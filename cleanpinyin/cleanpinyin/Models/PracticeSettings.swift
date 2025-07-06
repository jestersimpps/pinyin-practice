import Foundation

struct PracticeSettings: Codable {
    var selectedHSKLevels: Set<Int> = [1]
    var practiceMode: PracticeMode = .sequential
    var showToneNumbers: Bool = true
    var showEnglishTranslation: Bool = true
    var showHints: Bool = true
    var showPronunciationHints: Bool = true
    var showCharacterHints: Bool = true
    var requireTones: Bool = false
    var useTraditional: Bool = false
    var showFullMeaning: Bool = false
    var selectedChapters: Set<String> = []
    var isReviewMode: Bool = false
    var lastPracticeMode: LastPracticeMode = .quick
    
    init() {
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        selectedHSKLevels = try container.decodeIfPresent(Set<Int>.self, forKey: .selectedHSKLevels) ?? [1]
        practiceMode = try container.decodeIfPresent(PracticeMode.self, forKey: .practiceMode) ?? .sequential
        showToneNumbers = try container.decodeIfPresent(Bool.self, forKey: .showToneNumbers) ?? true
        showEnglishTranslation = try container.decodeIfPresent(Bool.self, forKey: .showEnglishTranslation) ?? true
        showHints = try container.decodeIfPresent(Bool.self, forKey: .showHints) ?? true
        requireTones = try container.decodeIfPresent(Bool.self, forKey: .requireTones) ?? false
        useTraditional = try container.decodeIfPresent(Bool.self, forKey: .useTraditional) ?? false
        showFullMeaning = try container.decodeIfPresent(Bool.self, forKey: .showFullMeaning) ?? false
        
        showPronunciationHints = try container.decodeIfPresent(Bool.self, forKey: .showPronunciationHints) ?? showHints
        showCharacterHints = try container.decodeIfPresent(Bool.self, forKey: .showCharacterHints) ?? showHints
        
        selectedChapters = try container.decodeIfPresent(Set<String>.self, forKey: .selectedChapters) ?? []
        isReviewMode = try container.decodeIfPresent(Bool.self, forKey: .isReviewMode) ?? false
        lastPracticeMode = try container.decodeIfPresent(LastPracticeMode.self, forKey: .lastPracticeMode) ?? .quick
    }
    
}