import Foundation

protocol ChapterOrganizing {
    func organizeIntoChapters(items: [VocabularyItem], level: Int) -> [Chapter]
    func getChapterVocabulary(chapterId: ChapterIdentifier, from vocabulary: [String: [VocabularyItem]]) -> [VocabularyItem]
}

final class ChapterOrganizer: ChapterOrganizing {
    func organizeIntoChapters(items: [VocabularyItem], level: Int) -> [Chapter] {
        let itemsWithChapters = items.filter { $0.cp != nil }
        
        if !itemsWithChapters.isEmpty {
            return organizeVocabularyByCurriculum(items: items, level: level)
        } else {
            return organizeVocabularyByFrequency(items: items, level: level)
        }
    }
    
    func getChapterVocabulary(chapterId: ChapterIdentifier, from vocabulary: [String: [VocabularyItem]]) -> [VocabularyItem] {
        return vocabulary[chapterId.rawValue] ?? []
    }
    
    private func organizeVocabularyByCurriculum(items: [VocabularyItem], level: Int) -> [Chapter] {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        
        let groupedByChapter = Dictionary(grouping: items) { item in
            item.cp ?? 0
        }
        
        for (chapterNum, chapterItems) in groupedByChapter where chapterNum > 0 {
            guard !ChapterCurriculum.reviewChapters.contains(chapterNum) else { continue }
            
            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNum)
            
            guard chapterInfo.hskLevel == level else { continue }
            
            let chapterId = ChapterIdentifier.fromGlobalNumber(chapterNum)
            vocabularyByChapter[chapterId.rawValue] = chapterItems
            
            let chapter = Chapter(
                id: chapterId.rawValue,
                hskLevel: level,
                chapterNumber: chapterNum,
                title: chapterInfo.title,
                description: chapterInfo.description,
                wordCount: chapterItems.count,
                isUnlocked: chapterNum == 1,
                icon: chapterInfo.icon
            )
            
            chapters.append(chapter)
        }
        
        return chapters.sorted { $0.chapterNumber < $1.chapterNumber }
    }
    
    private func organizeVocabularyByFrequency(items: [VocabularyItem], level: Int) -> [Chapter] {
        var chapters: [Chapter] = []
        let sortedItems = items.sorted { $0.frequency < $1.frequency }
        
        guard let chaptersCount = Constants.HSK.chaptersPerLevel[level] else { return [] }
        let wordsPerChapter = items.count / chaptersCount
        let remainder = items.count % chaptersCount
        
        var currentIndex = 0
        
        for chapterNum in 1...chaptersCount {
            guard let offset = Constants.HSK.chapterOffsets[level] else { continue }
            let globalChapterNum = offset + chapterNum
            
            let chapterSize = wordsPerChapter + (chapterNum <= remainder ? 1 : 0)
            let endIndex = min(currentIndex + chapterSize, items.count)
            
            let chapterWords = Array(sortedItems[currentIndex..<endIndex])
            let chapterId = "hsk\(level)_chapter\(chapterNum)"
            
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
        
        return chapters
    }
    
    func createCustomChapters(from items: [VocabularyItem], fileNames: [String]) -> [Chapter] {
        var chapters: [Chapter] = []
        
        for (index, fileName) in fileNames.enumerated() {
            let chapterId = "custom_\(fileName)"
            let chapterTitle = formatChapterTitle(from: fileName)
            
            let customChapter = Chapter(
                id: chapterId,
                hskLevel: Constants.HSK.customLevel,
                chapterNumber: index + 1,
                title: chapterTitle,
                description: "Practice with \(chapterTitle.lowercased()) vocabulary",
                wordCount: items.count,
                isUnlocked: true,
                icon: getCustomChapterIcon(for: index + 1)
            )
            
            chapters.append(customChapter)
        }
        
        return chapters
    }
    
    private func formatChapterTitle(from filename: String) -> String {
        var title = filename
        
        if title.lowercased().hasPrefix("basic-") {
            title = title.replacingOccurrences(of: "basic-", with: "Basic ", options: .caseInsensitive)
            return title
        }
        
        if title.lowercased().hasPrefix("custom") {
            title = String(title.dropFirst(6))
        }
        
        title = title.replacingOccurrences(of: "_", with: " ")
        title = title.replacingOccurrences(of: "-", with: " ")
        
        if let firstChar = title.first, firstChar.isNumber {
            let components = title.split(separator: " ")
            if components.count == 1 && components[0].contains(where: { !$0.isNumber && $0 != "-" }) {
                if let nonNumberIndex = title.firstIndex(where: { !$0.isNumber }) {
                    title = String(title[nonNumberIndex...])
                }
            }
        }
        
        title = title.trimmingCharacters(in: .whitespaces)
        
        return title.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    private func getCustomChapterIcon(for chapterNumber: Int) -> String {
        let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "sparkles", "moon.fill", "sun.max.fill", "cloud.fill"]
        return icons[(chapterNumber - 1) % icons.count]
    }
}