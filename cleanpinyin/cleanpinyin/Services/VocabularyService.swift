import Foundation

final class VocabularyService: ObservableObject, VocabularyServiceProtocol {
    static let shared = VocabularyService()

    private struct Library {
        var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        var chapters: [Chapter] = []
    }

    @Published private(set) var syllabus: HSKSyllabus
    private(set) var allVocabulary: [VocabularyItem] = []
    private var libraries: [HSKSyllabus: Library] = [:]

    private let fileLoader = VocabularyFileLoader()
    private let customLoader = CustomVocabularyLoader()
    private let chapterOrganizer = ChapterOrganizer(setThemes: ChapterOrganizer.loadSetThemes())

    init(syllabus: HSKSyllabus = .hsk3) {
        self.syllabus = syllabus
        loadVocabulary()
    }

    func select(_ syllabus: HSKSyllabus) {
        guard syllabus != self.syllabus else { return }
        self.syllabus = syllabus
    }

    private var library: Library {
        libraries[syllabus] ?? Library()
    }

    var vocabularyByChapter: [String: [VocabularyItem]] {
        library.vocabularyByChapter
    }

    var chapters: [Chapter] {
        library.chapters
    }

    private func loadVocabulary() {
        let bank: [VocabularyItem]
        switch fileLoader.loadWordBank() {
        case .success(let items):
            bank = items.sorted { $0.frequency < $1.frequency }
        case .failure(let error):
            assertionFailure("Failed to load the word bank: \(error)")
            bank = []
        }

        let customData = customLoader.loadCustomVocabulary()
        for syllabus in HSKSyllabus.allCases {
            var library = makeLibrary(from: bank, syllabus: syllabus)
            library.chapters.append(contentsOf: customData.chapters)
            library.vocabularyByChapter.merge(customData.vocabularyByChapter) { _, new in new }
            libraries[syllabus] = library
        }

        allVocabulary = Self.uniqued(bank + customData.allItems)
    }

    private func makeLibrary(from bank: [VocabularyItem], syllabus: HSKSyllabus) -> Library {
        var library = Library()
        let byLevel = Dictionary(grouping: bank) { $0.level(in: syllabus) }

        for level in PracticeSettings.hskLevels {
            let items = byLevel[level] ?? []
            library.vocabularyByLevel[level] = items

            let organized = chapterOrganizer.organizeIntoChapters(items: items, level: level, syllabus: syllabus)
            library.chapters.append(contentsOf: organized.chapters)
            library.vocabularyByChapter.merge(organized.vocabularyByChapter) { _, new in new }
        }
        return library
    }

    func wordCount(in syllabus: HSKSyllabus) -> Int {
        PracticeSettings.hskLevels.reduce(0) { $0 + (libraries[syllabus]?.vocabularyByLevel[$1]?.count ?? 0) }
    }

    var hskWordCount: Int {
        wordCount(in: syllabus)
    }

    var hasCustomChapters: Bool {
        chapters.contains { $0.kind == .custom }
    }

    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        Self.uniqued(levels.sorted().flatMap { library.vocabularyByLevel[$0] ?? [] })
    }

    func vocabularyForLevel(_ level: Int) -> [VocabularyItem] {
        library.vocabularyByLevel[level] ?? []
    }

    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        Self.uniqued(chapterIds.sorted().flatMap { vocabularyByChapter[$0] ?? [] })
    }

    // Keeps the order of ids and drops unknown or repeated ones; covers both word lists
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
