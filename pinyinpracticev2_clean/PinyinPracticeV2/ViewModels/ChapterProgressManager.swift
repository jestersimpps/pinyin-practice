import Foundation

protocol ChapterProgressManaging {
    func updateProgress(for word: VocabularyItem, in chapterId: String, isCorrect: Bool) -> CompletedChapterInfo?
    func checkForChapterCompletion(chapterId: String, wordsCompleted: Int, availableWords: Int) -> CompletedChapterInfo?
}

struct CompletedChapterInfo {
    let chapter: Chapter
    let progress: ChapterProgress
}

final class ChapterProgressManager: ChapterProgressManaging {
    private let vocabularyService: VocabularyProviding
    private let progressTracker: ProgressTracking
    
    init(vocabularyService: VocabularyProviding, progressTracker: ProgressTracking) {
        self.vocabularyService = vocabularyService
        self.progressTracker = progressTracker
    }
    
    func updateProgress(for word: VocabularyItem, in chapterId: String, isCorrect: Bool) -> CompletedChapterInfo? {
        guard let chapterWords = findChapterContainingWord(word) else { return nil }
        
        progressTracker.updateChapterProgress(
            chapterId: chapterWords.chapterId,
            wordId: word.id,
            isCorrect: isCorrect
        )
        
        let progressV2 = progressTracker.getChapterProgressV2(chapterId: chapterWords.chapterId)
        let wasCompleted = progressV2?.completionPercentage ?? 0 >= Constants.Chapter.fullCompletionThreshold
        
        if wasCompleted {
            return createCompletedChapterInfo(chapterId: chapterWords.chapterId, words: chapterWords.words)
        }
        
        return nil
    }
    
    func checkForChapterCompletion(chapterId: String, wordsCompleted: Int, availableWords: Int) -> CompletedChapterInfo? {
        guard wordsCompleted >= availableWords else { return nil }
        
        let progressV2 = progressTracker.getChapterProgressV2(chapterId: chapterId)
        let progress = ChapterProgress(
            chapterId: chapterId,
            wordsCompleted: progressV2?.correctWords ?? [],
            totalWords: progressV2?.totalWords ?? availableWords,
            isCompleted: (progressV2?.completionPercentage ?? 0) >= Constants.Chapter.fullCompletionThreshold,
            completionDate: (progressV2?.completionPercentage ?? 0) >= Constants.Chapter.fullCompletionThreshold ? Date() : nil
        )
        
        let identifier = ChapterIdentifier(chapterId)
        guard let chapterNumber = identifier.globalChapterNumber else { return nil }
        
        let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
        
        let chapter = Chapter(
            id: chapterId,
            hskLevel: chapterInfo.hskLevel,
            chapterNumber: chapterNumber,
            title: chapterInfo.title,
            description: chapterInfo.description,
            wordCount: availableWords,
            isUnlocked: true,
            icon: chapterInfo.icon
        )
        
        return CompletedChapterInfo(chapter: chapter, progress: progress)
    }
    
    private func findChapterContainingWord(_ word: VocabularyItem) -> (chapterId: String, words: [VocabularyItem])? {
        for (chapterId, words) in vocabularyService.vocabularyByChapter {
            if words.contains(where: { $0.id == word.id }) {
                return (chapterId, words)
            }
        }
        return nil
    }
    
    private func createCompletedChapterInfo(chapterId: String, words: [VocabularyItem]) -> CompletedChapterInfo? {
        let identifier = ChapterIdentifier(chapterId)
        guard let chapterNumber = identifier.globalChapterNumber else { return nil }
        
        let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
        
        let chapter = Chapter(
            id: chapterId,
            hskLevel: chapterInfo.hskLevel,
            chapterNumber: chapterNumber,
            title: chapterInfo.title,
            description: chapterInfo.description,
            wordCount: words.count,
            isUnlocked: true,
            icon: chapterInfo.icon
        )
        
        if let progressV2 = progressTracker.getChapterProgressV2(chapterId: chapterId) {
            let progress = ChapterProgress(
                chapterId: chapterId,
                wordsCompleted: progressV2.correctWords,
                totalWords: progressV2.totalWords,
                isCompleted: progressV2.completionPercentage >= Constants.Chapter.fullCompletionThreshold,
                completionDate: progressV2.completionPercentage >= Constants.Chapter.fullCompletionThreshold ? Date() : nil
            )
            
            return CompletedChapterInfo(chapter: chapter, progress: progress)
        }
        
        return nil
    }
}