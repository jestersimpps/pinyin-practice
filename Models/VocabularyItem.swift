import Foundation

enum HSKLevel: Int, CaseIterable, Codable {
    case hsk1 = 1
    case hsk2 = 2
    case hsk3 = 3
    case hsk4 = 4
    
    var displayName: String {
        return "HSK \(rawValue)"
    }
    
    var wordCount: Int {
        switch self {
        case .hsk1: return 150
        case .hsk2: return 300
        case .hsk3: return 600
        case .hsk4: return 1200
        }
    }
}

enum VocabularyCategory: String, CaseIterable, Codable {
    case emotions = "emotions"
    case numbers = "numbers"
    case family = "family"
    case objects = "objects"
    case places = "places"
    case concepts = "concepts"
    case phrases = "phrases"
    case grammar = "grammar"
    case food = "food"
    case drinks = "drinks"
    case verbs = "verbs"
    case transportation = "transportation"
    case actions = "actions"
    case adjectives = "adjectives"
    case measure = "measure"
    case technology = "technology"
    case entertainment = "entertainment"
    case adverbs = "adverbs"
    case questionWords = "question words"
    case time = "time"
    case work = "work"
    case animals = "animals"
    case language = "language"
    case conjunctions = "conjunctions"
    case directions = "directions"
    case modalVerbs = "modal verbs"
    case pronouns = "pronouns"
    case countries = "countries"
    case activities = "activities"
    case body = "body"
    case behavior = "behavior"
    case expressions = "expressions"
    case finance = "finance"
    case professions = "professions"
    case health = "health"
    case education = "education"
    case weather = "weather"
    case clothing = "clothing"
    case nature = "nature"
    case other = "other"
    
    var displayName: String {
        return self.rawValue.capitalized.replacingOccurrences(of: "_", with: " ")
    }
    
    var icon: String {
        switch self {
        case .emotions: return "heart.fill"
        case .numbers: return "number"
        case .family: return "person.2.fill"
        case .objects: return "cube.fill"
        case .places: return "map.fill"
        case .food: return "fork.knife"
        case .drinks: return "cup.and.saucer.fill"
        case .verbs, .actions: return "figure.walk"
        case .transportation: return "car.fill"
        case .adjectives: return "textformat.abc"
        case .technology: return "desktopcomputer"
        case .entertainment: return "tv.fill"
        case .animals: return "pawprint.fill"
        case .time: return "clock.fill"
        case .work, .professions: return "briefcase.fill"
        case .health: return "heart.text.square.fill"
        case .education: return "graduationcap.fill"
        case .weather: return "cloud.sun.fill"
        case .clothing: return "tshirt.fill"
        case .nature: return "leaf.fill"
        default: return "star.fill"
        }
    }
}

struct VocabularyItem: Identifiable, Codable {
    let id: String
    let chinese: String
    let pinyin: String
    let pinyinNumeric: String
    let english: String
    let category: VocabularyCategory
    let hskLevel: HSKLevel
    let hint: String?
    
    // Computed property to check if pinyin is valid
    func isPinyinCorrect(_ input: String, requireTones: Bool = true) -> Bool {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPinyin = pinyin.lowercased()
        let normalizedNumeric = pinyinNumeric.lowercased()
        
        // Exact match with tones
        if normalizedInput == normalizedPinyin || normalizedInput == normalizedNumeric {
            return true
        }
        
        // If tones not required, check without tones
        if !requireTones {
            let inputWithoutTones = removeTones(from: normalizedInput)
            let pinyinWithoutTones = removeTones(from: normalizedPinyin)
            return inputWithoutTones == pinyinWithoutTones
        }
        
        return false
    }
    
    // Check if pinyin is partially correct (correct syllables but wrong tones)
    func isPinyinPartiallyCorrect(_ input: String) -> Bool {
        let inputWithoutTones = removeTones(from: input.lowercased())
        let pinyinWithoutTones = removeTones(from: pinyin.lowercased())
        
        return inputWithoutTones == pinyinWithoutTones
    }
    
    private func removeTones(from pinyin: String) -> String {
        // Remove tone marks and numbers
        var result = pinyin
        
        // Replace tone marked vowels with plain vowels
        let toneMap = [
            "ā": "a", "á": "a", "ǎ": "a", "à": "a",
            "ē": "e", "é": "e", "ě": "e", "è": "e",
            "ī": "i", "í": "i", "ǐ": "i", "ì": "i",
            "ō": "o", "ó": "o", "ǒ": "o", "ò": "o",
            "ū": "u", "ú": "u", "ǔ": "u", "ù": "u",
            "ǖ": "ü", "ǘ": "ü", "ǚ": "ü", "ǜ": "ü"
        ]
        
        for (toned, plain) in toneMap {
            result = result.replacingOccurrences(of: toned, with: plain)
        }
        
        // Remove tone numbers (1-4)
        result = result.replacingOccurrences(of: "[1-4]", with: "", options: .regularExpression)
        
        return result
    }
}

// Extension to create from TypeScript data
extension VocabularyItem {
    init(id: String, chinese: String, pinyin: String, english: String, category: String, hint: String? = nil, level: HSKLevel = .hsk1) {
        self.id = id
        self.chinese = chinese
        self.pinyin = pinyin
        self.english = english
        self.category = VocabularyCategory(rawValue: category) ?? .other
        self.hskLevel = level
        self.hint = hint
        
        // Generate numeric pinyin from tone marks
        self.pinyinNumeric = Self.convertToNumericPinyin(pinyin)
    }
    
    static func convertToNumericPinyin(_ pinyin: String) -> String {
        var result = pinyin
        
        let toneMap: [(pattern: String, tone: String)] = [
            // First tone
            ("ā", "a1"), ("ē", "e1"), ("ī", "i1"), ("ō", "o1"), ("ū", "u1"), ("ǖ", "ü1"),
            // Second tone
            ("á", "a2"), ("é", "e2"), ("í", "i2"), ("ó", "o2"), ("ú", "u2"), ("ǘ", "ü2"),
            // Third tone
            ("ǎ", "a3"), ("ě", "e3"), ("ǐ", "i3"), ("ǒ", "o3"), ("ǔ", "u3"), ("ǚ", "ü3"),
            // Fourth tone
            ("à", "a4"), ("è", "e4"), ("ì", "i4"), ("ò", "o4"), ("ù", "u4"), ("ǜ", "ü4")
        ]
        
        for (pattern, replacement) in toneMap {
            result = result.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return result
    }
}