import Foundation

enum ChineseTransliterator {
    private static let digits: [Character: Character] = [
        "0": "零", "1": "一", "2": "二", "3": "三", "4": "四",
        "5": "五", "6": "六", "7": "七", "8": "八", "9": "九"
    ]

    static func hanzi(in text: String) -> String {
        String(text.compactMap { character -> Character? in
            if let digit = digits[character] { return digit }
            return character.unicodeScalars.allSatisfy(\.properties.isUnifiedIdeograph) ? character : nil
        })
    }

    // Tone-marked pinyin, e.g. "你好" -> "nǐ hǎo"
    static func pinyin(for chinese: String) -> String {
        let mutable = NSMutableString(string: chinese)
        CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false)
        return (mutable as String).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
