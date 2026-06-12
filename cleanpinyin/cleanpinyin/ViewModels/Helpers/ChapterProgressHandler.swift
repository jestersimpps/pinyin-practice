import Foundation

class ChapterProgressHandler {
    private var attemptTimerStart = Date()

    func resetTimer() {
        attemptTimerStart = Date()
    }

    // Records the attempt against the word's chapter and returns the chapter id when this attempt just completed it
    func recordAttempt(
        for word: VocabularyItem,
        isCorrect: Bool,
        activeChapters: Set<String>,
        vocabularyByChapter: [String: [VocabularyItem]],
        progressService: UserProgressServiceProtocol
    ) -> String? {
        guard let chapterId = chapterId(for: word, in: activeChapters, vocabularyByChapter: vocabularyByChapter),
              let totalWords = vocabularyByChapter[chapterId]?.count else {
            return nil
        }

        let practiceTime = Date().timeIntervalSince(attemptTimerStart)
        resetTimer()

        progressService.recordChapterAttempt(
            chapterId: chapterId,
            totalWords: totalWords,
            isCorrect: isCorrect,
            practiceTime: practiceTime
        )

        guard isCorrect else { return nil }

        let wasJustCompleted = progressService.updateChapterProgress(
            chapterId: chapterId,
            wordId: word.id,
            totalWords: totalWords
        )
        return wasJustCompleted ? chapterId : nil
    }

    private func chapterId(
        for word: VocabularyItem,
        in activeChapters: Set<String>,
        vocabularyByChapter: [String: [VocabularyItem]]
    ) -> String? {
        activeChapters.sorted().first { chapterId in
            vocabularyByChapter[chapterId]?.contains { $0.id == word.id } ?? false
        }
    }
}
