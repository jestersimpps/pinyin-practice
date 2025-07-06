import Foundation

struct ChapterProgress: Codable {
    let chapterId: String
    var wordsCompleted: Set<String>
    var totalWords: Int
    var isCompleted: Bool
    var completionDate: Date?
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsCompleted.count) / Double(totalWords) * 100
    }
    
    mutating func markWordCompleted(_ wordId: String) {
        wordsCompleted.insert(wordId)
        if wordsCompleted.count >= totalWords {
            isCompleted = true
            if completionDate == nil {
                completionDate = Date()
            }
        }
    }
}

struct ChapterProgressV2: Codable {
    let chapterId: String
    var wordAttempts: [String: WordAttemptRecord] = [:]
    var totalWords: Int = 0
    
    struct WordAttemptRecord: Codable {
        var attempts: Int = 0
        var correctAttempts: Int = 0
        var lastAttemptDate: Date?
        var firstCorrectDate: Date?
    }
    
    var correctWords: Set<String> {
        Set(wordAttempts.compactMap { $0.value.correctAttempts > 0 ? $0.key : nil })
    }
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(correctWords.count) / Double(totalWords) * 100
    }
    
    mutating func recordWordAttempt(wordId: String, isCorrect: Bool) {
        if wordAttempts[wordId] == nil {
            wordAttempts[wordId] = WordAttemptRecord()
        }
        
        wordAttempts[wordId]?.attempts += 1
        wordAttempts[wordId]?.lastAttemptDate = Date()
        
        if isCorrect {
            wordAttempts[wordId]?.correctAttempts += 1
            if wordAttempts[wordId]?.firstCorrectDate == nil {
                wordAttempts[wordId]?.firstCorrectDate = Date()
            }
        }
    }
}