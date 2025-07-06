import Foundation

class VocabularyService: ObservableObject, VocabularyServiceProtocol {
    static let shared = VocabularyService()
    
    @Published var allVocabulary: [VocabularyItem] = []
    @Published var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    @Published var vocabularyByChapter: [String: [VocabularyItem]] = [:]
    @Published var chapters: [Chapter] = []
    @Published var customVocabulary: [VocabularyItem] = []
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
                
                for (chapterId, items) in levelVocabularyByChapter {
                    vocabularyByChapter[chapterId] = items
                }
                
            case .failure(let error):
                print("Failed to load vocabulary for level \(level): \(error)")
            }
        }
        
        let customData = customLoader.loadCustomVocabulary()
        chapters.append(contentsOf: customData.chapters)
        
        for (chapterId, items) in customData.vocabularyByChapter {
            vocabularyByChapter[chapterId] = items
        }
        
        customVocabulary = customData.allItems
        allItems.append(contentsOf: customData.allItems)
        
        allVocabulary = allItems
        isLoading = false
    }
    
    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        return levels.flatMap { level in
            vocabularyByLevel[level] ?? []
        }
    }
    
    func reviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem] {
        return allVocabulary.filter { incorrectWordIds.contains($0.id) }
    }
    
    func allVocabularyItems() -> [VocabularyItem] {
        return allVocabulary
    }
    
    func vocabularyForLevel(_ level: Int) -> [VocabularyItem] {
        return vocabularyByLevel[level] ?? []
    }
    
    func vocabularyForChapter(_ chapterId: String) -> [VocabularyItem] {
        return vocabularyByChapter[chapterId] ?? []
    }
    
    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        return chapterIds.flatMap { chapterId in
            vocabularyByChapter[chapterId] ?? []
        }
    }
    
    func chaptersForLevel(_ level: Int) -> [Chapter] {
        return chapters.filter { chapter in
            chapter.hskLevel == level && !ChapterCurriculum.reviewChapters.contains(chapter.chapterNumber)
        }
    }
    
    func chapter(byId chapterId: String) -> Chapter? {
        return chapters.first { $0.id == chapterId }
    }
    
    func customVocabularyItems() -> [VocabularyItem] {
        return customVocabulary
    }
}