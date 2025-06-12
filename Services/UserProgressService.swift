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
        // Load saved data
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
    
    func startNewSession() -> Date {
        return Date()
    }
    
    func endSession(startTime: Date, wordsStudied: Int) {
        let duration = Date().timeIntervalSince(startTime)
        let correctInSession = progress.correctAnswers - (sessions.last?.correctAnswers ?? 0)
        let accuracy = wordsStudied > 0 ? Double(correctInSession) / Double(wordsStudied) * 100 : 0
        
        let session = PracticeSession(
            date: Date(),
            duration: duration,
            wordsStudied: wordsStudied,
            correctAnswers: correctInSession,
            accuracy: accuracy,
            hskLevels: Array(settings.selectedHSKLevels),
            categories: Array(settings.selectedCategories)
        )
        
        sessions.append(session)
        saveSessions()
    }
    
    func resetProgress() {
        progress.reset()
        sessions.removeAll()
        saveSessions()
    }
    
    // Computed properties for UI
    var hasIncorrectWords: Bool {
        !progress.incorrectWords.isEmpty
    }
    
    var canPracticeReview: Bool {
        settings.practiceMode == .reviewMistakes && hasIncorrectWords
    }
    
    func getTotalWordsLearned() -> Int {
        progress.completedWords.count
    }
    
    func getIncorrectWords() -> Set<String> {
        progress.incorrectWords
    }
}