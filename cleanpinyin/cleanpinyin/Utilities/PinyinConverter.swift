import Foundation

struct PinyinConverter {
    private static let toneMarks: [Character: [Character]] = [
        "a": ["ā", "á", "ǎ", "à"],
        "e": ["ē", "é", "ě", "è"],
        "i": ["ī", "í", "ǐ", "ì"],
        "o": ["ō", "ó", "ǒ", "ò"],
        "u": ["ū", "ú", "ǔ", "ù"],
        "ü": ["ǖ", "ǘ", "ǚ", "ǜ"]
    ]

    // Convert numbered pinyin ("ni3 hao3") to tone marks ("nǐ hǎo")
    static func convertToToneMarks(_ pinyinWithNumbers: String) -> String {
        pinyinWithNumbers
            .split(separator: " ", omittingEmptySubsequences: false)
            .map { convertSyllable(String($0)) }
            .joined(separator: " ")
    }

    private static func convertSyllable(_ syllable: String) -> String {
        guard let last = syllable.last, let tone = last.wholeNumberValue, (1...5).contains(tone) else {
            return replacingUmlaut(in: syllable)
        }

        let base = replacingUmlaut(in: String(syllable.dropLast()))
        guard tone <= 4, let markIndex = toneMarkIndex(in: base) else { return base }

        var characters = Array(base)
        let vowel = characters[markIndex]
        if let marked = toneMarks[Character(vowel.lowercased())]?[tone - 1] {
            characters[markIndex] = vowel.isUppercase ? Character(marked.uppercased()) : marked
        }
        return String(characters)
    }

    private static func replacingUmlaut(in syllable: String) -> String {
        syllable
            .replacingOccurrences(of: "v", with: "ü")
            .replacingOccurrences(of: "V", with: "Ü")
    }

    // Tone mark placement: 'a' wins, then 'e', then the 'o' in "ou", otherwise the last vowel
    private static func toneMarkIndex(in syllable: String) -> Int? {
        let characters = Array(syllable.lowercased())
        if let index = characters.firstIndex(of: "a") { return index }
        if let index = characters.firstIndex(of: "e") { return index }
        if let index = characters.indices.first(where: { characters[$0] == "o" && characters.indices.contains($0 + 1) && characters[$0 + 1] == "u" }) {
            return index
        }
        return characters.lastIndex { toneMarks.keys.contains($0) }
    }
}
