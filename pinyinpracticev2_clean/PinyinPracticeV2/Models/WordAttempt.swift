import Foundation

struct WordAttempt {
    let wordId: String
    let isCorrect: Bool
    let responseTime: TimeInterval
    let timestamp: Date
    
    init(wordId: String, isCorrect: Bool, responseTime: TimeInterval, timestamp: Date = Date()) {
        self.wordId = wordId
        self.isCorrect = isCorrect
        self.responseTime = responseTime
        self.timestamp = timestamp
    }
}