import Foundation

struct VocabularyItem: Identifiable, Codable, Equatable {
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
        toneNumbers
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    // MARK: - English Meaning Properties
    func english(fullMeaning: Bool) -> String {
        fullMeaning ? englishFull : englishClean
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
}
