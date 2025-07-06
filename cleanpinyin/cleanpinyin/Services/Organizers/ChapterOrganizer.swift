import Foundation

class ChapterOrganizer {
    func organizeIntoChapters(items: [VocabularyItem], level: Int) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]]) {
        let itemsWithChapters = items.filter { $0.cp != nil }
        
        if !itemsWithChapters.isEmpty {
            return organizeVocabularyByCurriculum(items: items, level: level)
        } else {
            return organizeVocabularyByFrequency(items: items, level: level)
        }
    }
    
    private func organizeVocabularyByCurriculum(items: [VocabularyItem], level: Int) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]]) {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        
        let groupedByChapter = Dictionary(grouping: items) { item in
            item.cp ?? 0
        }
        
        for (chapterNum, chapterItems) in groupedByChapter where chapterNum > 0 {
            if ChapterCurriculum.reviewChapters.contains(chapterNum) {
                continue
            }
            
            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNum)
            
            if chapterInfo.hskLevel == level {
                let chapterId = ChapterIdentifier(chapterNumber: chapterNum).value
                vocabularyByChapter[chapterId] = chapterItems
                
                let chapter = Chapter(
                    id: chapterId,
                    hskLevel: level,
                    chapterNumber: chapterNum,
                    title: chapterInfo.title,
                    description: chapterInfo.description,
                    wordCount: chapterItems.count,
                    isUnlocked: chapterNum == 1 || isChapterUnlocked(chapterNum),
                    icon: chapterInfo.icon
                )
                
                chapters.append(chapter)
            }
        }
        
        chapters.sort { $0.chapterNumber < $1.chapterNumber }
        return (chapters, vocabularyByChapter)
    }
    
    private func organizeVocabularyByFrequency(items: [VocabularyItem], level: Int) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]]) {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        
        let sortedItems = items.sorted { $0.frequency < $1.frequency }
        let chaptersCount = ChapterCurriculum.chaptersForLevel(level)
        let wordsPerChapter = items.count / chaptersCount
        let remainder = items.count % chaptersCount
        
        var currentIndex = 0
        
        for chapterNum in 1...chaptersCount {
            let globalChapterNum = calculateGlobalChapterNumber(level: level, chapterNum: chapterNum)
            let chapterSize = wordsPerChapter + (chapterNum <= remainder ? 1 : 0)
            let endIndex = min(currentIndex + chapterSize, items.count)
            
            let chapterWords = Array(sortedItems[currentIndex..<endIndex])
            let chapterId = ChapterIdentifier(hskLevel: level, chapterNumber: chapterNum).value
            
            vocabularyByChapter[chapterId] = chapterWords
            
            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: globalChapterNum)
            
            let chapter = Chapter(
                id: chapterId,
                hskLevel: level,
                chapterNumber: chapterNum,
                title: chapterInfo.title,
                description: chapterInfo.description,
                wordCount: chapterWords.count,
                isUnlocked: chapterNum == 1,
                icon: chapterInfo.icon
            )
            
            chapters.append(chapter)
            currentIndex = endIndex
        }
        
        return (chapters, vocabularyByChapter)
    }
    
    private func calculateGlobalChapterNumber(level: Int, chapterNum: Int) -> Int {
        switch level {
        case 1: return chapterNum
        case 2: return 14 + chapterNum
        case 3: return 28 + chapterNum
        case 4: return 42 + chapterNum
        case 5: return 56 + chapterNum
        case 6: return 68 + chapterNum
        default: return chapterNum
        }
    }
    
    private func isChapterUnlocked(_ chapterNum: Int) -> Bool {
        return true
    }
}