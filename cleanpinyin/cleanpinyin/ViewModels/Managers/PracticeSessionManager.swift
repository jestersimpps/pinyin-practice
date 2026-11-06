import Foundation

class PracticeSessionManager {
    private(set) var sessionStartTime: Date?
    private(set) var sessionCorrectAnswers: Int = 0
    private(set) var sessionTotalAttempts: Int = 0
    private(set) var wordsCompleted: Int = 0
    private(set) var combo: Int = 0
    private(set) var bestCombo: Int = 0

    func startNewSession(at date: Date = Date()) {
        sessionStartTime = date
        sessionCorrectAnswers = 0
        sessionTotalAttempts = 0
        wordsCompleted = 0
        combo = 0
        bestCombo = 0
    }

    func recordAttempt(isCorrect: Bool) {
        sessionTotalAttempts += 1
        if isCorrect {
            sessionCorrectAnswers += 1
            combo += 1
            bestCombo = max(bestCombo, combo)
        } else {
            combo = 0
        }
    }

    func recordWordCompletion() {
        wordsCompleted += 1
    }

    func getSessionStats(practiceModeName: String, now: Date = Date()) -> SessionStats? {
        guard wordsCompleted > 0, let startTime = sessionStartTime else { return nil }

        return SessionStats(
            wordsStudied: wordsCompleted,
            correctAnswers: sessionCorrectAnswers,
            totalAttempts: sessionTotalAttempts,
            practiceMode: practiceModeName,
            duration: now.timeIntervalSince(startTime),
            bestCombo: bestCombo
        )
    }

    // Saves the session once; later calls do nothing until a new session starts
    func endSession(progressService: UserProgressServiceProtocol, hskLevels: [Int]) {
        guard let startTime = sessionStartTime, wordsCompleted > 0 else { return }

        progressService.endSession(
            startTime: startTime,
            wordsStudied: wordsCompleted,
            correctAnswers: sessionCorrectAnswers,
            totalAttempts: sessionTotalAttempts,
            hskLevels: hskLevels
        )
        sessionStartTime = nil
    }
}
