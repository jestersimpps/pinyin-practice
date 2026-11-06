import Foundation

struct SetTheme: Codable, Equatable {
    let word: String
    let title: String
    let icon: String
}

final class ChapterOrganizer {
    typealias OrganizedChapters = (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]])

    static let wordsPerSet = 40
    static let fallbackSetIcon = "square.stack.3d.up"

    private let setThemes: [Int: [SetTheme]]

    init(setThemes: [Int: [SetTheme]] = [:]) {
        self.setThemes = setThemes
    }

    // Titles and icons for frequency sets, keyed by HSK level, one entry per set in order
    static func loadSetThemes(from bundle: Bundle = .main) -> [Int: [SetTheme]] {
        guard let url = bundle.url(forResource: "set-themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [SetTheme]].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in Int(key).map { ($0, value) } })
    }

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

        let sortedItems = items.sorted { ($0.frequency, $0.id) < ($1.frequency, $1.id) }
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
            let theme = setThemes[level].flatMap { themes in
                themes.indices.contains(setNumber - 1) ? themes[setNumber - 1] : nil
            }.flatMap { theme in
                setItems.contains { $0.id == theme.word } ? theme : nil
            }

            chapters.append(Chapter(
                id: id,
                kind: .frequencySet,
                hskLevel: level,
                chapterNumber: setNumber,
                title: theme?.title ?? "Words \(start + 1)–\(start + size)",
                description: "Words \(start + 1)–\(start + size), most common first",
                wordCount: size,
                icon: theme?.icon ?? Self.fallbackSetIcon
            ))
            start += size
        }
        return (chapters, vocabularyByChapter)
    }
}
