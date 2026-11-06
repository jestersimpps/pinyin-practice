import Foundation

struct TutorExplanation: Equatable {
    let summary: String
    let memoryTip: String
}

struct ExampleSentence: Codable, Equatable, Identifiable {
    let chinese: String
    let pinyin: String
    let english: String

    var id: String { chinese }
}

struct MistakeContext: Equatable {
    enum Kind: Equatable {
        case tone
        case spelling
        case skipped
    }

    let word: VocabularyItem
    let answer: String
    let kind: Kind
}

protocol Tutoring: AnyObject {
    var isAvailable: Bool { get }
    func explain(_ mistake: MistakeContext) async throws -> TutorExplanation
    // Raw model output: (Chinese sentence, English translation) pairs
    func generateExamples(for word: VocabularyItem, hskLevel: Int) async throws -> [(chinese: String, english: String)]
}

enum TutorFactory {
    static func makeDefault() -> Tutoring? {
        if #available(iOS 26.0, *) {
            return FoundationModelsTutor()
        }
        return nil
    }
}

enum ExampleSentenceFilter {
    static let maximumLength = 30
    static let maximumSentences = 3

    // Keeps short, all-Chinese sentences that really use the word; pinyin comes from the system transliterator, not the model
    static func validated(_ raw: [(chinese: String, english: String)], for word: VocabularyItem) -> [ExampleSentence] {
        var seen = Set<String>()
        let sentences: [ExampleSentence] = raw.compactMap { pair in
            let chinese = pair.chinese.trimmingCharacters(in: .whitespacesAndNewlines)
            let english = pair.english.trimmingCharacters(in: .whitespacesAndNewlines)
            let characters = ChineseTransliterator.hanzi(in: chinese)

            guard chinese.contains(word.simplified),
                  characters.count > word.simplified.count,
                  chinese.count <= maximumLength,
                  !chinese.contains(where: { $0.isASCII && $0.isLetter }),
                  !english.isEmpty,
                  seen.insert(chinese).inserted else { return nil }

            return ExampleSentence(chinese: chinese, pinyin: ChineseTransliterator.pinyin(for: chinese), english: english)
        }
        return Array(sentences.prefix(maximumSentences))
    }
}

enum ToneDescription {
    private static let names = [
        1: "1st tone (high and flat)",
        2: "2nd tone (rising)",
        3: "3rd tone (dipping)",
        4: "4th tone (falling)",
        5: "neutral tone (light and short)"
    ]

    static func describe(_ toneNumbers: String) -> String {
        toneNumbers.split(separator: " ").map { syllable in
            let tone = syllable.last?.wholeNumberValue ?? 5
            let marked = PinyinConverter.convertToToneMarks(String(syllable))
            return "\(marked) is the \(names[tone] ?? "neutral tone")"
        }.joined(separator: "; ")
    }
}
