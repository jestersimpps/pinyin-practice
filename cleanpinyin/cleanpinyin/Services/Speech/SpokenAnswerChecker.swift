import Foundation

struct SpokenAnswer: Equatable {
    let heardText: String
    let heardPinyin: String
    let result: AnswerValidationResult
}

// Grades what the recognizer heard: the word itself or a same-sounding word passes, same syllables with other tones are partial
struct SpokenAnswerChecker {
    private let validator = PinyinValidator()

    func evaluate(transcript: String, word: VocabularyItem) -> SpokenAnswer {
        let heard = ChineseTransliterator.hanzi(in: transcript)
        guard !heard.isEmpty else {
            return SpokenAnswer(heardText: transcript, heardPinyin: "", result: .incorrect)
        }

        let heardPinyin = ChineseTransliterator.pinyin(for: heard)
        if heard == word.simplified || heard == word.traditional {
            return SpokenAnswer(heardText: heard, heardPinyin: heardPinyin, result: .correct)
        }

        let result = validator.validateAnswer(input: heardPinyin, word: word, requireTones: true)
        return SpokenAnswer(heardText: heard, heardPinyin: heardPinyin, result: result)
    }
}
