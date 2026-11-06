# EchoLingo Chinese — Product Spec

EchoLingo Chinese (project name: cleanpinyin) teaches English speakers to read Chinese characters. The app shows a character and the learner types its pinyin. It covers the 4,993 words of HSK levels 1–6 and ships all vocabulary inside the app: no account, no network, no tracking.

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
- **PRA-3** **Incorrect or partial:** the correct pinyin, the meaning and the hints are shown, and the miss is recorded once per word. The learner can retype. A correct retype turns the feedback green, counts toward chapter progress and clears the word from the mistakes list without rescheduling it, but does not auto-advance. A visible **Next** button is always available.
- **PRA-4** **Skip** (button, or swipe right) counts as a miss and reveals the answer, just like an incorrect answer.
- **PRA-5** **Hint** (lightbulb, or swipe left) toggles the character and pronunciation hints. It's only available when hints are enabled.
- **PRA-6** The speaker button reads the word aloud at any time.
- **PRA-7** When the last word is done, a summary appears: words studied, accuracy, time and best combo. The session is saved to history. **Continue Practice** starts a new round and **Back to Home** closes the session.
- **PRA-8** Leaving a session early saves it if at least one word was completed.
- **PRA-9** A session with no words shows an empty state with a way back. It never shows a blank screen.

## 4. Practice modes

- **MODE-1 Quick Practice** resumes the last chapter selection, or the last review session if words are still due. Otherwise it practises the HSK levels chosen in Settings (default HSK 1).
  - **Sequential order:** words not yet learned come first, in frequency order, followed by learned words. Each session therefore continues where the learner left off.
  - **Random order:** shuffled, with never-seen words first.
- **MODE-2 Chapter Practice** practises the selected unlocked chapters (see §5).
- **MODE-3 Custom Practice** practises any chapters or custom lists the learner picks, locked or not. It's a one-off and does not change the Quick Practice levels or the chapter selection.
- **MODE-4 Smart Review** practises the words that are due under spaced repetition (§12), each once, most overdue first. It is disabled when nothing is due, and then says when the next review is.
- **MODE-5** The Quick Practice card shows how many words the selected levels contain. Its subtitle says what it will do.

## 5. Chapters

- **CH-1** HSK 1–2 words are grouped by their curriculum chapter (`cp`). A chapter appears only if it has words, and it uses its curriculum title (`你好 Hello`).
- **CH-2** HSK 3–6 words have no curriculum chapter yet. They are split by frequency into near-equal sets of at most 40 words. Each set is titled and iconed after a featured word it actually contains ("Set 1: 世界 World", globe), so the list reads like chapters without claiming a topic the words don't share. Titles and icons live in `Resources/set-themes.json` (editable); icons are unique within a level. If a theme no longer matches its set, the set falls back to its word range as title.
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
- **PROG-5** The Progress screen shows learned words (of 4,993), accuracy, total practice time and words due now. It also shows the day streak and best, charts for accuracy, words per day and minutes per day (week / month / all time), learned words per HSK level, and achievements.
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

## 10. Say it (on-device speech recognition)

- **SAY-1** When the device can recognise Mandarin on-device, the practice input row shows a microphone switch. On iOS 26 recognition uses SpeechAnalyzer/SpeechTranscriber, downloading the Mandarin model the first time. Older iOS versions, and devices where SpeechTranscriber lacks Mandarin, use SFSpeechRecognizer in on-device mode. Audio never leaves the device.
- **SAY-2** The transcript is reduced to its Chinese characters (digits become numerals) and converted to pinyin. Hearing the word itself, or a same-sounding word with the same tones (他/她 for tā), is **correct**. The same syllables with other tones are **partial**. Anything else is **incorrect**.
- **SAY-3** A spoken answer is recorded exactly like a typed one (PRA-2/PRA-3), and the screen shows what was heard with its pinyin.
- **SAY-4** If permission is refused, voice stays off, nothing is recorded and a short message explains what to do. Tone grading is only as precise as the recogniser: a clear word with a slightly off tone may still pass.
- **SAY-5** **Hands-free:** tapping the microphone turns voice answers on until it is tapped again; the choice is remembered and the next session starts listening by itself. While on, the app listens for every word without further taps. While the learner speaks, partial transcripts are checked: the moment the correct word is heard, listening stops and the answer counts. Otherwise a listen ends after 0.5 s of silence (measured against the speaker's own volume, so steady background noise doesn't keep it open), after 8 s without speech, or after 10 s. It never listens while the app is speaking, while a correct answer is on screen, or while a summary is shown. Typing still works at the same time, and the keyboard stays hidden.
- **SAY-6** Every heard answer moves on by itself. A correct answer moves on after 1 s. After a miss, the screen shows the correct pinyin and the app always reads the word aloud (whatever the Speak on Correct Answer setting), then moves on shortly after it has finished speaking; if that speech is interrupted, it moves on after 5 s anyway. The app does not listen during that pause. Typed answers keep PRA-3: a typed miss waits for Next.
- **SAY-7** After three silent listens in a row (about 25 s), voice pauses with a message; tapping the microphone resumes it. Pausing does not change the remembered preference.

## 11. AI tutor (on-device language model)

- **TUT-1** On iOS 26 devices where Apple Intelligence is available and enabled, a tutor panel appears under the word after any miss (wrong letters, wrong tones or skip). Without the on-device model the panel never appears and the app behaves as before.
- **TUT-2** **Why?** asks Apple's on-device model (FoundationModels) for a one-to-two sentence explanation and a memory tip. The prompt carries the correct pinyin, each syllable's tone and the app's own diagnosis (tone, spelling or skipped), so the model explains rather than guesses. Errors show a short "couldn't help" message.
- **TUT-3** **Use it** asks for three short example sentences at the learner's HSK level. The app keeps only sentences of at most 30 characters that contain the word, are written in Chinese characters only and have an English translation; at most three are shown. Pinyin comes from the system transliterator, not the model. (It uses dictionary tones, so 喜欢 reads xǐ huān rather than the spoken xǐ huan.) Tapping a sentence reads it aloud.
- **TUT-4** Example sentences are cached per word on the device, so they appear instantly next time.

## 12. Smart review (spaced repetition)

- **REV-1** Every word gets a review card scheduled with FSRS-5 (default weights, 90% target retention, intervals of 1 to 365 days). A first answer sets the initial stability and difficulty. Each later answer updates them using the time since the last review, and the next due date is the interval at which recall is predicted to fall to 90%.
- **REV-2** A forgotten word (**Again**) is due again straight away.
- **REV-3** Answers are rated automatically: correct first time = **Good**; correct after opening hints = **Hard**; right syllables, wrong tones = **Hard** (still a miss for accuracy and combo); wrong, skipped or wrong spoken word = **Again**. Retyping after a miss does not reschedule the word.
- **REV-4** The review queue lists due words, most overdue first. Misses recorded before scheduling existed (no card yet) come first.
- **REV-5** Cards are saved with progress, survive updates and are cleared by Reset All Progress.
