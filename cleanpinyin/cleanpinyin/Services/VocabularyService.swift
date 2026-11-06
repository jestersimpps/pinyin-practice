import Foundation

final class VocabularyService: ObservableObject, VocabularyServiceProtocol {
    static let shared = VocabularyService()

    private(set) var allVocabulary: [VocabularyItem] = []
    private(set) var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    private(set) var vocabularyByChapter: [String: [VocabularyItem]] = [:]
    private(set) var chapters: [Chapter] = []

    private let fileLoader = VocabularyFileLoader()
    private let customLoader = CustomVocabularyLoader()
    private let chapterOrganizer = ChapterOrganizer(setThemes: ChapterOrganizer.loadSetThemes())

    private init() {
        loadVocabulary()
    }

    private func loadVocabulary() {
        var allItems: [VocabularyItem] = []

        for level in PracticeSettings.hskLevels {
            switch fileLoader.loadVocabularyFromJSON(level: level) {
            case .success(let items):
                let sortedItems = items.sorted { $0.frequency < $1.frequency }
                vocabularyByLevel[level] = sortedItems
                allItems.append(contentsOf: sortedItems)

                let organized = chapterOrganizer.organizeIntoChapters(items: sortedItems, level: level)
                chapters.append(contentsOf: organized.chapters)
                vocabularyByChapter.merge(organized.vocabularyByChapter) { _, new in new }

            case .failure(let error):
                assertionFailure("Failed to load vocabulary for level \(level): \(error)")
            }
        }

        let customData = customLoader.loadCustomVocabulary()
        chapters.append(contentsOf: customData.chapters)
        vocabularyByChapter.merge(customData.vocabularyByChapter) { _, new in new }
        allItems.append(contentsOf: customData.allItems)

        allVocabulary = Self.uniqued(allItems)
    }

    var hskWordCount: Int {
        PracticeSettings.hskLevels.reduce(0) { $0 + (vocabularyByLevel[$1]?.count ?? 0) }
    }

    var hasCustomChapters: Bool {
        chapters.contains { $0.kind == .custom }
    }

    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        Self.uniqued(levels.sorted().flatMap { vocabularyByLevel[$0] ?? [] })
    }

    func vocabularyForLevel(_ level: Int) -> [VocabularyItem] {
        vocabularyByLevel[level] ?? []
    }

    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        Self.uniqued(chapterIds.sorted().flatMap { vocabularyByChapter[$0] ?? [] })
    }

    // Keeps the order of ids and drops unknown or repeated ones
    func words(withIds ids: [String]) -> [VocabularyItem] {
        let byId = Dictionary(allVocabulary.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<String>()
        return ids.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return byId[id]
        }
    }

    func chaptersForLevel(_ level: Int) -> [Chapter] {
        chapters.filter { $0.hskLevel == level }
    }

    func chapter(withId id: String) -> Chapter? {
        chapters.first { $0.id == id }
    }

    func nextChapter(after chapter: Chapter) -> Chapter? {
        guard chapter.kind != .custom else { return nil }

        let levelChapters = chaptersForLevel(chapter.hskLevel)
        if let index = levelChapters.firstIndex(of: chapter), index + 1 < levelChapters.count {
            return levelChapters[index + 1]
        }
        return PracticeSettings.hskLevels
            .filter { $0 > chapter.hskLevel }
            .lazy
            .compactMap { self.chaptersForLevel($0).first }
            .first
    }

    private static func uniqued(_ items: [VocabularyItem]) -> [VocabularyItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }
}
