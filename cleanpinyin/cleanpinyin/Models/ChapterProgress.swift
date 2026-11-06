import Foundation

struct ChapterProgress: Codable, Equatable {
    let chapterId: String
    var wordsCompleted: Set<String>
    var totalWords: Int
    var isCompleted: Bool
    var completionDate: Date?
    var totalAttempts: Int = 0
    var correctAttempts: Int = 0
    var totalPracticeTime: TimeInterval = 0
    var lastPracticeDate: Date?
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsCompleted.count) / Double(totalWords) * 100
    }
    
    var accuracy: Double? {
        guard totalAttempts > 0 else { return nil }
        return Double(correctAttempts) / Double(totalAttempts) * 100
    }
    
    mutating func markWordCompleted(_ wordId: String) {
        wordsCompleted.insert(wordId)
        if wordsCompleted.count == totalWords && !isCompleted {
            isCompleted = true
            completionDate = Date()
        }
    }
    
    mutating func recordAttempt(isCorrect: Bool, practiceTime: TimeInterval) {
        totalAttempts += 1
        if isCorrect {
            correctAttempts += 1
        }
        totalPracticeTime += practiceTime
        lastPracticeDate = Date()
    }
}