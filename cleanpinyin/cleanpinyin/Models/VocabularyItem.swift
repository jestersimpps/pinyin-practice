import Foundation

struct VocabularyItem: Identifiable, Codable {
    let s: String
    let t: String
    let r: String
    let q: Int
    let p: [String]
    let m: [String]
    let c: [String]?
    let ch: String
    let ph: String
    let tn: String
    let cp: Int?  // Curriculum chapter (1-80)

    // MARK: - Basic Properties
    var id: String { s }
    var simplified: String { s }
    var traditional: String { t }
    var frequency: Int { q }
    var meanings: [String] { m }
    var characterHint: String { ch }
    var pronunciationHint: String { ph }
    var toneNumbers: String { tn }

    // MARK: - Pinyin Properties
    var pinyin: String {
        PinyinConverter.convertToToneMarks(toneNumbers)
    }

    var possiblePinyinVariations: [String] {
        toneNumbers.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    // MARK: - English Meaning Properties
    var english: String {
        UserProgressService.shared.settings.showFullMeaning ? englishFull : englishClean
    }

    private var englishClean: String {
        meanings.map { meaning in
            if meaning.lowercased().starts(with: "variant of"),
               let commaIndex = meaning.firstIndex(of: ",") {
                return String(meaning[meaning.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
            }
            return meaning
        }.joined(separator: "; ")
    }

    private var englishFull: String {
        meanings.joined(separator: "; ")
    }

    var shortTranslation: String {
        meanings.first ?? ""
    }

    // MARK: - Validation Methods
    func isPinyinCorrect(_ input: String, requireTones: Bool = true) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        for pinyin in possiblePinyinVariations {
            if normalizedInput == pinyin {
                return true
            }

            if !requireTones, stripToneNumbers(normalizedInput) == stripToneNumbers(pinyin) {
                return true
            }
        }

        return false
    }

    func isPinyinPartiallyCorrect(_ input: String) -> Bool {
        let normalizedInput = stripToneNumbers(input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
        return possiblePinyinVariations.contains { stripToneNumbers($0) == normalizedInput }
    }

    private func stripToneNumbers(_ pinyin: String) -> String {
        pinyin.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
    }
}
