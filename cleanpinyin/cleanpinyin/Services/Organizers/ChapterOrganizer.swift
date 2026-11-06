import Foundation

final class ChapterOrganizer {
    typealias OrganizedChapters = (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]])

    static let wordsPerSet = 40

    func organizeIntoChapters(items: [VocabularyItem], level: Int) -> OrganizedChapters {
        if items.contains(where: { $0.cp != nil }) {
            return organizeByCurriculum(items: items, level: level)
        }
        return organizeIntoFrequencySets(items: items, level: level)
    }

    private func organizeByCurriculum(items: [VocabularyItem], level: Int) -> OrganizedChapters {
        let grouped = Dictionary(grouping: items.filter { $0.cp != nil }) { $0.cp ?? 0 }
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]

        let chapters = grouped.keys.sorted().map { chapterNumber -> Chapter in
            let info = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
            let id = "chapter\(chapterNumber)"
            let chapterItems = grouped[chapterNumber] ?? []
            vocabularyByChapter[id] = chapterItems

            return Chapter(
                id: id,
                kind: .curriculum,
                hskLevel: level,
                chapterNumber: chapterNumber,
                title: info.title,
                description: info.description,
                wordCount: chapterItems.count,
                icon: info.icon
            )
        }
        return (chapters, vocabularyByChapter)
    }

    private func organizeIntoFrequencySets(items: [VocabularyItem], level: Int) -> OrganizedChapters {
        guard !items.isEmpty else { return ([], [:]) }

        let sortedItems = items.sorted { $0.frequency < $1.frequency }
        let setCount = Int((Double(sortedItems.count) / Double(Self.wordsPerSet)).rounded(.up))
        let baseSize = sortedItems.count / setCount
        let remainder = sortedItems.count % setCount

        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        var start = 0

        for setNumber in 1...setCount {
            let size = baseSize + (setNumber <= remainder ? 1 : 0)
            let setItems = Array(sortedItems[start..<(start + size)])
            let id = "hsk\(level)_set\(setNumber)"
            vocabularyByChapter[id] = setItems

            chapters.append(Chapter(
                id: id,
                kind: .frequencySet,
                hskLevel: level,
                chapterNumber: setNumber,
                title: "Set \(setNumber)",
                description: "Words \(start + 1)–\(start + size), most common first",
                wordCount: size,
                icon: "square.stack.3d.up"
            ))
            start += size
        }
        return (chapters, vocabularyByChapter)
    }
}
