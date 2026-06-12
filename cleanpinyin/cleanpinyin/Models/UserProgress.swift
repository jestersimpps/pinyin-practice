import Foundation

struct UserProgress: Codable {
    var wordsSeenCount: Int = 0
    var correctAnswers: Int = 0
    var totalAttempts: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var incorrectWords: Set<String> = []
    var seenWords: Set<String> = []
    var lastSeenWordId: String?
    var lastPracticeDate: Date?
    var chapterProgress: [String: ChapterProgress] = [:]
    
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAttempts) * 100
    }
    
    var formattedAccuracy: String {
        return String(format: "%.0f%%", accuracy)
    }
    
    mutating func recordAnswer(wordId: String, isCorrect: Bool) {
        totalAttempts += 1
        seenWords.insert(wordId)
        lastSeenWordId = wordId
        lastPracticeDate = Date()
        
        if isCorrect {
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            incorrectWords.remove(wordId)
        } else {
            currentStreak = 0
            incorrectWords.insert(wordId)
        }
        
        wordsSeenCount = seenWords.count
    }
    
    mutating func reset() {
        wordsSeenCount = 0
        correctAnswers = 0
        totalAttempts = 0
        currentStreak = 0
        bestStreak = 0
        incorrectWords.removeAll()
        seenWords.removeAll()
        lastSeenWordId = nil
        lastPracticeDate = nil
        chapterProgress.removeAll()
    }
    
    func getChapterProgress(chapterId: String) -> ChapterProgress? {
        return chapterProgress[chapterId]
    }
    
    mutating func recordChapterAttempt(chapterId: String, totalWords: Int, isCorrect: Bool, practiceTime: TimeInterval) {
        ensureChapterProgress(chapterId: chapterId, totalWords: totalWords)
        chapterProgress[chapterId]?.recordAttempt(isCorrect: isCorrect, practiceTime: practiceTime)
    }

    mutating func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool {
        ensureChapterProgress(chapterId: chapterId, totalWords: totalWords)

        let wasCompleted = chapterProgress[chapterId]?.isCompleted ?? false
        chapterProgress[chapterId]?.markWordCompleted(wordId)
        let isNowCompleted = chapterProgress[chapterId]?.isCompleted ?? false

        return !wasCompleted && isNowCompleted
    }

    private mutating func ensureChapterProgress(chapterId: String, totalWords: Int) {
        guard chapterProgress[chapterId] == nil else { return }
        chapterProgress[chapterId] = ChapterProgress(
            chapterId: chapterId,
            wordsCompleted: [],
            totalWords: totalWords,
            isCompleted: false,
            completionDate: nil
        )
    }

    func isChapterUnlocked(chapterId: String) -> Bool {
        let identifier = ChapterIdentifier(chapterId)
        if identifier.isCustom { return true }
        guard let chapterNumber = identifier.chapterNumber else { return true }

        if identifier.isCurriculumChapter {
            if ChapterCurriculum.isReviewChapter(chapterNumber) { return false }

            let level = ChapterCurriculum.hskLevel(forChapter: chapterNumber)
            if chapterNumber == ChapterCurriculum.firstChapter(forLevel: level) { return true }

            var previousChapter = chapterNumber - 1
            while ChapterCurriculum.isReviewChapter(previousChapter) && previousChapter > 1 {
                previousChapter -= 1
            }
            return meetsUnlockRequirement(ChapterIdentifier(chapterNumber: previousChapter).value)
        }

        if chapterNumber == 1 { return true }
        guard let level = identifier.hskLevel else { return true }
        return meetsUnlockRequirement(ChapterIdentifier(hskLevel: level, chapterNumber: chapterNumber - 1).value)
    }

    private func meetsUnlockRequirement(_ previousChapterId: String) -> Bool {
        guard let previous = chapterProgress[previousChapterId] else { return false }
        return previous.completionPercentage >= AppConstants.Chapters.unlockRequirement * 100
    }
}