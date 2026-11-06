import Foundation

struct PinyinValidator {
    func validateAnswer(input: String, word: VocabularyItem, requireTones: Bool) -> AnswerValidationResult {
        let typed = PinyinInput(input)
        let results = word.possiblePinyinVariations.map { reading in
            evaluate(typed, against: PinyinReading(reading), requireTones: requireTones)
        }

        if results.contains(.correct) { return .correct }
        if results.contains(.partial) { return .partial }
        return .incorrect
    }

    private func evaluate(_ typed: PinyinInput, against reading: PinyinReading, requireTones: Bool) -> AnswerValidationResult {
        guard !typed.letters.isEmpty, typed.comparableLetters == reading.comparableLetters else { return .incorrect }
        guard requireTones else { return .correct }
        return reading.acceptsTones(typed.tones(alignedTo: reading)) ? .correct : .partial
    }
}

enum AnswerValidationResult {
    case correct
    case incorrect
    case partial

    var feedbackState: FeedbackState {
        switch self {
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
}

private struct PinyinReading {
    let syllables: [(letters: String, tone: Int)]

    init(_ toneNumbers: String) {
        syllables = toneNumbers.lowercased().split(separator: " ").map { syllable in
            let tone = syllable.last?.wholeNumberValue ?? 5
            let letters = syllable.filter(\.isLetter).replacingOccurrences(of: "ü", with: "v")
            return (letters, (1...5).contains(tone) ? tone : 5)
        }
    }

    var comparableLetters: String {
        syllables.map(\.letters).joined().replacingOccurrences(of: "v", with: "u")
    }

    var syllableEndOffsets: [Int] {
        var total = 0
        return syllables.map { syllable in
            total += syllable.letters.count
            return total
        }
    }

    func acceptsTones(_ typedTones: [Int?]?) -> Bool {
        guard let typedTones, typedTones.count == syllables.count else { return false }
        return zip(syllables, typedTones).allSatisfy { syllable, typed in
            syllable.tone == 5 ? (typed == nil || typed == 5) : typed == syllable.tone
        }
    }
}

private struct PinyinInput {
    private(set) var letters = ""
    private var toneMarks: [(letterIndex: Int, tone: Int, isTrailingNumber: Bool)] = []

    private static let markedVowels: [Character: (base: Character, tone: Int)] = [
        "ā": ("a", 1), "á": ("a", 2), "ǎ": ("a", 3), "à": ("a", 4),
        "ē": ("e", 1), "é": ("e", 2), "ě": ("e", 3), "è": ("e", 4),
        "ī": ("i", 1), "í": ("i", 2), "ǐ": ("i", 3), "ì": ("i", 4),
        "ō": ("o", 1), "ó": ("o", 2), "ǒ": ("o", 3), "ò": ("o", 4),
        "ū": ("u", 1), "ú": ("u", 2), "ǔ": ("u", 3), "ù": ("u", 4),
        "ǖ": ("v", 1), "ǘ": ("v", 2), "ǚ": ("v", 3), "ǜ": ("v", 4),
    ]

    init(_ raw: String) {
        let normalized = raw.lowercased()
            .replacingOccurrences(of: "u:", with: "v")
            .replacingOccurrences(of: "ü", with: "v")

        for character in normalized {
            if let marked = Self.markedVowels[character] {
                letters.append(marked.base)
                toneMarks.append((letters.count - 1, marked.tone, false))
            } else if let digit = character.wholeNumberValue, (0...5).contains(digit) {
                toneMarks.append((letters.count, digit == 0 ? 5 : digit, true))
            } else if character.isLetter {
                letters.append(character)
            }
        }
    }

    var comparableLetters: String {
        letters.replacingOccurrences(of: "v", with: "u")
    }

    // Assigns each typed tone to its syllable; nil when a number sits mid-syllable or a syllable gets two tones
    func tones(alignedTo reading: PinyinReading) -> [Int?]? {
        let ends = reading.syllableEndOffsets
        var tones = [Int?](repeating: nil, count: ends.count)

        for mark in toneMarks {
            let syllableIndex = mark.isTrailingNumber
                ? ends.firstIndex(of: mark.letterIndex)
                : ends.firstIndex { mark.letterIndex < $0 }
            guard let syllableIndex, tones[syllableIndex] == nil else { return nil }
            tones[syllableIndex] = mark.tone
        }
        return tones
    }
}
