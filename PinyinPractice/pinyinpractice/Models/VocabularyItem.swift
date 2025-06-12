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

struct Transcriptions: Codable {
    let y: String
    let n: String
    let w: String?
    let b: String?
    let g: String?
    
    var pinyin: String { y }
    var numeric: String { n }
    var wadeGiles: String? { w }
    var bopomofo: String? { b }
    var gwoyeuRomatzyh: String? { g }
}

struct VocabularyForm: Codable {
    let t: String
    let i: Transcriptions
    let m: [String]
    let c: [String]?
    
    var traditional: String { t }
    var transcriptions: Transcriptions { i }
    var meanings: [String] { m }
    var classifiers: [String]? { c }
}

struct VocabularyItem: Identifiable, Codable {
    let s: String
    let r: String
    let q: Int
    let p: [String]
    let f: [VocabularyForm]
    
    var id: String { s }
    var simplified: String { s }
    var radical: String { r }
    var frequency: Int { q }
    var partOfSpeech: [String] { p }
    var forms: [VocabularyForm] { f }
    
    var pinyin: String {
        forms.first?.transcriptions.pinyin ?? ""
    }
    
    var pinyinNumeric: String {
        forms.first?.transcriptions.numeric ?? ""
    }
    
    var traditional: String {
        forms.first?.traditional ?? simplified
    }
    
    var english: String {
        UserProgressService.shared.settings.showFullMeaning ? englishFull : englishClean
    }
    
    var englishClean: String {
        let meanings = forms.first?.meanings ?? []
        return meanings.map { meaning in
            // Remove "variant of X" prefix if present
            if meaning.lowercased().starts(with: "variant of") {
                if let commaIndex = meaning.firstIndex(of: ",") {
                    return String(meaning[meaning.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
                }
            }
            return meaning
        }.joined(separator: "; ")
    }
    
    var englishFull: String {
        forms.first?.meanings.joined(separator: "; ") ?? ""
    }
    
    var meanings: [String] {
        forms.first?.meanings ?? []
    }
    
    func isPinyinCorrect(_ input: String, requireTones: Bool = true) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPinyin = pinyin.lowercased()
        let normalizedNumeric = pinyinNumeric.lowercased()
        
        if normalizedInput == normalizedPinyin || normalizedInput == normalizedNumeric {
            return true
        }
        
        if !requireTones {
            // Simply remove numbers from both input and numeric pinyin
            let inputWithoutNumbers = normalizedInput.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
            let numericWithoutNumbers = normalizedNumeric.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
            
            return inputWithoutNumbers == numericWithoutNumbers
        }
        
        return false
    }
    
    func isPinyinPartiallyCorrect(_ input: String) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNumeric = pinyinNumeric.lowercased()
        
        // Remove numbers from both
        let inputWithoutNumbers = normalizedInput.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
        let numericWithoutNumbers = normalizedNumeric.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
        
        return inputWithoutNumbers == numericWithoutNumbers
    }
}