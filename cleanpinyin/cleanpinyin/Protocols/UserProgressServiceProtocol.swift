import Foundation

protocol UserProgressServiceProtocol: AnyObject {
    var progress: UserProgress { get set }
    var settings: PracticeSettings { get set }
    var sessions: [PracticeSession] { get }

    func recordAnswer(for word: VocabularyItem, isCorrect: Bool)
    func resetProgress()
    func endSession(startTime: Date, wordsStudied: Int, correctAnswers: Int, totalAttempts: Int)
    func recordChapterAttempt(chapterId: String, totalWords: Int, isCorrect: Bool, practiceTime: TimeInterval)
    @discardableResult
    func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool
    func getChapterProgress(chapterId: String) -> ChapterProgress?
    func isChapterUnlocked(chapterId: String) -> Bool
}
