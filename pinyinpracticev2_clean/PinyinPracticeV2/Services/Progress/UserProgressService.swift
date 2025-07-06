import Foundation
import SwiftUI

final class UserProgressService: ObservableObject {
    private let progressTracker: ProgressTracking
    private let settingsManager: SettingsManaging
    private let sessionManager: SessionManaging
    
    @Published var currentStreak: Int = 0
    @Published var accuracy: String = "0%"
    
    var settings: PracticeSettings { settingsManager.settings }
    var hasIncorrectWords: Bool { !progressTracker.incorrectWords.isEmpty }
    var canPracticeReview: Bool { hasIncorrectWords }
    
    init(
        progressTracker: ProgressTracking,
        settingsManager: SettingsManaging,
        sessionManager: SessionManaging
    ) {
        self.progressTracker = progressTracker
        self.settingsManager = settingsManager
        self.sessionManager = sessionManager
        
        updatePublishedValues()
    }
    
    private func updatePublishedValues() {
        currentStreak = progressTracker.currentStreak
        accuracy = progressTracker.formattedAccuracy
    }
    
    func updateSettings(_ update: (inout PracticeSettings) -> Void) {
        settingsManager.updateSettings(update)
    }
    
    func cleanupSelectedChapters() {
        settingsManager.cleanupSelectedChapters { level, chapter in
            progressTracker.isChapterUnlocked(level: level, chapter: chapter)
        }
    }
    
    func getTotalWordsLearned() -> Int {
        progressTracker.seenWords.count
    }
    
    func getIncorrectWords() -> Set<String> {
        progressTracker.incorrectWords
    }
    
    func getSessionsForTimeRange(_ days: Int) -> [PracticeSession] {
        sessionManager.getSessionsForTimeRange(days)
    }
    
    func getTotalPracticeMinutes() -> Int {
        sessionManager.getTotalPracticeMinutes()
    }
    
    func resetProgress() {
        progressTracker.reset()
        updatePublishedValues()
    }
    
    // Computed properties for accessing progress data
    var progress: (wordsSeenCount: Int, formattedAccuracy: String) {
        return (
            wordsSeenCount: progressTracker.seenWords.count,
            formattedAccuracy: progressTracker.formattedAccuracy
        )
    }
}