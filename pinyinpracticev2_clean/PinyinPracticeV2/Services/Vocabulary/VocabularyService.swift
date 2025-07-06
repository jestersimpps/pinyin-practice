import Foundation
import SwiftUI

protocol VocabularyProviding {
    var allVocabulary: [VocabularyItem] { get }
    var vocabularyByLevel: [Int: [VocabularyItem]] { get }
    var vocabularyByChapter: [String: [VocabularyItem]] { get }
    var chapters: [Chapter] { get }
    var customVocabulary: [VocabularyItem] { get }
    
    func loadVocabulary()
    func getVocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem]
    func getVocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem]
    func getReviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem]
    func getChaptersForLevel(_ level: Int) -> [Chapter]
    func getChapter(byId chapterId: String) -> Chapter?
}

final class VocabularyService: ObservableObject, VocabularyProviding {
    @Published var allVocabulary: [VocabularyItem] = []
    @Published var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    @Published var vocabularyByChapter: [String: [VocabularyItem]] = [:]
    @Published var chapters: [Chapter] = []
    @Published var customVocabulary: [VocabularyItem] = []
    @Published var isLoading = false
    
    private let loader: VocabularyLoading
    private let organizer: ChapterOrganizing
    
    init(loader: VocabularyLoading, organizer: ChapterOrganizing) {
        self.loader = loader
        self.organizer = organizer
    }
    
    func loadVocabulary() {
        isLoading = true
        
        var allItems: [VocabularyItem] = []
        chapters.removeAll()
        vocabularyByChapter.removeAll()
        
        for level in Constants.HSK.minLevel...Constants.HSK.maxLevel {
            if let items = loader.loadVocabularyFromJSON(level: level) {
                let sortedItems = items.sorted { $0.frequency < $1.frequency }
                vocabularyByLevel[level] = sortedItems
                allItems.append(contentsOf: sortedItems)
                
                let levelChapters = organizer.organizeIntoChapters(items: sortedItems, level: level)
                chapters.append(contentsOf: levelChapters)
                
                for chapter in levelChapters {
                    let chapterId = ChapterIdentifier(chapter.id)
                    vocabularyByChapter[chapter.id] = organizer.getChapterVocabulary(
                        chapterId: chapterId,
                        from: vocabularyByChapter
                    )
                }
            }
        }
        
        customVocabulary = loader.loadCustomVocabulary()
        allItems.append(contentsOf: customVocabulary)
        
        allVocabulary = allItems
        isLoading = false
    }
    
    func getVocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        return levels.flatMap { level in
            vocabularyByLevel[level] ?? []
        }
    }
    
    func getVocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        return chapterIds.flatMap { chapterId in
            vocabularyByChapter[chapterId] ?? []
        }
    }
    
    func getReviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem] {
        return allVocabulary.filter { incorrectWordIds.contains($0.id) }
    }
    
    func getChaptersForLevel(_ level: Int) -> [Chapter] {
        return chapters.filter { chapter in
            chapter.hskLevel == level && !ChapterCurriculum.reviewChapters.contains(chapter.chapterNumber)
        }
    }
    
    func getChapter(byId chapterId: String) -> Chapter? {
        return chapters.first { $0.id == chapterId }
    }
}