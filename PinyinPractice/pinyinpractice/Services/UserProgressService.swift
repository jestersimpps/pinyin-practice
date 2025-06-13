import Foundation
import SwiftUI

class UserProgressService: ObservableObject {
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
    
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int? = nil, totalAttempts: Int? = nil) {
        let duration = Date().timeIntervalSince(startTime)
        
        // Use provided session stats if available, otherwise calculate from total progress
        let sessionCorrect: Int
        let sessionTotal: Int
        
        if let correct = correctAnswers, let total = totalAttempts {
            sessionCorrect = correct
            sessionTotal = total
        } else {
            // Fallback to old calculation method
            sessionCorrect = progress.correctAnswers - (sessions.last?.correctAnswers ?? 0)
            sessionTotal = wordsStudied
        }
        
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
        let vocabulary = VocabularyService.shared.getVocabularyForLevel(level)
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
}