import Foundation

class PracticeSessionManager {
    private(set) var sessionStartTime: Date?
    private(set) var sessionCorrectAnswers: Int = 0
    private(set) var sessionTotalAttempts: Int = 0
    private(set) var wordsCompleted: Int = 0
    
    func startNewSession() -> Date {
        let startTime = Date()
        sessionStartTime = startTime
        sessionCorrectAnswers = 0
        sessionTotalAttempts = 0
        wordsCompleted = 0
        return startTime
    }
    
    func recordAttempt(isCorrect: Bool) {
        sessionTotalAttempts += 1
        if isCorrect {
            sessionCorrectAnswers += 1
        }
    }
    
    func recordWordCompletion() {
        wordsCompleted += 1
    }
    
    func getSessionStats(practiceModeName: String, currentStreak: Int, bestStreak: Int) -> PracticeCompletionView.SessionStats? {
        guard wordsCompleted > 0,
              let startTime = sessionStartTime else { return nil }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return PracticeCompletionView.SessionStats(
            wordsStudied: wordsCompleted,
            correctAnswers: sessionCorrectAnswers,
            totalAttempts: sessionTotalAttempts,
            practiceMode: practiceModeName,
            duration: duration,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }
    
    func endSession(progressService: UserProgressServiceProtocol) {
        guard let startTime = sessionStartTime,
              wordsCompleted > 0 else { return }
        
        progressService.endSession(
            startTime: startTime,
            wordsStudied: wordsCompleted,
            correctAnswers: sessionCorrectAnswers,
            totalAttempts: sessionTotalAttempts
        )
        
        sessionStartTime = nil
    }
    
    func reset() {
        sessionStartTime = nil
        sessionCorrectAnswers = 0
        sessionTotalAttempts = 0
        wordsCompleted = 0
    }
}