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
    
    mutating func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool {
        var wasJustCompleted = false
        
        
        if chapterProgress[chapterId] == nil {
            chapterProgress[chapterId] = ChapterProgress(
                chapterId: chapterId,
                wordsCompleted: [],
                totalWords: totalWords,
                isCompleted: false,
                completionDate: nil
            )
        }
        
        let wasCompleted = chapterProgress[chapterId]?.isCompleted ?? false
        chapterProgress[chapterId]?.markWordCompleted(wordId)
        let isNowCompleted = chapterProgress[chapterId]?.isCompleted ?? false
        
        
        wasJustCompleted = !wasCompleted && isNowCompleted
        
        return wasJustCompleted
    }
    
    func isChapterUnlocked(level: Int, chapter: Int) -> Bool {
        if ChapterCurriculum.reviewChapters.contains(chapter) { return false }
        
        if chapter == 1 { return true }
        if chapter == 15 { return true }
        if chapter == 29 { return true }
        if chapter == 43 { return true }
        if chapter == 57 { return true }
        if chapter == 69 { return true }
        
        var previousChapter = chapter - 1
        while ChapterCurriculum.reviewChapters.contains(previousChapter) && previousChapter > 0 {
            previousChapter -= 1
        }
        
        let previousChapterId = "chapter\(previousChapter)"
        
        
        if let previousProgress = chapterProgress[previousChapterId] {
            let percentage = previousProgress.completionPercentage
            let isUnlocked = percentage >= 80.0
            
            
            return isUnlocked
        }
        
        
        return false
    }
}