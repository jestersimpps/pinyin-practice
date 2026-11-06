# cleanpinyin — Product Spec

cleanpinyin teaches English speakers to read Chinese characters. The app shows a character and the learner types its pinyin. It covers the 4,993 words of HSK levels 1–6 and ships all vocabulary inside the app: no account, no network, no tracking.

Each rule has an ID (`ANS-3`, `CH-2`, …). Tests in `cleanpinyinTests` name the rule they verify.

---

## 1. Vocabulary data

Words live in `Resources/Data/<level>.min.json`, one file per HSK level. Optional study lists live in `Resources/CustomData/*.json`.

| Field | Meaning |
|---|---|
| `s` / `t` | simplified / traditional characters. `s` is the word's identity. |
| `tn` | pinyin with tone numbers, one syllable per character, space separated (`ba4 ba5`). `v` stands for `ü` (`nv3`). Neutral tone is `5`. |
| `m` | English meanings, most useful first |
| `q` | frequency rank (lower is more common) |
| `ch` / `ph` | character and pronunciation memory hints |
| `cp` | curriculum chapter (1–80), present for HSK 1–2 only |

- **DATA-1** Every syllable in `tn` is letters followed by a tone number 1–5. The syllable count equals the character count, except for erhua words that end in 儿.
- **DATA-2** `ü` is written as `v`, so 女 is `nv3` and is shown as `nǚ`.
- **DATA-3** Only proper nouns start with a capital letter (北京 `Bei3 jing1`). A common word never leads with a surname, abbreviation or place-name meaning: 白 means "white", not "surname Bai".
- **DATA-4** A word appears at most once per HSK level. A word can appear in a custom list as well as in an HSK level; both refer to the same progress.
- **DATA-5** Every level file loads and decodes. A broken custom list is skipped and doesn't affect the rest.

## 2. Answer checking

- **ANS-1** Input is compared ignoring case, surrounding whitespace and the spaces between syllables. `baba`, `ba ba` and `Ba Ba` all match `ba4 ba5` when tones are not required.
- **ANS-2** Tones can be typed as numbers (`ni3hao3`) or as marks (`nǐhǎo`). Both are accepted.
- **ANS-3** `ü` can be typed as `v`, `ü`, `u:` or plain `u`.
- **ANS-4** Neutral tone may be typed as `5`, as `0` or left out (`ba4ba`).
- **ANS-5** With **Require Tones** off, any tones the learner types are ignored.
- **ANS-6** With **Require Tones** on, every toned syllable must carry the right tone. If the letters are right but a tone is wrong or missing, the result is **partial**: shown in orange and recorded as a miss.
- **ANS-7** Auto-submit: when the input is already a correct answer, the app submits it after a 0.5 s pause in typing. An incorrect or incomplete answer is never auto-submitted. The learner presses **Check** or Return.

## 3. Practice session

- **PRA-1** A session works through a fixed list of words, one at a time. The header shows a progress bar, words done / total, overall accuracy and the current combo (correct answers in a row).
- **PRA-2** **Correct:** green feedback, a haptic tap, the word is spoken (if **Speak on Correct Answer** is on) and the session moves to the next word after 1 s (1.5 s on the last word). **Next** skips the wait.
- **PRA-3** **Incorrect or partial:** the correct pinyin, the meaning and the hints are shown, and the miss is recorded once per word. The learner can retype. A correct retype turns the feedback green, counts toward chapter progress and clears the word from Review Mistakes, but does not auto-advance. A visible **Next** button is always available.
- **PRA-4** **Skip** (button, or swipe right) counts as a miss and reveals the answer, just like an incorrect answer.
- **PRA-5** **Hint** (lightbulb, or swipe left) toggles the character and pronunciation hints. It's only available when hints are enabled.
- **PRA-6** The speaker button reads the word aloud at any time.
- **PRA-7** When the last word is done, a summary appears: words studied, accuracy, time and best combo. The session is saved to history. **Continue Practice** starts a new round and **Back to Home** closes the session.
- **PRA-8** Leaving a session early saves it if at least one word was completed.
- **PRA-9** A session with no words shows an empty state with a way back. It never shows a blank screen.

## 4. Practice modes

- **MODE-1 Quick Practice** resumes the last chapter selection, or the last review session if mistakes remain. Otherwise it practises the HSK levels chosen in Settings (default HSK 1).
  - **Sequential order:** words not yet learned come first, in frequency order, followed by learned words. Each session therefore continues where the learner left off.
  - **Random order:** shuffled, with never-seen words first.
- **MODE-2 Chapter Practice** practises the selected unlocked chapters (see §5).
- **MODE-3 Custom Practice** practises any chapters or custom lists the learner picks, locked or not. It's a one-off and does not change the Quick Practice levels or the chapter selection.
- **MODE-4 Review Mistakes** practises the words whose latest answer was wrong, each word once. It is disabled when there are none.
- **MODE-5** The Quick Practice card shows how many words the selected levels contain. Its subtitle says what it will do.

## 5. Chapters

- **CH-1** HSK 1–2 words are grouped by their curriculum chapter (`cp`). A chapter appears only if it has words, and it uses its curriculum title (`你好 Hello`).
- **CH-2** HSK 3–6 words have no curriculum chapter yet. They are split by frequency into near-equal sets of at most 40 words, titled `Set N` with the word range (`Words 1–38`). They don't borrow topical titles they don't match.
- **CH-3** Within a level, the first chapter is always unlocked. Each later chapter unlocks once the chapter before it, in that level's list, is at least 80% complete. Empty curriculum slots are skipped and never block anything.
- **CH-4** A chapter's completion is the share of its words answered correctly at least once during chapter or custom practice.
- **CH-5** Completing a chapter shows a celebration with **Continue to Next Chapter** (the next chapter in the level, or the first chapter of the next level), **Review This Chapter** and **Back to Chapters**. **Continue** is only offered when a next chapter exists.

## 6. Imprint mode (listening)

- **IMP-1** The learner picks chapters, then presses Start. For each word the app speaks the English meaning, waits 2 s, speaks the Chinese word, then shows the character, pinyin and meaning. Then it moves on.
- **IMP-2** Each step starts when the previous speech has finished. It is not timed by estimates.
- **IMP-3** Pause keeps the position and Resume continues from it. Stop resets to the start. Leaving the screen stops all speech.

## 7. Progress & motivation

- **PROG-1** A word is **learned** once it has been answered correctly at least once.
- **PROG-2** **Accuracy** is correct answers divided by attempts, across all time.
- **PROG-3** **Day streak** counts consecutive calendar days with at least one answer. It continues if the learner practised today or yesterday, and resets to 0 once a full day is missed. The best day streak is kept.
- **PROG-4** **Combo** counts correct answers in a row. Any miss resets it to 0. It is shown during practice.
- **PROG-5** The Progress screen shows learned words (of 4,993), accuracy, total practice time and words to review. It also shows the day streak and best, charts for accuracy, words per day and minutes per day (week / month / all time), learned words per HSK level, and achievements.
- **PROG-6** **Reset All Progress** asks for confirmation, then clears progress and history but keeps settings.

## 8. Settings

- **SET-1** Appearance: Light / Dark / System.
- **SET-2** Quick Practice levels: pick one or more of HSK 1–6. At least one stays selected.
- **SET-3** Word order: Sequential / Random.
- **SET-4** Toggles: Require Tones, Show English, Pronunciation Hints, Character Hints, Traditional Characters, Full Meanings, Speak on Correct Answer.
- **SET-5** Settings are saved immediately. Unknown or missing keys fall back to defaults, so updates never wipe settings.
- **SET-6** An About section shows the app version.

## 9. Platform & quality

- **PLAT-1** iPhone, portrait. iOS 17 or later.
- **PLAT-2** Audio takes the audio session only while speaking. Other apps' audio is ducked during speech and restored afterwards.
- **PLAT-3** All data stays on the device (UserDefaults). The app ships a privacy manifest that declares UserDefaults use and no tracking or data collection.
- **PLAT-4** Every interactive element has an accessibility label. The app is usable in light and dark mode.
