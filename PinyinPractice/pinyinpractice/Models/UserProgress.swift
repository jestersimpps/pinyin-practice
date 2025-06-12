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
    }
}

struct PracticeSession: Codable {
    let id: UUID = UUID()
    let date: Date
    let duration: TimeInterval
    let wordsStudied: Int
    let correctAnswers: Int
    let accuracy: Double
    let hskLevels: [HSKLevel]
    let categories: [VocabularyCategory]
    
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
    var selectedHSKLevels: Set<HSKLevel> = [.hsk1]
    var selectedCategories: Set<VocabularyCategory> = Set(VocabularyCategory.allCases)
    var practiceMode: PracticeMode = .sequential
    var showToneNumbers: Bool = true
    var showEnglishTranslation: Bool = true
    var showHints: Bool = true
    var requireTones: Bool = true
    
    enum PracticeMode: String, CaseIterable, Codable {
        case sequential = "Sequential"
        case random = "Random"
        case reviewMistakes = "Review Mistakes"
        
        var icon: String {
            switch self {
            case .sequential: return "list.number"
            case .random: return "shuffle"
            case .reviewMistakes: return "exclamationmark.triangle"
            }
        }
        
        var description: String {
            switch self {
            case .sequential: return "Study words in HSK order"
            case .random: return "Random order, prioritizing new words"
            case .reviewMistakes: return "Focus on words you got wrong"
            }
        }
    }
}