import Foundation

protocol VocabularyServiceProtocol: AnyObject {
    var allVocabulary: [VocabularyItem] { get }
    var vocabularyByLevel: [Int: [VocabularyItem]] { get }
    var vocabularyByChapter: [String: [VocabularyItem]] { get }
    var chapters: [Chapter] { get }
    var customVocabulary: [VocabularyItem] { get }
    var isLoading: Bool { get }
    
    func loadVocabulary()
    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem]
    func reviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem]
    func allVocabularyItems() -> [VocabularyItem]
    func vocabularyForLevel(_ level: Int) -> [VocabularyItem]
    func vocabularyForChapter(_ chapterId: String) -> [VocabularyItem]
    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem]
    func chaptersForLevel(_ level: Int) -> [Chapter]
    func chapter(byId chapterId: String) -> Chapter?
    func customVocabularyItems() -> [VocabularyItem]
}