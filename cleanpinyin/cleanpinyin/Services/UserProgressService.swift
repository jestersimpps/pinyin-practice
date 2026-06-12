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
        progress = Self.load(UserProgress.self, forKey: "UserProgress") ?? UserProgress()
        settings = Self.load(PracticeSettings.self, forKey: "PracticeSettings") ?? PracticeSettings()
        sessions = Self.load([PracticeSession].self, forKey: "PracticeSessions") ?? []

        // Persist any new default values introduced since the last save
        saveSettings()
    }

    // MARK: - Persistence
    private static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func saveProgress() {
        save(progress, forKey: progressKey)
    }

    private func saveSettings() {
        save(settings, forKey: settingsKey)
    }

    private func saveSessions() {
        save(sessions, forKey: sessionsKey)
    }

    // MARK: - Answers
    func recordAnswer(for word: VocabularyItem, isCorrect: Bool) {
        progress.recordAnswer(wordId: word.id, isCorrect: isCorrect)
    }

    // MARK: - Sessions
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

    func getAccuracyTrend(days: Int) -> [(date: Date, accuracy: Double)] {
        getSessionsForTimeRange(days).map { ($0.date, $0.accuracy) }
    }

    func getDailyWordsLearned(days: Int) -> [(date: Date, words: Int)] {
        aggregateByDay(days) { $0.wordsStudied }
            .map { (date: $0.date, words: $0.value) }
    }

    func getDailyPracticeTime(days: Int) -> [(date: Date, minutes: Double)] {
        aggregateByDay(days) { $0.duration / 60.0 }
            .map { (date: $0.date, minutes: $0.value) }
    }

    private func aggregateByDay<Value: AdditiveArithmetic>(
        _ days: Int,
        value: (PracticeSession) -> Value
    ) -> [(date: Date, value: Value)] {
        let calendar = Calendar.current
        var daily: [Date: Value] = [:]

        for session in getSessionsForTimeRange(days) {
            let startOfDay = calendar.startOfDay(for: session.date)
            daily[startOfDay] = (daily[startOfDay] ?? .zero) + value(session)
        }

        return daily.map { ($0.key, $0.value) }.sorted { $0.date < $1.date }
    }

    func getTotalPracticeMinutes() -> Int {
        Int(sessions.reduce(0) { $0 + $1.duration } / 60)
    }

    // MARK: - Chapter Progress
    func recordChapterAttempt(chapterId: String, totalWords: Int, isCorrect: Bool, practiceTime: TimeInterval) {
        progress.recordChapterAttempt(chapterId: chapterId, totalWords: totalWords, isCorrect: isCorrect, practiceTime: practiceTime)
    }

    @discardableResult
    func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool {
        progress.updateChapterProgress(chapterId: chapterId, wordId: wordId, totalWords: totalWords)
    }

    func getChapterProgress(chapterId: String) -> ChapterProgress? {
        progress.getChapterProgress(chapterId: chapterId)
    }

    func isChapterUnlocked(chapterId: String) -> Bool {
        progress.isChapterUnlocked(chapterId: chapterId)
    }

    func cleanupSelectedChapters() {
        settings.selectedChapters = settings.selectedChapters.filter { isChapterUnlocked(chapterId: $0) }
    }

    // MARK: - Progress Queries
    var hasIncorrectWords: Bool {
        !progress.incorrectWords.isEmpty
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

    func resetProgress() {
        progress.reset()
        sessions.removeAll()
        saveSessions()
    }
}
