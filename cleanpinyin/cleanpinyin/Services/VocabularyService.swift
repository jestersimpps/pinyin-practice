import Foundation

class VocabularyService: ObservableObject, VocabularyServiceProtocol {
    static let shared = VocabularyService()

    @Published var allVocabulary: [VocabularyItem] = []
    @Published var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    @Published var vocabularyByChapter: [String: [VocabularyItem]] = [:]
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false

    private let fileLoader = VocabularyFileLoader()
    private let customLoader = CustomVocabularyLoader()
    private let chapterOrganizer = ChapterOrganizer()

    private init() {
        loadVocabulary()
    }

    func loadVocabulary() {
        isLoading = true

        var allItems: [VocabularyItem] = []
        chapters.removeAll()
        vocabularyByChapter.removeAll()

        for level in 1...6 {
            switch fileLoader.loadVocabularyFromJSON(level: level) {
            case .success(let items):
                let sortedItems = items.sorted { $0.frequency < $1.frequency }
                vocabularyByLevel[level] = sortedItems
                allItems.append(contentsOf: sortedItems)

                let (levelChapters, levelVocabularyByChapter) = chapterOrganizer.organizeIntoChapters(items: sortedItems, level: level)
                chapters.append(contentsOf: levelChapters)
                vocabularyByChapter.merge(levelVocabularyByChapter) { _, new in new }

            case .failure(let error):
                print("Failed to load vocabulary for level \(level): \(error)")
            }
        }

        let customData = customLoader.loadCustomVocabulary()
        chapters.append(contentsOf: customData.chapters)
        vocabularyByChapter.merge(customData.vocabularyByChapter) { _, new in new }
        allItems.append(contentsOf: customData.allItems)

        allVocabulary = allItems
        isLoading = false
    }

    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        levels.sorted().flatMap { vocabularyByLevel[$0] ?? [] }
    }

    func vocabularyForLevel(_ level: Int) -> [VocabularyItem] {
        vocabularyByLevel[level] ?? []
    }

    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        chapterIds.sorted().flatMap { vocabularyByChapter[$0] ?? [] }
    }

    func reviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem] {
        allVocabulary.filter { incorrectWordIds.contains($0.id) }
    }

    func chaptersForLevel(_ level: Int) -> [Chapter] {
        chapters.filter { $0.hskLevel == level }
    }
}
