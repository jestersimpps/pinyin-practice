import Foundation

class VocabularyService: ObservableObject {
    static let shared = VocabularyService()
    
    @Published var allVocabulary: [VocabularyItem] = []
    @Published var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    @Published var isLoading = false
    
    private init() {
        loadVocabulary()
    }
    
    func loadVocabulary() {
        isLoading = true
        
        var allItems: [VocabularyItem] = []
        
        for level in 1...6 {
            if let items = loadVocabularyFromJSON(level: level) {
                vocabularyByLevel[level] = items
                allItems.append(contentsOf: items)
            }
        }
        
        allVocabulary = allItems
        isLoading = false
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
}