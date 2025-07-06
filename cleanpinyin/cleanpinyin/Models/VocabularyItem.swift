import Foundation

enum HSKLevel: Int, CaseIterable, Codable {
    case hsk1 = 1
    case hsk2 = 2
    case hsk3 = 3
    case hsk4 = 4
    case hsk5 = 5
    case hsk6 = 6
    
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
    let cp: Int?  // Chapter progression (1-80)
    
    // MARK: - Basic Properties
    var id: String { s }
    var simplified: String { s }
    var traditional: String { t }
    var radical: String { r }
    var frequency: Int { q }
    var partOfSpeech: [String] { p }
    var meanings: [String] { m }
    var characterHint: String { ch }
    var pronunciationHint: String { ph }
    var toneNumbers: String { tn }
    
    // MARK: - Chapter Properties
    var chapter: Int {
        // Use cp (content progression) if available, otherwise default to 1
        return cp ?? 1
    }
    
    var chapterProgression: Int? {
        // Returns the curriculum chapter number (1-80) if available
        return cp
    }
    
    var belongsToChapter: Bool {
        chapterProgression != nil
    }
    
    var chapterIdentifier: String {
        "chapter_\(chapter)"
    }
    
    // MARK: - Pinyin Properties
    var pinyin: String {
        // Convert tone numbers to pinyin with tone marks
        return toneNumbers
    }
    
    var pinyinWithToneMarks: String {
        PinyinConverter.convertToToneMarks(toneNumbers)
    }
    
    var pinyinWithoutTones: String {
        PinyinConverter.removeTones(pinyinWithToneMarks)
    }
    
    var possiblePinyinVariations: [String] {
        toneNumbers.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    var hasTones: Bool {
        PinyinConverter.containsToneMarks(pinyinWithToneMarks) || 
        toneNumbers.contains(where: { "1234".contains($0) })
    }
    
    var numberOfSyllables: Int {
        toneNumbers.split(separator: " ").count
    }
    
    // MARK: - Display Properties
    var displayCharacter: String {
        simplified
    }
    
    var displayPinyin: String {
        pinyinWithToneMarks
    }
    
    var displayMeaning: String {
        english
    }
    
    var shortMeaning: String {
        let firstMeaning = meanings.first ?? ""
        if firstMeaning.count > 30 {
            return String(firstMeaning.prefix(27)) + "..."
        }
        return firstMeaning
    }
    
    // MARK: - English Meaning Properties
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
    
    var primaryMeaning: String {
        meanings.first ?? ""
    }
    
    var hasMultipleMeanings: Bool {
        meanings.count > 1
    }
    
    // MARK: - Character Properties
    var isTraditionalDifferent: Bool {
        simplified != traditional
    }
    
    var characterCount: Int {
        simplified.count
    }
    
    var isSingleCharacter: Bool {
        characterCount == 1
    }
    
    var isPhrase: Bool {
        characterCount > 1
    }
    
    // MARK: - Part of Speech Properties
    var primaryPartOfSpeech: String? {
        partOfSpeech.first
    }
    
    var isNoun: Bool {
        partOfSpeech.contains(where: { $0.lowercased().contains("noun") || $0.lowercased() == "n" })
    }
    
    var isVerb: Bool {
        partOfSpeech.contains(where: { $0.lowercased().contains("verb") || $0.lowercased() == "v" })
    }
    
    var isAdjective: Bool {
        partOfSpeech.contains(where: { $0.lowercased().contains("adj") })
    }
    
    var partsOfSpeechDisplay: String {
        partOfSpeech.joined(separator: ", ")
    }
    
    // MARK: - Validation Methods
    func isPinyinCorrect(_ input: String, requireTones: Bool = true) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if input matches any of the possible pronunciations
        for pinyin in possiblePinyinVariations {
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
        
        // Check if input matches any pronunciation without tones
        for pinyin in possiblePinyinVariations {
            let pinyinWithoutNumbers = pinyin.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
            
            if inputWithoutNumbers == pinyinWithoutNumbers {
                return true
            }
        }
        
        return false
    }
    
    func matchesSearchQuery(_ query: String) -> Bool {
        let lowercasedQuery = query.lowercased()
        
        return simplified.lowercased().contains(lowercasedQuery) ||
               traditional.lowercased().contains(lowercasedQuery) ||
               pinyinWithoutTones.lowercased().contains(lowercasedQuery) ||
               toneNumbers.lowercased().contains(lowercasedQuery) ||
               meanings.contains(where: { $0.lowercased().contains(lowercasedQuery) })
    }
    
    func difficultyScore() -> Int {
        var score = 0
        
        // Character count adds to difficulty
        score += characterCount * 10
        
        // Number of syllables adds to difficulty
        score += numberOfSyllables * 5
        
        // Multiple meanings add complexity
        if hasMultipleMeanings {
            score += meanings.count * 3
        }
        
        // Lower frequency words are harder
        score += max(0, 100 - frequency)
        
        return score
    }
}