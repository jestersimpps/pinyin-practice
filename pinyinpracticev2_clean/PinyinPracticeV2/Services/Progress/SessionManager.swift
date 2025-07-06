import Foundation

protocol SessionManaging {
    func startNewSession() -> Date
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int, totalAttempts: Int)
    func getSessionsForTimeRange(_ days: Int) -> [PracticeSession]
    func getTotalPracticeMinutes() -> Int
}

final class SessionManager: SessionManaging {
    private let storage: StorageService
    private let storageKey = "PracticeSessions"
    private var sessions: [PracticeSession] = []
    private let settings: PracticeSettings
    
    init(storage: StorageService, settings: PracticeSettings) {
        self.storage = storage
        self.settings = settings
        loadSessions()
    }
    
    private func loadSessions() {
        if let loadedSessions = try? storage.load([PracticeSession].self, forKey: storageKey) {
            sessions = loadedSessions
        }
    }
    
    private func saveSessions() {
        try? storage.save(sessions, forKey: storageKey)
    }
    
    func startNewSession() -> Date {
        return Date()
    }
    
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int, totalAttempts: Int) {
        let duration = Date().timeIntervalSince(startTime)
        let accuracy = totalAttempts > 0 ? Double(correctAnswers) / Double(totalAttempts) * 100 : 0
        
        let session = PracticeSession(
            date: Date(),
            duration: duration,
            wordsStudied: wordsStudied,
            correctAnswers: correctAnswers,
            accuracy: accuracy,
            hskLevels: Array(settings.selectedHSKLevels)
        )
        
        sessions.append(session)
        saveSessions()
    }
    
    func getSessionsForTimeRange(_ days: Int) -> [PracticeSession] {
        guard days > 0 else { return sessions }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { $0.date >= cutoffDate }
    }
    
    func getTotalPracticeMinutes() -> Int {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60)
    }
}