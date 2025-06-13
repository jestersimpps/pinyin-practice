import Foundation

enum HSKLevel: Int, CaseIterable, Codable {
    case hsk1 = 1
    case hsk2 = 2
    case hsk3 = 3
    case hsk4 = 4
    case hsk5 = 5
    case hsk6 = 6
    
    var displayName: String {
        return "HSK \(rawValue)"
    }
}

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
    
    var id: String { s }
    var simplified: String { s }
    var traditional: String { t }
    var radical: String { r }
    var frequency: Int { q }
    var partOfSpeech: [String] { p }
    var meanings: [String] { m }
    var classifiers: [String]? { c }
    var characterHint: String { ch }
    var pronunciationHint: String { ph }
    var toneNumbers: String { tn }
    
    var pinyin: String {
        // Convert tone numbers to pinyin with tone marks
        return toneNumbers
    }
    
    var pinyinNumeric: String {
        // Return the numeric pinyin format
        return toneNumbers
    }
    
    var english: String {
        UserProgressService.shared.settings.showFullMeaning ? englishFull : englishClean
    }
    
    var englishClean: String {
        return meanings.map { meaning in
            if meaning.lowercased().starts(with: "variant of") {
                if let commaIndex = meaning.firstIndex(of: ",") {
                    return String(meaning[meaning.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
                }
            }
            return meaning
        }.joined(separator: "; ")
    }
    
    var englishFull: String {
        meanings.joined(separator: "; ")
    }
    
    func isPinyinCorrect(_ input: String, requireTones: Bool = true) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get all possible pronunciations (split by comma if multiple exist)
        let possiblePinyins = toneNumbers.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Check if input matches any of the possible pronunciations
        for pinyin in possiblePinyins {
            if normalizedInput == pinyin {
                return true
            }
            
            if !requireTones {
                let inputWithoutNumbers = normalizedInput.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
                let pinyinWithoutNumbers = pinyin.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
                
                if inputWithoutNumbers == pinyinWithoutNumbers {
                    return true
                }
            }
        }
        
        return false
    }
    
    func isPinyinPartiallyCorrect(_ input: String) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let inputWithoutNumbers = normalizedInput.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
        
        // Get all possible pronunciations (split by comma if multiple exist)
        let possiblePinyins = toneNumbers.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Check if input matches any pronunciation without tones
        for pinyin in possiblePinyins {
            let pinyinWithoutNumbers = pinyin.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
            
            if inputWithoutNumbers == pinyinWithoutNumbers {
                return true
            }
        }
        
        return false
    }
}