import Foundation

struct PracticeSettings: Codable {
    var selectedHSKLevels: Set<Int> = [1]
    var practiceMode: PracticeMode = .sequential
    var showToneNumbers: Bool = true
    var showEnglishTranslation: Bool = true
    var showPronunciationHints: Bool = true
    var showCharacterHints: Bool = true
    var requireTones: Bool = false
    var useTraditional: Bool = false
    var showFullMeaning: Bool = false
    var selectedChapters: Set<String> = []
    var isReviewMode: Bool = false
    var lastPracticeMode: LastPracticeMode = .quick
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        selectedHSKLevels = try container.decodeIfPresent(Set<Int>.self, forKey: .selectedHSKLevels) ?? [1]
        practiceMode = try container.decodeIfPresent(PracticeMode.self, forKey: .practiceMode) ?? .sequential
        showToneNumbers = try container.decodeIfPresent(Bool.self, forKey: .showToneNumbers) ?? true
        showEnglishTranslation = try container.decodeIfPresent(Bool.self, forKey: .showEnglishTranslation) ?? true
        requireTones = try container.decodeIfPresent(Bool.self, forKey: .requireTones) ?? false
        useTraditional = try container.decodeIfPresent(Bool.self, forKey: .useTraditional) ?? false
        showFullMeaning = try container.decodeIfPresent(Bool.self, forKey: .showFullMeaning) ?? false
        
        let showHints = try container.decodeIfPresent(Bool.self, forKey: .showHints) ?? true
        showPronunciationHints = try container.decodeIfPresent(Bool.self, forKey: .showPronunciationHints) ?? showHints
        showCharacterHints = try container.decodeIfPresent(Bool.self, forKey: .showCharacterHints) ?? showHints
        
        selectedChapters = try container.decodeIfPresent(Set<String>.self, forKey: .selectedChapters) ?? []
        isReviewMode = try container.decodeIfPresent(Bool.self, forKey: .isReviewMode) ?? false
        lastPracticeMode = try container.decodeIfPresent(LastPracticeMode.self, forKey: .lastPracticeMode) ?? .quick
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(selectedHSKLevels, forKey: .selectedHSKLevels)
        try container.encode(practiceMode, forKey: .practiceMode)
        try container.encode(showToneNumbers, forKey: .showToneNumbers)
        try container.encode(showEnglishTranslation, forKey: .showEnglishTranslation)
        try container.encode(showPronunciationHints, forKey: .showPronunciationHints)
        try container.encode(showCharacterHints, forKey: .showCharacterHints)
        try container.encode(requireTones, forKey: .requireTones)
        try container.encode(useTraditional, forKey: .useTraditional)
        try container.encode(showFullMeaning, forKey: .showFullMeaning)
        try container.encode(selectedChapters, forKey: .selectedChapters)
        try container.encode(isReviewMode, forKey: .isReviewMode)
        try container.encode(lastPracticeMode, forKey: .lastPracticeMode)
    }
    
    private enum CodingKeys: String, CodingKey {
        case selectedHSKLevels
        case practiceMode
        case showToneNumbers
        case showEnglishTranslation
        case showHints
        case showPronunciationHints
        case showCharacterHints
        case requireTones
        case useTraditional
        case showFullMeaning
        case selectedChapters
        case isReviewMode
        case lastPracticeMode
    }
}

enum PracticeMode: String, CaseIterable, Codable {
    case sequential = "Sequential"
    case random = "Random"
    
    var icon: String {
        switch self {
        case .sequential: return "list.number"
        case .random: return "shuffle"
        }
    }
    
    var description: String {
        switch self {
        case .sequential: return "Study words in HSK order"
        case .random: return "Random order, prioritizing new words"
        }
    }
}

enum LearningMode {
    case levels(Set<Int>)
    case chapters(Set<String>)
    case review(Set<String>)
}

enum LastPracticeMode: String, Codable {
    case quick = "quick"
    case custom = "custom"
    case chapters = "chapters"
    case review = "review"
}