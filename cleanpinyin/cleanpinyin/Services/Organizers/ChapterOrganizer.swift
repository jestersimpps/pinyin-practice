import Foundation

class ChapterOrganizer {
    func organizeIntoChapters(items: [VocabularyItem], level: Int) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]]) {
        let hasCurriculumChapters = items.contains { $0.cp != nil }

        if hasCurriculumChapters {
            return organizeVocabularyByCurriculum(items: items, level: level)
        } else {
            return organizeVocabularyByFrequency(items: items, level: level)
        }
    }

    private func organizeVocabularyByCurriculum(items: [VocabularyItem], level: Int) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]]) {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]

        let groupedByChapter = Dictionary(grouping: items) { $0.cp ?? 0 }

        for (chapterNumber, chapterItems) in groupedByChapter where chapterNumber > 0 {
            if ChapterCurriculum.isReviewChapter(chapterNumber) {
                continue
            }

            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
            guard chapterInfo.hskLevel == level else { continue }

            let chapterId = ChapterIdentifier(chapterNumber: chapterNumber).value
            vocabularyByChapter[chapterId] = chapterItems

            chapters.append(Chapter(
                id: chapterId,
                hskLevel: level,
                chapterNumber: chapterNumber,
                title: chapterInfo.title,
                description: chapterInfo.description,
                wordCount: chapterItems.count,
                icon: chapterInfo.icon
            ))
        }

        chapters.sort { $0.chapterNumber < $1.chapterNumber }
        return (chapters, vocabularyByChapter)
    }

    private func organizeVocabularyByFrequency(items: [VocabularyItem], level: Int) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]]) {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]

        let sortedItems = items.sorted { $0.frequency < $1.frequency }
        let chaptersCount = ChapterCurriculum.chaptersForLevel(level)
        guard chaptersCount > 0, !items.isEmpty else { return (chapters, vocabularyByChapter) }

        let wordsPerChapter = items.count / chaptersCount
        let remainder = items.count % chaptersCount

        var currentIndex = 0

        for chapterNumber in 1...chaptersCount {
            let globalChapterNumber = ChapterCurriculum.globalChapterNumber(level: level, localChapter: chapterNumber)
            let chapterSize = wordsPerChapter + (chapterNumber <= remainder ? 1 : 0)
            let endIndex = min(currentIndex + chapterSize, items.count)

            let chapterWords = Array(sortedItems[currentIndex..<endIndex])
            let chapterId = ChapterIdentifier(hskLevel: level, chapterNumber: chapterNumber).value

            vocabularyByChapter[chapterId] = chapterWords

            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: globalChapterNumber)

            chapters.append(Chapter(
                id: chapterId,
                hskLevel: level,
                chapterNumber: chapterNumber,
                title: chapterInfo.title,
                description: chapterInfo.description,
                wordCount: chapterWords.count,
                icon: chapterInfo.icon
            ))

            currentIndex = endIndex
        }

        return (chapters, vocabularyByChapter)
    }
}
