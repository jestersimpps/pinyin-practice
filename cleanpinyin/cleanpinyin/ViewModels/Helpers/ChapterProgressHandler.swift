import Foundation

class ChapterProgressHandler {
    func parseChapterNumber(from chapterId: String) -> Int? {
        if chapterId.hasPrefix("chapter") && !chapterId.contains("_") {
            // Format: "chapter1", "chapter15", etc.
            return Int(chapterId.replacingOccurrences(of: "chapter", with: ""))
        } else if chapterId.contains("chapter_") {
            // Legacy format: "chapter_1", "chapter_15", etc.
            return Int(chapterId.replacingOccurrences(of: "chapter_", with: ""))
        } else if chapterId.contains("hsk") && chapterId.contains("_chapter") {
            // Format: "hsk1_chapter1", "hsk2_chapter1", etc.
            let components = chapterId.components(separatedBy: "_chapter")
            if components.count == 2 {
                let levelStr = components[0].replacingOccurrences(of: "hsk", with: "")
                if let level = Int(levelStr),
                   let localChapterNum = Int(components[1]) {
                    // Convert local chapter number to global chapter number
                    switch level {
                    case 1: return localChapterNum
                    case 2: return 14 + localChapterNum
                    case 3: return 28 + localChapterNum
                    case 4: return 42 + localChapterNum
                    case 5: return 56 + localChapterNum
                    case 6: return 68 + localChapterNum
                    default: return nil
                    }
                }
            }
        }
        return nil
    }
    
    func createChapter(
        chapterId: String,
        chapterNumber: Int,
        wordCount: Int
    ) -> Chapter {
        let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
        
        return Chapter(
            id: chapterId,
            hskLevel: chapterInfo.hskLevel,
            chapterNumber: chapterNumber,
            title: chapterInfo.title,
            description: chapterInfo.description,
            wordCount: wordCount,
            isUnlocked: true,
            icon: chapterInfo.icon
        )
    }
    
    func handleChapterProgress(
        for word: VocabularyItem,
        vocabularyByChapter: [String: [VocabularyItem]],
        progressService: UserProgressServiceProtocol
    ) -> (chapter: Chapter?, progress: ChapterProgress?, wasCompleted: Bool) {
        for (chapterId, words) in vocabularyByChapter {
            if words.contains(where: { $0.id == word.id }) {
                // Record the attempt for chapter stats
                if let chapterProgress = progressService.getChapterProgress(chapterId: chapterId) {
                    var updatedProgress = chapterProgress
                    updatedProgress.recordAttempt(isCorrect: true, practiceTime: 0)
                    progressService.progress.chapterProgress[chapterId] = updatedProgress
                }
                
                let wasCompleted = progressService.updateChapterProgress(
                    chapterId: chapterId,
                    wordId: word.id,
                    totalWords: words.count
                )
                
                if wasCompleted {
                    if let chapterNumber = parseChapterNumber(from: chapterId) {
                        let chapter = createChapter(
                            chapterId: chapterId,
                            chapterNumber: chapterNumber,
                            wordCount: words.count
                        )
                        let progress = progressService.progress.chapterProgress[chapterId]
                        return (chapter, progress, true)
                    }
                }
                
                break
            }
        }
        
        return (nil, nil, false)
    }
}