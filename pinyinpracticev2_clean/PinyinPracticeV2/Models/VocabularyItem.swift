import Foundation

struct VocabularyItem: Codable, Identifiable, Hashable {
    let id: String
    let simplified: String
    let traditional: String
    let pinyin: String
    let toneNumbers: String
    let english: String
    let frequency: Int
    let hskLevel: Int
    let cp: Int?
    
    var displayCharacter: String {
        return simplified
    }
    
    func isPinyinCorrect(_ input: String, requireTones: Bool) -> Bool {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if requireTones {
            return normalizedInput == pinyin.lowercased() || normalizedInput == toneNumbers.lowercased()
        } else {
            let inputWithoutTones = removeTones(from: normalizedInput)
            let pinyinWithoutTones = removeTones(from: pinyin.lowercased())
            return inputWithoutTones == pinyinWithoutTones
        }
    }
    
    func isPinyinPartiallyCorrect(_ input: String) -> Bool {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let inputWithoutTones = removeTones(from: normalizedInput)
        let pinyinWithoutTones = removeTones(from: pinyin.lowercased())
        return inputWithoutTones == pinyinWithoutTones
    }
    
    private func removeTones(from text: String) -> String {
        return text
            .replacingOccurrences(of: "ā", with: "a").replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "ǎ", with: "a").replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ē", with: "e").replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "ě", with: "e").replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ī", with: "i").replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ǐ", with: "i").replacingOccurrences(of: "ì", with: "i")
            .replacingOccurrences(of: "ō", with: "o").replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ǒ", with: "o").replacingOccurrences(of: "ò", with: "o")
            .replacingOccurrences(of: "ū", with: "u").replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ǔ", with: "u").replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "ǖ", with: "ü").replacingOccurrences(of: "ǘ", with: "ü")
            .replacingOccurrences(of: "ǚ", with: "ü").replacingOccurrences(of: "ǜ", with: "ü")
    }
}