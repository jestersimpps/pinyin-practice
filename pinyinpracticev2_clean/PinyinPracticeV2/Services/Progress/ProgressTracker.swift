import Foundation

protocol ProgressTracking {
    var currentStreak: Int { get }
    var bestStreak: Int { get }
    var accuracy: Double { get }
    var formattedAccuracy: String { get }
    var incorrectWords: Set<String> { get }
    var seenWords: Set<String> { get }
    
    func recordAnswer(for word: VocabularyItem, isCorrect: Bool)
    func recordWordDifficulty(wordId: String, isCorrect: Bool, responseTime: TimeInterval)
    func updateChapterProgress(chapterId: String, wordId: String, isCorrect: Bool)
    func getChapterProgressV2(chapterId: String) -> ChapterProgressV2?
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool
    func reset()
}

final class ProgressTracker: ProgressTracking {
    private let storage: StorageService
    private let progressKey = "UserProgress"
    private var progress: UserProgress
    
    var currentStreak: Int { progress.currentStreak }
    var bestStreak: Int { progress.bestStreak }
    var accuracy: Double { progress.accuracy }
    var formattedAccuracy: String { progress.formattedAccuracy }
    var incorrectWords: Set<String> { progress.incorrectWords }
    var seenWords: Set<String> { progress.seenWords }
    
    init(storage: StorageService) {
        self.storage = storage
        
        if let loadedProgress = try? storage.load(UserProgress.self, forKey: progressKey) {
            self.progress = loadedProgress
        } else {
            self.progress = UserProgress()
        }
        
        migrateChapterProgress()
    }
    
    private func saveProgress() {
        try? storage.save(progress, forKey: progressKey)
    }
    
    private func migrateChapterProgress() {
        progress.chapterProgressV2.removeAll()
        saveProgress()
    }
    
    func recordAnswer(for word: VocabularyItem, isCorrect: Bool) {
        progress.recordAnswer(wordId: word.id, isCorrect: isCorrect)
        saveProgress()
    }
    
    func recordWordDifficulty(wordId: String, isCorrect: Bool, responseTime: TimeInterval) {
        if progress.wordDifficulties[wordId] == nil {
            progress.wordDifficulties[wordId] = WordDifficulty(wordId: wordId)
        }
        progress.wordDifficulties[wordId]?.recordAttempt(isCorrect: isCorrect, responseTime: responseTime)
        saveProgress()
    }
    
    func updateChapterProgress(chapterId: String, wordId: String, isCorrect: Bool) {
        progress.updateChapterProgressV2(chapterId: chapterId, wordId: wordId, isCorrect: isCorrect)
        saveProgress()
    }
    
    func getChapterProgressV2(chapterId: String) -> ChapterProgressV2? {
        return progress.getChapterProgressV2(chapterId: chapterId)
    }
    
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool {
        return progress.isChapterUnlocked(level: level, chapter: chapter)
    }
    
    func reset() {
        progress.reset()
        saveProgress()
    }
}