import Foundation
import SwiftUI

class UserProgressService: ObservableObject, UserProgressServiceProtocol {
    static let shared = UserProgressService()
    
    @Published var progress: UserProgress {
        didSet {
            saveProgress()
        }
    }
    
    @Published var settings: PracticeSettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var sessions: [PracticeSession] = []
    
    private let progressKey = "UserProgress"
    private let settingsKey = "PracticeSettings"
    private let sessionsKey = "PracticeSessions"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.progress = decoded
        } else {
            self.progress = UserProgress()
        }
        
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(PracticeSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = PracticeSettings()
        }
        
        // Ensure settings are saved after loading to persist any new default values
        saveSettings()
        
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            self.sessions = decoded
        } else {
            self.sessions = []
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    func recordAnswer(for word: VocabularyItem, isCorrect: Bool) {
        progress.recordAnswer(wordId: word.id, isCorrect: isCorrect)
    }
    
    func recordAnswer(wordId: String, isCorrect: Bool, chapterId: String?, chapterSize: Int) {
        progress.recordAnswer(wordId: wordId, isCorrect: isCorrect)
        if let chapterId = chapterId {
            updateChapterProgress(chapterId: chapterId, wordId: wordId, totalWords: chapterSize)
        }
    }
    
    func recordSkip(wordId: String, chapterId: String?) {
        // Record skip as incorrect answer
        progress.recordAnswer(wordId: wordId, isCorrect: false)
    }
    
    func recordSessionCompletion(correctAnswers: Int, totalQuestions: Int, levels: Set<Int>) {
        // This is handled by endSession method
    }
    
    func getAccuracyForLastNSessions(_ n: Int) -> Double? {
        let recentSessions = sessions.suffix(n)
        guard !recentSessions.isEmpty else { return nil }
        
        let totalCorrect = recentSessions.reduce(0) { $0 + $1.correctAnswers }
        let totalQuestions = recentSessions.reduce(0) { $0 + $1.wordsStudied }
        
        guard totalQuestions > 0 else { return nil }
        return Double(totalCorrect) / Double(totalQuestions) * 100
    }
    
    func getTotalPracticeTime() -> TimeInterval {
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    func getStreakDays() -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streakDays = 0
        var currentDate = today
        
        // Group sessions by day
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        
        // Count consecutive days backwards from today
        while sessionDays.contains(currentDate) {
            streakDays += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // If no practice today, check if there was practice yesterday
        if streakDays == 0 {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if sessionDays.contains(yesterday) {
                currentDate = yesterday
                while sessionDays.contains(currentDate) {
                    streakDays += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                }
            }
        }
        
        return streakDays
    }
    
    func updateSettings(_ settings: PracticeSettings) {
        self.settings = settings
    }
    
    @discardableResult
    func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool {
        return progress.updateChapterProgress(chapterId: chapterId, wordId: wordId, totalWords: totalWords)
    }
    
    func getChapterProgress(chapterId: String) -> ChapterProgress? {
        return progress.getChapterProgress(chapterId: chapterId)
    }
    
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool {
        return progress.isChapterUnlocked(level: level, chapter: chapter)
    }
    
    func cleanupSelectedChapters() {
        // Remove any selected chapters that are now locked
        var validChapters: Set<String> = []
        
        for chapterId in settings.selectedChapters {
            if let chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter_", with: "")) {
                let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
                if isChapterUnlocked(level: chapterInfo.hskLevel, chapter: chapterNumber) {
                    validChapters.insert(chapterId)
                }
            }
        }
        
        settings.selectedChapters = validChapters
    }
    
    func startNewSession() -> Date {
        return Date()
    }
    
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int, totalAttempts: Int) {
        let duration = Date().timeIntervalSince(startTime)
        
        let sessionCorrect = correctAnswers
        let sessionTotal = totalAttempts
        
        let accuracy = sessionTotal > 0 ? Double(sessionCorrect) / Double(sessionTotal) * 100 : 0
        
        let session = PracticeSession(
            date: Date(),
            duration: duration,
            wordsStudied: wordsStudied,
            correctAnswers: sessionCorrect,
            accuracy: accuracy,
            hskLevels: Array(settings.selectedHSKLevels)
        )
        
        sessions.append(session)
        saveSessions()
    }
    
    func resetProgress() {
        progress.reset()
        sessions.removeAll()
        saveSessions()
    }
    
    var hasIncorrectWords: Bool {
        !progress.incorrectWords.isEmpty
    }
    
    var canPracticeReview: Bool {
        hasIncorrectWords
    }
    
    func getTotalWordsLearned() -> Int {
        progress.seenWords.count
    }
    
    func getIncorrectWords() -> Set<String> {
        progress.incorrectWords
    }
    
    func getWordsLearnedForLevel(_ level: Int) -> Int {
        let vocabulary = VocabularyService.shared.vocabularyForLevel(level)
        return vocabulary.filter { progress.seenWords.contains($0.id) }.count
    }
    
    func getSessionsForTimeRange(_ days: Int) -> [PracticeSession] {
        guard days > 0 else { return sessions }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { $0.date >= cutoffDate }
    }
    
    func getAccuracyTrend(days: Int) -> [(date: Date, accuracy: Double)] {
        let sessionsInRange = getSessionsForTimeRange(days)
        return sessionsInRange.map { ($0.date, $0.accuracy) }
    }
    
    func getDailyWordsLearned(days: Int) -> [(date: Date, words: Int)] {
        let sessionsInRange = getSessionsForTimeRange(days)
        
        // Group sessions by day
        let calendar = Calendar.current
        var dailyWords: [Date: Int] = [:]
        
        for session in sessionsInRange {
            let startOfDay = calendar.startOfDay(for: session.date)
            dailyWords[startOfDay] = (dailyWords[startOfDay] ?? 0) + session.wordsStudied
        }
        
        // Convert to sorted array
        return dailyWords.map { ($0.key, $0.value) }.sorted { $0.date < $1.date }
    }
    
    func getDailyPracticeTime(days: Int) -> [(date: Date, minutes: Double)] {
        let sessionsInRange = getSessionsForTimeRange(days)
        
        // Group sessions by day
        let calendar = Calendar.current
        var dailyTime: [Date: TimeInterval] = [:]
        
        for session in sessionsInRange {
            let startOfDay = calendar.startOfDay(for: session.date)
            dailyTime[startOfDay] = (dailyTime[startOfDay] ?? 0) + session.duration
        }
        
        // Convert to sorted array with minutes
        return dailyTime.map { ($0.key, $0.value / 60.0) }.sorted { $0.date < $1.date }
    }
    
    func getTotalPracticeMinutes() -> Int {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        return Int(totalSeconds / 60)
    }
}