import Foundation

struct WordDifficulty: Codable {
    let wordId: String
    var attempts: Int = 0
    var correctAttempts: Int = 0
    var averageResponseTime: TimeInterval = 0
    var lastAttemptDate: Date?
    var difficultyScore: Double = 0.5
    
    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(attempts)
    }
    
    mutating func recordAttempt(isCorrect: Bool, responseTime: TimeInterval) {
        attempts += 1
        if isCorrect {
            correctAttempts += 1
        }
        
        averageResponseTime = ((averageResponseTime * Double(attempts - 1)) + responseTime) / Double(attempts)
        lastAttemptDate = Date()
        
        updateDifficultyScore()
    }
    
    private mutating func updateDifficultyScore() {
        let accuracyWeight = 0.6
        let speedWeight = 0.4
        
        let accuracyScore = 1.0 - accuracy
        
        let normalizedSpeed = min(averageResponseTime / 10.0, 1.0)
        
        difficultyScore = (accuracyScore * accuracyWeight) + (normalizedSpeed * speedWeight)
    }
}