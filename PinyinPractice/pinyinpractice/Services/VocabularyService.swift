import Foundation

class VocabularyService: ObservableObject {
    static let shared = VocabularyService()
    
    @Published var allVocabulary: [VocabularyItem] = []
    @Published var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    @Published var vocabularyByChapter: [String: [VocabularyItem]] = [:]
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    
    private init() {
        loadVocabulary()
    }
    
    func loadVocabulary() {
        isLoading = true
        
        var allItems: [VocabularyItem] = []
        chapters.removeAll()
        vocabularyByChapter.removeAll()
        
        for level in 1...6 {
            if let items = loadVocabularyFromJSON(level: level) {
                // Sort by frequency for chapter assignment
                let sortedItems = items.sorted { $0.frequency < $1.frequency }
                vocabularyByLevel[level] = sortedItems
                allItems.append(contentsOf: sortedItems)
                
                // Organize into chapters
                organizeIntoChapters(items: sortedItems, level: level)
            }
        }
        
        allVocabulary = allItems
        isLoading = false
    }
    
    private func organizeIntoChapters(items: [VocabularyItem], level: Int) {
        // Check if items have cp (chapter progression) values
        let itemsWithChapters = items.filter { $0.cp != nil }
        
        if !itemsWithChapters.isEmpty {
            // Use curriculum-based chapter organization
            organizeVocabularyByCurriculum(items: items, level: level)
        } else {
            // Fall back to frequency-based organization
            organizeVocabularyByFrequency(items: items, level: level)
        }
    }
    
    private func organizeVocabularyByCurriculum(items: [VocabularyItem], level: Int) {
        // Group items by their cp (chapter progression) value
        let groupedByChapter = Dictionary(grouping: items) { item in
            item.cp ?? 0
        }
        
        // Create chapters based on curriculum
        for (chapterNum, chapterItems) in groupedByChapter where chapterNum > 0 {
            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNum)
            
            // Only process if this chapter belongs to the current HSK level
            if chapterInfo.hskLevel == level {
                let chapterId = "chapter\(chapterNum)"
                vocabularyByChapter[chapterId] = chapterItems
                
                let chapter = Chapter(
                    id: chapterId,
                    hskLevel: level,
                    chapterNumber: chapterNum,
                    title: chapterInfo.title,
                    description: chapterInfo.description,
                    wordCount: chapterItems.count,
                    isUnlocked: chapterNum == 1 || isChapterUnlocked(chapterNum)
                )
                
                chapters.append(chapter)
            }
        }
        
        // Sort chapters by number
        chapters.sort { $0.chapterNumber < $1.chapterNumber }
    }
    
    private func organizeVocabularyByFrequency(items: [VocabularyItem], level: Int) {
        // Original frequency-based organization
        let sortedItems = items.sorted { $0.frequency < $1.frequency }
        
        let chaptersCount = ChapterConfiguration.chaptersPerLevel[level] ?? 10
        let wordsPerChapter = items.count / chaptersCount
        let remainder = items.count % chaptersCount
        
        var currentIndex = 0
        
        for chapterNum in 1...chaptersCount {
            // Distribute remainder words across first chapters
            let chapterSize = wordsPerChapter + (chapterNum <= remainder ? 1 : 0)
            let endIndex = min(currentIndex + chapterSize, items.count)
            
            let chapterWords = Array(sortedItems[currentIndex..<endIndex])
            let chapterId = "hsk\(level)_chapter\(chapterNum)"
            
            vocabularyByChapter[chapterId] = chapterWords
            
            // Create chapter metadata
            let chapter = Chapter(
                id: chapterId,
                hskLevel: level,
                chapterNumber: chapterNum,
                title: ChapterConfiguration.getChapterTitle(level: level, chapter: chapterNum),
                description: "Study \(chapterWords.count) essential HSK\(level) words",
                wordCount: chapterWords.count,
                isUnlocked: chapterNum == 1 // First chapter always unlocked
            )
            
            chapters.append(chapter)
            currentIndex = endIndex
        }
    }
    
    private func isChapterUnlocked(_ chapterNum: Int) -> Bool {
        // Check if previous chapter is 80% complete
        // This will be implemented with UserProgressService
        return true // For now, all chapters are unlocked
    }
    
    private func loadVocabularyFromJSON(level: Int) -> [VocabularyItem]? {
        guard let url = Bundle.main.url(forResource: "\(level).min", withExtension: "json") else {
            print("Could not find \(level).min.json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)
            return items
        } catch {
            print("Error loading vocabulary for level \(level): \(error)")
            return nil
        }
    }
    
    func getVocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        return levels.flatMap { level in
            vocabularyByLevel[level] ?? []
        }
    }
    
    func getReviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem] {
        return allVocabulary.filter { incorrectWordIds.contains($0.id) }
    }
    
    func getAllVocabulary() -> [VocabularyItem] {
        return allVocabulary
    }
    
    func getVocabularyForLevel(_ level: Int) -> [VocabularyItem] {
        return vocabularyByLevel[level] ?? []
    }
    
    func getVocabularyForChapter(_ chapterId: String) -> [VocabularyItem] {
        return vocabularyByChapter[chapterId] ?? []
    }
    
    func getVocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        return chapterIds.flatMap { chapterId in
            vocabularyByChapter[chapterId] ?? []
        }
    }
    
    func getChaptersForLevel(_ level: Int) -> [Chapter] {
        return chapters.filter { $0.hskLevel == level }
    }
    
    func getChapter(byId chapterId: String) -> Chapter? {
        return chapters.first { $0.id == chapterId }
    }
}