import Foundation

protocol UserProgressServiceProtocol: AnyObject {
    var progress: UserProgress { get set }
    var settings: PracticeSettings { get set }
    var sessions: [PracticeSession] { get }
    
    func recordAnswer(wordId: String, isCorrect: Bool, chapterId: String?, chapterSize: Int)
    func recordAnswer(for word: VocabularyItem, isCorrect: Bool)
    func recordSkip(wordId: String, chapterId: String?)
    func recordSessionCompletion(correctAnswers: Int, totalQuestions: Int, levels: Set<Int>)
    func resetProgress()
    func startNewSession() -> Date
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int, totalAttempts: Int)
    func getAccuracyForLastNSessions(_ n: Int) -> Double?
    func getTotalPracticeTime() -> TimeInterval
    func getStreakDays() -> Int
    func updateSettings(_ settings: PracticeSettings)
    func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool
    func getChapterProgress(chapterId: String) -> ChapterProgress?
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool
}