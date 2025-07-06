import Foundation

struct PinyinConverter {
    // Tone mark to number mapping
    private static let toneMarkToNumber: [Character: String] = [
        "ā": "a1", "á": "a2", "ǎ": "a3", "à": "a4",
        "ē": "e1", "é": "e2", "ě": "e3", "è": "e4",
        "ī": "i1", "í": "i2", "ǐ": "i3", "ì": "i4",
        "ō": "o1", "ó": "o2", "ǒ": "o3", "ò": "o4",
        "ū": "u1", "ú": "u2", "ǔ": "u3", "ù": "u4",
        "ǖ": "ü1", "ǘ": "ü2", "ǚ": "ü3", "ǜ": "ü4"
    ]
    
    // Base vowels for tone removal
    private static let toneToBase: [Character: Character] = [
        "ā": "a", "á": "a", "ǎ": "a", "à": "a",
        "ē": "e", "é": "e", "ě": "e", "è": "e",
        "ī": "i", "í": "i", "ǐ": "i", "ì": "i",
        "ō": "o", "ó": "o", "ǒ": "o", "ò": "o",
        "ū": "u", "ú": "u", "ǔ": "u", "ù": "u",
        "ǖ": "ü", "ǘ": "ü", "ǚ": "ü", "ǜ": "ü"
    ]
    
    // Convert pinyin with tone marks to tone numbers
    static func convertToToneNumbers(_ pinyin: String) -> String {
        var result = ""
        var currentSyllable = ""
        var toneNumber = ""
        
        for char in pinyin {
            if let replacement = toneMarkToNumber[char] {
                currentSyllable.append(String(replacement.dropLast()))
                toneNumber = String(replacement.last!)
            } else if char == " " {
                result.append(currentSyllable + toneNumber + " ")
                currentSyllable = ""
                toneNumber = ""
            } else {
                currentSyllable.append(char)
            }
        }
        
        // Append the last syllable
        result.append(currentSyllable + toneNumber)
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // Remove all tone marks from pinyin
    static func removeTones(_ pinyin: String) -> String {
        return pinyin.map { char in
            String(toneToBase[char] ?? char)
        }.joined()
    }
    
    // Check if a string contains tone marks
    static func containsToneMarks(_ pinyin: String) -> Bool {
        return pinyin.contains { toneToBase.keys.contains($0) }
    }
    
    // Normalize pinyin for comparison (remove tones and spaces, lowercase)
    static func normalize(_ pinyin: String) -> String {
        return removeTones(pinyin)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
    
    // Check if two pinyin strings are equivalent (ignoring tones)
    static func isEquivalentIgnoringTones(_ pinyin1: String, _ pinyin2: String) -> Bool {
        return normalize(pinyin1) == normalize(pinyin2)
    }
    
    // Extract tone pattern from pinyin (returns array of tone numbers)
    static func extractTonePattern(_ pinyin: String) -> [Int] {
        var tones: [Int] = []
        var currentTone = 0
        
        for char in pinyin {
            if let replacement = toneMarkToNumber[char] {
                currentTone = Int(String(replacement.last!)) ?? 0
            } else if char == " " && currentTone > 0 {
                tones.append(currentTone)
                currentTone = 0
            } else if char.isNumber {
                if let tone = Int(String(char)), tone >= 1 && tone <= 4 {
                    currentTone = tone
                }
            }
        }
        
        if currentTone > 0 {
            tones.append(currentTone)
        }
        
        return tones
    }
    
    // Convert tone numbers to tone marks (simplified version)
    static func convertToToneMarks(_ pinyinWithNumbers: String) -> String {
        // This is a simplified implementation
        // A full implementation would need to handle all vowel combinations
        var result = pinyinWithNumbers
        
        // Replace common patterns
        let replacements = [
            ("a1", "ā"), ("a2", "á"), ("a3", "ǎ"), ("a4", "à"),
            ("e1", "ē"), ("e2", "é"), ("e3", "ě"), ("e4", "è"),
            ("i1", "ī"), ("i2", "í"), ("i3", "ǐ"), ("i4", "ì"),
            ("o1", "ō"), ("o2", "ó"), ("o3", "ǒ"), ("o4", "ò"),
            ("u1", "ū"), ("u2", "ú"), ("u3", "ǔ"), ("u4", "ù"),
            ("ü1", "ǖ"), ("ü2", "ǘ"), ("ü3", "ǚ"), ("ü4", "ǜ"),
            ("v1", "ǖ"), ("v2", "ǘ"), ("v3", "ǚ"), ("v4", "ǜ")
        ]
        
        for (pattern, replacement) in replacements {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return result
    }
}