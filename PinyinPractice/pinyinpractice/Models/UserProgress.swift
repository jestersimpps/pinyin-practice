import Foundation

struct UserProgress: Codable {
    var wordsSeenCount: Int = 0
    var correctAnswers: Int = 0
    var totalAttempts: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var incorrectWords: Set<String> = []
    var seenWords: Set<String> = []
    var lastSeenWordId: String?
    var lastPracticeDate: Date?
    var chapterProgress: [String: ChapterProgress] = [:]
    
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAttempts) * 100
    }
    
    var formattedAccuracy: String {
        return String(format: "%.0f%%", accuracy)
    }
    
    mutating func recordAnswer(wordId: String, isCorrect: Bool) {
        totalAttempts += 1
        seenWords.insert(wordId)
        lastSeenWordId = wordId
        lastPracticeDate = Date()
        
        if isCorrect {
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            incorrectWords.remove(wordId)
        } else {
            currentStreak = 0
            incorrectWords.insert(wordId)
        }
        
        wordsSeenCount = seenWords.count
    }
    
    mutating func reset() {
        wordsSeenCount = 0
        correctAnswers = 0
        totalAttempts = 0
        currentStreak = 0
        bestStreak = 0
        incorrectWords.removeAll()
        seenWords.removeAll()
        lastSeenWordId = nil
        lastPracticeDate = nil
        chapterProgress.removeAll()
    }
    
    func getChapterProgress(chapterId: String) -> ChapterProgress? {
        return chapterProgress[chapterId]
    }
    
    mutating func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool {
        var wasJustCompleted = false
        
        
        if chapterProgress[chapterId] == nil {
            chapterProgress[chapterId] = ChapterProgress(
                chapterId: chapterId,
                wordsCompleted: [],
                totalWords: totalWords,
                isCompleted: false,
                completionDate: nil
            )
        }
        
        let wasCompleted = chapterProgress[chapterId]?.isCompleted ?? false
        chapterProgress[chapterId]?.markWordCompleted(wordId)
        let isNowCompleted = chapterProgress[chapterId]?.isCompleted ?? false
        
        
        // Return true if the chapter was just completed (wasn't complete before, but is now)
        wasJustCompleted = !wasCompleted && isNowCompleted
        
        return wasJustCompleted
    }
    
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool {
        // Review chapters are never unlocked (they have no content)
        let reviewChapters = [15, 28, 42, 56, 68, 80]
        if reviewChapters.contains(chapter) { return false }
        
        // First chapter of each level is always unlocked
        if chapter == 1 { return true }  // HSK1 start
        if chapter == 16 { return true } // HSK2 start
        if chapter == 29 { return true } // HSK3 start
        if chapter == 43 { return true } // HSK4 start
        if chapter == 57 { return true } // HSK5 start
        if chapter == 69 { return true } // HSK6 start
        
        // Find the previous non-review chapter
        var previousChapter = chapter - 1
        while reviewChapters.contains(previousChapter) && previousChapter > 0 {
            previousChapter -= 1
        }
        
        // Check if previous chapter is 80% complete
        // The chapter ID format is "chapter1", "chapter2", etc. for curriculum-based organization
        let previousChapterId = "chapter\(previousChapter)"
        
        
        if let previousProgress = chapterProgress[previousChapterId] {
            let percentage = previousProgress.completionPercentage
            let isUnlocked = percentage >= 80.0
            
            
            return isUnlocked
        }
        
        
        return false
    }
}

struct PracticeSession: Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let wordsStudied: Int
    let correctAnswers: Int
    let accuracy: Double
    let hskLevels: [Int]
    
    init(id: UUID = UUID(), date: Date, duration: TimeInterval, wordsStudied: Int, correctAnswers: Int, accuracy: Double, hskLevels: [Int]) {
        self.id = id
        self.date = date
        self.duration = duration
        self.wordsStudied = wordsStudied
        self.correctAnswers = correctAnswers
        self.accuracy = accuracy
        self.hskLevels = hskLevels
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PracticeSettings: Codable {
    var selectedHSKLevels: Set<Int> = [1]
    var practiceMode: PracticeMode = .sequential
    var showToneNumbers: Bool = true
    var showEnglishTranslation: Bool = true
    var showHints: Bool = true  // Legacy - will be deprecated
    var showPronunciationHints: Bool = true
    var showCharacterHints: Bool = true
    var requireTones: Bool = false
    var useTraditional: Bool = false
    var showFullMeaning: Bool = false
    var selectedChapters: Set<String> = []  // Format: "hsk1_chapter1"
    var isReviewMode: Bool = false  // Flag to indicate review mistakes mode
    var lastPracticeMode: LastPracticeMode = .quick  // Track the last practice mode used
    
    init() {
        // Default initializer uses the default values
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
        
        // Migration: if new hint settings don't exist, use the legacy showHints value
        showPronunciationHints = try container.decodeIfPresent(Bool.self, forKey: .showPronunciationHints) ?? showHints
        showCharacterHints = try container.decodeIfPresent(Bool.self, forKey: .showCharacterHints) ?? showHints
        
        selectedChapters = try container.decodeIfPresent(Set<String>.self, forKey: .selectedChapters) ?? []
        isReviewMode = try container.decodeIfPresent(Bool.self, forKey: .isReviewMode) ?? false
        lastPracticeMode = try container.decodeIfPresent(LastPracticeMode.self, forKey: .lastPracticeMode) ?? .quick
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
        case levels(Set<Int>)    // Custom practice with HSK levels
        case chapters(Set<String>) // Chapter practice
        case review(Set<String>)   // Review mistakes
    }
    
    enum LastPracticeMode: String, Codable {
        case quick = "quick"           // Quick practice (default)
        case custom = "custom"         // Custom practice with selected levels
        case chapters = "chapters"     // Chapter-based practice
        case review = "review"         // Review mistakes
    }
}