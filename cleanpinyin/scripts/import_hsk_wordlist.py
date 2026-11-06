#!/usr/bin/env python3
"""Build the app's word bank from the HSK 3.0 (2026) syllabus.

Usage: import_hsk_wordlist.py <complete.min.json> <syllabus.txt> [--report report.md]

  complete.min.json  drkameleon/complete-hsk-vocabulary (MIT): all readings and CC-CEDICT meanings per word.
                     Tags "t1"–"t6" are the 2026 syllabus levels.
  syllabus.txt       The official HSK 3.0 vocabulary with pinyin (新版HSK考试大纲-词汇_cleaned.txt from
                     krmanik/HSK-3.0-words-list), tab separated: number, level, word, pinyin, part of speech.

The word bank (cleanpinyin/Resources/Data/words.min.json) is the source of truth and keeps each word's hints and
HSK 2.0 level. This script adds missing HSK 3.0 words, sets HSK 3.0 levels, and takes every reading from the
official syllabus, so a word whose dictionary reading was picked wrongly gets the right reading and meanings.
"""
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BANK = ROOT / "cleanpinyin/Resources/Data/words.min.json"
HSK2, HSK3 = "hsk2", "hsk3"
HSK3_LEVELS = range(1, 7)

DROP = re.compile(r"^(surname |abbr\. for |abbr\. of |\(Tw\) abbr|Taiwan pr\.|old variant of|euphemistic variant of|variant of|used in )", re.I)
PROPER = re.compile(r"^([A-Z]|the [A-Z])")
KEEP_CAPS = {"北京", "汉语", "中国", "中文", "亚洲", "欧洲", "长城", "长江"}
TONE_MARKS = {"̄": 1, "́": 2, "̌": 3, "̀": 4}
# 一 and 不 change tone before other syllables; learners type their dictionary tone
SANDHI_CHARACTERS = "一不"

# Reviewed readings and meanings that override both sources
READINGS = {
    "致力于": "zhi4 li4 yu2", "纽扣儿": "niu3 kour4", "长江": "Chang2 jiang1",
    "电动车": "dian4 dong4 che1", "血": "xie3", "没法儿": "mei2 fa3 r5", "小偷儿": "xiao3 tou1 r5",
}
MEANINGS = {
    "比": ["to compare", "than (in comparisons)", "ratio", "to gesture"],
    "钟": ["clock", "bell", "o'clock; time"],
    "越": ["to exceed", "to climb over", "the more ... the more (越...越...)"],
    "台": ["platform; stage", "desk; table", "classifier for machines, vehicles, performances"],
    "张": ["classifier for flat objects (sheet, table, bed)", "to open up", "to spread"],
    "别": ["don't; must not", "to leave; to part (from)", "other; another"],
    "元": ["yuan (currency unit)", "first; primary", "basic"],
    "老板": ["boss", "business proprietor"],
    "等": ["to wait", "class; rank; grade", "and so on; etc."],
    "跟": ["with; and", "to follow", "heel"],
    "次": ["time (classifier for occurrences)", "next in sequence", "second; secondary"],
    "一起": ["together", "in the same place"],
    "就": ["then; right away", "only; just", "to approach"],
    "纪录": ["record (e.g. a world record)", "to record"],
    "体检": ["physical examination; checkup"],
    "贤惠": ["virtuous and kind"],
    "啰唆": ["long-winded; wordy", "troublesome"],
}


def numbered(reading: str) -> str:
    return reading.replace("ü", "v").replace("Ü", "V")


def parse_reading(reading: str) -> tuple[list[str], list[int]] | None:
    letters, tones = [], []
    for syllable in numbered(reading).lower().split():
        match = re.fullmatch(r"([a-zv]+?)([1-5])", syllable)
        if not match:
            return None
        letters.append(match.group(1))
        tones.append(int(match.group(2)))
    return letters, tones


def official_tones(pinyin: str, letters: list[str]) -> list[int] | None:
    """Tones of an official joined reading such as "bàba", aligned to dictionary syllables ["ba", "ba"]."""
    decomposed = unicodedata.normalize("NFD", re.sub(r"[\s'’\-]", "", pinyin.lower()))
    chars, marks = [], []
    for char in decomposed:
        if char in TONE_MARKS:
            marks[-1] = TONE_MARKS[char]
        elif char == "̈":
            chars[-1] = "v"
        else:
            chars.append(char)
            marks.append(0)
    joined, position, tones = "".join(chars), 0, []
    for syllable in letters:
        if not joined.startswith(syllable, position):
            return None
        marked = [mark for mark in marks[position:position + len(syllable)] if mark]
        tones.append(marked[0] if marked else 5)
        position += len(syllable)
    return tones if position == len(joined) else None


def load_official(path: Path) -> dict[str, str]:
    """First official reading for each word, expanding optional parts like 没（有） into 没 and 没有."""
    readings: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        _, _, word, pinyin, *_ = line.split("\t") + [""]
        word = re.sub(r"\d", "", word)
        pinyin = pinyin.split("/")[0]
        variants = [(word, pinyin)]
        optional_word = re.fullmatch(r"(.*)（(.*)）(.*)", word)
        optional_pinyin = re.fullmatch(r"(.*)\((.*)\)(.*)", pinyin)
        if optional_word and optional_pinyin:
            a, b, c = optional_word.groups()
            x, y, z = optional_pinyin.groups()
            variants = [(a + c, x + z), (a + b + c, x + y + z)]
        for variant_word, variant_pinyin in variants:
            readings.setdefault(variant_word, variant_pinyin)
    return readings


def clean_meanings(meanings: list[str], proper_noun: bool) -> list[str]:
    kept = [m for m in meanings if not DROP.match(m)] or meanings
    if proper_noun:
        kept = [m for m in kept if not PROPER.match(m)] or kept
    return kept


def best_form(word: dict, official: str | None) -> tuple[dict, str]:
    """The dictionary form that matches the official reading best, and that form's reading with official tones."""
    candidates = []
    for form in word["f"]:
        parsed = parse_reading(form["i"]["n"])
        if parsed is None:
            continue
        letters, tones = parsed
        real_meanings = [m for m in form["m"] if not DROP.match(m)]
        aligned = official_tones(official, letters) if official else None
        if aligned is not None:
            aligned = [tone if word["s"][i:i + 1] not in SANDHI_CHARACTERS else tones[i] for i, tone in enumerate(aligned)]
        matched_tones = sum(a == b for a, b in zip(aligned or [], tones))
        score = (aligned is not None, matched_tones, bool(real_meanings), not form["i"]["n"][:1].isupper(), len(real_meanings))
        reading = " ".join(f"{l}{t}" for l, t in zip(letters, aligned or tones))
        candidates.append((score, form, reading))
    if not candidates:
        form = word["f"][0]
        return form, numbered(form["i"]["n"])
    _, form, reading = max(candidates, key=lambda candidate: candidate[0])
    return form, reading


def normalize(word: dict, source: dict | None) -> None:
    """Use the main written form's traditional characters and drop variant notes and repeats from the meanings."""
    if source:
        letters = re.sub(r"\d", "", word["tn"].lower())
        same_sound = [f for f in source["f"] if re.sub(r"\d", "", numbered(f["i"]["n"]).lower()) == letters] or source["f"]
        main = max(same_sound, key=lambda f: sum(not DROP.match(m) for m in f["m"]))
        word["t"] = main["t"]
    kept = [m for m in word["m"] if not DROP.match(m)] or word["m"]
    word["m"] = list(dict.fromkeys(kept))


def load_bank() -> list[dict]:
    return json.loads(BANK.read_text())


def hsk3_level(word: dict) -> int | None:
    levels = [int(tag[1:]) for tag in word.get("l", []) if tag.startswith("t") and int(tag[1:]) in HSK3_LEVELS]
    return min(levels) if levels else None


def main() -> None:
    upstream = {word["s"]: word for word in json.loads(Path(sys.argv[1]).read_text())}
    official = load_official(Path(sys.argv[2]))
    report_path = Path(sys.argv[sys.argv.index("--report") + 1]) if "--report" in sys.argv else None
    bank = {word["s"]: word for word in load_bank()}

    for word in bank.values():
        word["lv"].pop(HSK3, None)
    added = []
    for simplified, source in upstream.items():
        level = hsk3_level(source)
        if level is None:
            continue
        if simplified not in bank:
            bank[simplified] = {"s": simplified, "r": source.get("r", ""), "q": source["q"], "p": source.get("p", []), "lv": {}}
            added.append(simplified)
        bank[simplified]["lv"][HSK3] = level

    changed, hints_cleared, unchecked = [], [], []
    for simplified, word in bank.items():
        source = upstream.get(simplified)
        previous = word.get("tn")
        if simplified not in official:
            unchecked.append(simplified)
        if source is None or (simplified not in official and previous is not None):
            continue
        form, reading = best_form(source, official.get(simplified))
        keep_caps = simplified in KEEP_CAPS
        reading = reading[:1].upper() + reading[1:] if keep_caps else reading
        reading = READINGS.get(simplified, reading)
        if previous is not None and previous.lower() == reading.lower():
            continue

        word["tn"] = reading
        word["t"] = form["t"]
        word["m"] = clean_meanings(form["m"], proper_noun=form["i"]["n"][:1].isupper() and not keep_caps)
        word["c"] = form.get("c", [])
        if previous is not None:
            changed.append((simplified, previous, reading, word["lv"]))
            previous_letters = re.sub(r"\d", "", previous.lower())
            if word.get("ph") and previous_letters != re.sub(r"\d", "", reading.lower()):
                word["ph"] = ""
                hints_cleared.append(simplified)

    for simplified, word in bank.items():
        normalize(word, upstream.get(simplified))
        if simplified in READINGS:
            word["tn"] = READINGS[simplified]
        if simplified in MEANINGS:
            word["m"] = MEANINGS[simplified]

    words = sorted(bank.values(), key=lambda w: (w["q"], w["s"]))
    BANK.write_text(json.dumps(words, ensure_ascii=False, separators=(",", ":")))

    per_level = {level: sum(1 for w in words if w["lv"].get(HSK3) == level) for level in HSK3_LEVELS}
    print(f"{len(words)} words, {len(added)} added, {len(changed)} readings corrected, "
          f"{len(unchecked)} not in the official syllabus. HSK 3.0 per level: {per_level}")

    if report_path:
        def levels(lv: dict) -> str:
            return ", ".join(f"{'HSK 2.0' if key == HSK2 else 'HSK 3.0'} L{value}" for key, value in sorted(lv.items()))
        lines = [
            "# Word bank import review", "",
            f"- {len(words)} words; {len(added)} new HSK 3.0 words.",
            f"- {len(changed)} existing readings corrected to the official HSK 3.0 syllabus pinyin "
            "(tones of 一 and 不 stay at their dictionary tone).",
            f"- {len(hints_cleared)} pronunciation hints cleared because the reading changed; they get rewritten in the hints step.",
            f"- {len(unchecked)} words are not in the official syllabus (HSK 2.0 only) and could not be checked.", "",
            "## Corrected readings", "", "| Word | Was | Now | Lists |", "|---|---|---|---|",
        ]
        lines += [f"| {s} | {old} | {new} | {levels(lv)} |" for s, old, new, lv in changed]
        BANK_UNCHECKED = [s for s in unchecked if HSK3 not in bank[s]["lv"]]
        lines += ["", f"## HSK 2.0 words not in the official syllabus ({len(BANK_UNCHECKED)})", "", " ".join(BANK_UNCHECKED)]
        report_path.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
