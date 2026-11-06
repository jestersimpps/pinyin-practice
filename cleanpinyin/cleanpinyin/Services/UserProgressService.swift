import Foundation

final class UserProgressService: ObservableObject, UserProgressServiceProtocol {
    static let shared = UserProgressService()

    @Published var progress: UserProgress {
        didSet { save(progress, forKey: Keys.progress) }
    }

    @Published var settings: PracticeSettings {
        didSet { save(settings, forKey: Keys.settings) }
    }

    @Published private(set) var sessions: [PracticeSession] {
        didSet { save(sessions, forKey: Keys.sessions) }
    }

    private enum Keys {
        static let progress = "UserProgress"
        static let settings = "PracticeSettings"
        static let sessions = "PracticeSessions"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        progress = Self.load(UserProgress.self, forKey: Keys.progress, from: defaults) ?? UserProgress()
        settings = Self.load(PracticeSettings.self, forKey: Keys.settings, from: defaults) ?? PracticeSettings()
        sessions = Self.load([PracticeSession].self, forKey: Keys.sessions, from: defaults) ?? []
    }

    // MARK: - Persistence
    private static func load<T: Decodable>(_ type: T.Type, forKey key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let encoded = try? JSONEncoder().encode(value) else { return }
        defaults.set(encoded, forKey: key)
    }

    // MARK: - Answers
    func recordAnswer(for word: VocabularyItem, isCorrect: Bool, rating: ReviewRating?) {
        progress.recordAnswer(wordId: word.id, isCorrect: isCorrect, rating: rating)
    }

    // MARK: - Sessions
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int, totalAttempts: Int, hskLevels: [Int]) {
        let accuracy = totalAttempts > 0 ? Double(correctAnswers) / Double(totalAttempts) * 100 : 0

        sessions.append(PracticeSession(
            date: Date(),
            duration: Date().timeIntervalSince(startTime),
            wordsStudied: wordsStudied,
            correctAnswers: correctAnswers,
            accuracy: accuracy,
            hskLevels: hskLevels
        ))
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

    func isChapterUnlocked(_ chapter: Chapter, vocabulary: VocabularyServiceProtocol = VocabularyService.shared) -> Bool {
        progress.isChapterUnlocked(chapter, levelChapters: vocabulary.chaptersForLevel(chapter.hskLevel))
    }

    func cleanupSelectedChapters(vocabulary: VocabularyServiceProtocol = VocabularyService.shared) {
        let valid = settings.selectedChapters.filter { id in
            guard let chapter = vocabulary.chapter(withId: id) else { return false }
            return isChapterUnlocked(chapter, vocabulary: vocabulary)
        }
        if valid != settings.selectedChapters {
            settings.selectedChapters = valid
        }
    }

    // Switches the vocabulary before publishing the setting, so screens redraw with the new list
    func selectSyllabus(_ syllabus: HSKSyllabus, vocabulary: VocabularyService = .shared) {
        vocabulary.select(syllabus)
        settings.syllabus = syllabus
        cleanupSelectedChapters(vocabulary: vocabulary)
    }

    // MARK: - Progress Queries
    var hasIncorrectWords: Bool {
        !progress.incorrectWords.isEmpty
    }

    var wordsLearnedCount: Int {
        progress.learnedWords.count
    }

    var dueCount: Int {
        progress.dueWordIds().count
    }

    var currentDayStreak: Int {
        progress.currentDayStreak()
    }

    func getWordsLearnedForLevel(_ level: Int, vocabulary: VocabularyServiceProtocol = VocabularyService.shared) -> Int {
        vocabulary.vocabularyForLevel(level).filter { progress.learnedWords.contains($0.id) }.count
    }

    func resetProgress() {
        progress.reset()
        sessions.removeAll()
    }
}
