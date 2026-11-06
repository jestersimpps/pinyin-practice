import Foundation

struct PracticeSettings: Codable, Equatable {
    static let hskLevels: ClosedRange<Int> = 1...6

    var syllabus: HSKSyllabus = .hsk3
    var selectedHSKLevels: Set<Int> = [1] {
        didSet { selectedHSKLevels = Self.sanitized(selectedHSKLevels) }
    }
    var practiceMode: PracticeMode = .sequential
    var showEnglishTranslation: Bool = true
    var showPronunciationHints: Bool = true
    var showCharacterHints: Bool = true
    var requireTones: Bool = false
    var useTraditional: Bool = false
    var showFullMeaning: Bool = false
    var selectedChapters: Set<String> = []
    var lastPracticeMode: LastPracticeMode = .quick
    var speakOnCorrectAnswer: Bool = true
    var speakMeaningOnNewWord: Bool = true
    var handsFreeVoice: Bool = false
    var imprintAnswerAloud: Bool = false

    private enum CodingKeys: String, CodingKey {
        case syllabus, selectedHSKLevels, practiceMode, showEnglishTranslation, showPronunciationHints, showCharacterHints
        case requireTones, useTraditional, showFullMeaning, selectedChapters, lastPracticeMode, speakOnCorrectAnswer, speakMeaningOnNewWord, handsFreeVoice, imprintAnswerAloud
        case showHints
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyShowHints = try container.decodeIfPresent(Bool.self, forKey: .showHints) ?? true

        // Settings saved before HSK 3.0 existed were made while studying the HSK 2.0 list
        syllabus = try container.decodeIfPresent(HSKSyllabus.self, forKey: .syllabus) ?? .hsk2
        selectedHSKLevels = Self.sanitized(try container.decodeIfPresent(Set<Int>.self, forKey: .selectedHSKLevels) ?? [1])
        practiceMode = try container.decodeIfPresent(PracticeMode.self, forKey: .practiceMode) ?? .sequential
        showEnglishTranslation = try container.decodeIfPresent(Bool.self, forKey: .showEnglishTranslation) ?? true
        showPronunciationHints = try container.decodeIfPresent(Bool.self, forKey: .showPronunciationHints) ?? legacyShowHints
        showCharacterHints = try container.decodeIfPresent(Bool.self, forKey: .showCharacterHints) ?? legacyShowHints
        requireTones = try container.decodeIfPresent(Bool.self, forKey: .requireTones) ?? false
        useTraditional = try container.decodeIfPresent(Bool.self, forKey: .useTraditional) ?? false
        showFullMeaning = try container.decodeIfPresent(Bool.self, forKey: .showFullMeaning) ?? false
        selectedChapters = try container.decodeIfPresent(Set<String>.self, forKey: .selectedChapters) ?? []
        lastPracticeMode = try container.decodeIfPresent(LastPracticeMode.self, forKey: .lastPracticeMode) ?? .quick
        speakOnCorrectAnswer = try container.decodeIfPresent(Bool.self, forKey: .speakOnCorrectAnswer) ?? true
        speakMeaningOnNewWord = try container.decodeIfPresent(Bool.self, forKey: .speakMeaningOnNewWord) ?? true
        handsFreeVoice = try container.decodeIfPresent(Bool.self, forKey: .handsFreeVoice) ?? false
        imprintAnswerAloud = try container.decodeIfPresent(Bool.self, forKey: .imprintAnswerAloud) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(syllabus, forKey: .syllabus)
        try container.encode(selectedHSKLevels, forKey: .selectedHSKLevels)
        try container.encode(practiceMode, forKey: .practiceMode)
        try container.encode(showEnglishTranslation, forKey: .showEnglishTranslation)
        try container.encode(showPronunciationHints, forKey: .showPronunciationHints)
        try container.encode(showCharacterHints, forKey: .showCharacterHints)
        try container.encode(requireTones, forKey: .requireTones)
        try container.encode(useTraditional, forKey: .useTraditional)
        try container.encode(showFullMeaning, forKey: .showFullMeaning)
        try container.encode(selectedChapters, forKey: .selectedChapters)
        try container.encode(lastPracticeMode, forKey: .lastPracticeMode)
        try container.encode(speakOnCorrectAnswer, forKey: .speakOnCorrectAnswer)
        try container.encode(speakMeaningOnNewWord, forKey: .speakMeaningOnNewWord)
        try container.encode(handsFreeVoice, forKey: .handsFreeVoice)
        try container.encode(imprintAnswerAloud, forKey: .imprintAnswerAloud)
    }

    private static func sanitized(_ levels: Set<Int>) -> Set<Int> {
        let valid = levels.filter { hskLevels.contains($0) }
        return valid.isEmpty ? [1] : valid
    }
}
