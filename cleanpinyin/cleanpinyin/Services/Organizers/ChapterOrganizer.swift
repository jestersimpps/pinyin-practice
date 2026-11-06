import Foundation

struct SetTheme: Codable, Equatable {
    let word: String
    let title: String
    let icon: String
}

final class ChapterOrganizer {
    typealias OrganizedChapters = (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]])
    typealias SetThemes = [HSKSyllabus: [Int: [SetTheme]]]

    static let wordsPerSet = 40
    static let fallbackSetIcon = "square.stack.3d.up"

    private let setThemes: SetThemes

    init(setThemes: SetThemes = [:]) {
        self.setThemes = setThemes
    }

    // Titles and icons for frequency sets, keyed by word list and HSK level, one entry per set in order
    static func loadSetThemes(from bundle: Bundle = .main) -> SetThemes {
        guard let url = bundle.url(forResource: "set-themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: [SetTheme]]].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: decoded.compactMap { syllabusKey, levels in
            HSKSyllabus(rawValue: syllabusKey).map { syllabus in
                (syllabus, Dictionary(uniqueKeysWithValues: levels.compactMap { key, value in Int(key).map { ($0, value) } }))
            }
        })
    }

    func organizeIntoChapters(items: [VocabularyItem], level: Int, syllabus: HSKSyllabus) -> OrganizedChapters {
        if items.contains(where: { $0.curriculumChapter(in: syllabus) != nil }) {
            return organizeByCurriculum(items: items, level: level, syllabus: syllabus)
        }
        return organizeIntoFrequencySets(items: items, level: level, syllabus: syllabus)
    }

    private func organizeByCurriculum(items: [VocabularyItem], level: Int, syllabus: HSKSyllabus) -> OrganizedChapters {
        let grouped = Dictionary(grouping: items) { $0.curriculumChapter(in: syllabus) }
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]

        let chapters = grouped.keys.compactMap { $0 }.sorted().map { chapterNumber -> Chapter in
            let info = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
            let id = "\(syllabus.chapterIdPrefix)chapter\(chapterNumber)"
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

    private func organizeIntoFrequencySets(items: [VocabularyItem], level: Int, syllabus: HSKSyllabus) -> OrganizedChapters {
        guard !items.isEmpty else { return ([], [:]) }

        let sortedItems = items.sorted { ($0.frequency, $0.id) < ($1.frequency, $1.id) }
        let setCount = Int((Double(sortedItems.count) / Double(Self.wordsPerSet)).rounded(.up))
        let baseSize = sortedItems.count / setCount
        let remainder = sortedItems.count % setCount
        let levelThemes = setThemes[syllabus]?[level] ?? []

        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        var start = 0

        for setNumber in 1...setCount {
            let size = baseSize + (setNumber <= remainder ? 1 : 0)
            let setItems = Array(sortedItems[start..<(start + size)])
            let id = "\(syllabus.chapterIdPrefix)hsk\(level)_set\(setNumber)"
            vocabularyByChapter[id] = setItems
            let theme = levelThemes.indices.contains(setNumber - 1) ? levelThemes[setNumber - 1] : nil
            let matchingTheme = theme.flatMap { theme in setItems.contains { $0.id == theme.word } ? theme : nil }

            chapters.append(Chapter(
                id: id,
                kind: .frequencySet,
                hskLevel: level,
                chapterNumber: setNumber,
                title: matchingTheme?.title ?? "Words \(start + 1)–\(start + size)",
                description: "Words \(start + 1)–\(start + size), most common first",
                wordCount: size,
                icon: matchingTheme?.icon ?? Self.fallbackSetIcon
            ))
            start += size
        }
        return (chapters, vocabularyByChapter)
    }
}
