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
    
    mutating func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) {
        if chapterProgress[chapterId] == nil {
            chapterProgress[chapterId] = ChapterProgress(
                chapterId: chapterId,
                wordsCompleted: [],
                totalWords: totalWords,
                isCompleted: false,
                completionDate: nil
            )
        }
        chapterProgress[chapterId]?.markWordCompleted(wordId)
    }
    
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool {
        // First chapter is always unlocked
        if chapter == 1 { return true }
        
        // Check if previous chapter is 80% complete
        let previousChapterId = "hsk\(level)_chapter\(chapter - 1)"
        if let previousProgress = chapterProgress[previousChapterId] {
            return previousProgress.completionPercentage >= 80.0
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
    var showAdditionalInfo: Bool = true
    var useTraditional: Bool = false
    var showFullMeaning: Bool = false
    var selectedChapters: Set<String> = []  // Format: "hsk1_chapter1"
    
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
        showAdditionalInfo = try container.decodeIfPresent(Bool.self, forKey: .showAdditionalInfo) ?? true
        useTraditional = try container.decodeIfPresent(Bool.self, forKey: .useTraditional) ?? false
        showFullMeaning = try container.decodeIfPresent(Bool.self, forKey: .showFullMeaning) ?? false
        
        // Migration: if new hint settings don't exist, use the legacy showHints value
        showPronunciationHints = try container.decodeIfPresent(Bool.self, forKey: .showPronunciationHints) ?? showHints
        showCharacterHints = try container.decodeIfPresent(Bool.self, forKey: .showCharacterHints) ?? showHints
        
        selectedChapters = try container.decodeIfPresent(Set<String>.self, forKey: .selectedChapters) ?? []
    }
    
    enum PracticeMode: String, CaseIterable, Codable {
        case sequential = "Sequential"
        case random = "Random"
        case reviewMistakes = "Review Mistakes"
        case chapter = "Chapter"
        
        var icon: String {
            switch self {
            case .sequential: return "list.number"
            case .random: return "shuffle"
            case .reviewMistakes: return "exclamationmark.triangle"
            case .chapter: return "book.closed"
            }
        }
        
        var description: String {
            switch self {
            case .sequential: return "Study words in HSK order"
            case .random: return "Random order, prioritizing new words"
            case .reviewMistakes: return "Focus on words you got wrong"
            case .chapter: return "Study by chapter progression"
            }
        }
    }
}