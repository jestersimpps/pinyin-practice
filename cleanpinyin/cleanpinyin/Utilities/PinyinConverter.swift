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

    private static let toneToBase: [Character: Character] = [
        "ā": "a", "á": "a", "ǎ": "a", "à": "a",
        "ē": "e", "é": "e", "ě": "e", "è": "e",
        "ī": "i", "í": "i", "ǐ": "i", "ì": "i",
        "ō": "o", "ó": "o", "ǒ": "o", "ò": "o",
        "ū": "u", "ú": "u", "ǔ": "u", "ù": "u",
        "ǖ": "ü", "ǘ": "ü", "ǚ": "ü", "ǜ": "ü"
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
            return syllable.replacingOccurrences(of: "v", with: "ü")
        }

        let base = String(syllable.dropLast()).replacingOccurrences(of: "v", with: "ü")
        guard tone <= 4 else { return base }

        guard let markIndex = toneMarkIndex(in: base) else { return base }
        var characters = Array(base)
        if let marked = toneMarks[characters[markIndex]]?[tone - 1] {
            characters[markIndex] = marked
        }
        return String(characters)
    }

    // Tone mark placement: 'a' wins, then 'e', then the 'o' in "ou", otherwise the last vowel
    private static func toneMarkIndex(in syllable: String) -> Int? {
        let characters = Array(syllable)
        if let index = characters.firstIndex(of: "a") { return index }
        if let index = characters.firstIndex(of: "e") { return index }
        if let range = syllable.range(of: "ou") {
            return syllable.distance(from: syllable.startIndex, to: range.lowerBound)
        }
        return characters.lastIndex { toneMarks.keys.contains($0) }
    }

    static func removeTones(_ pinyin: String) -> String {
        String(pinyin.map { toneToBase[$0] ?? $0 })
    }

    static func containsToneMarks(_ pinyin: String) -> Bool {
        pinyin.contains { toneToBase.keys.contains($0) }
    }
}
