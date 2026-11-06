import Foundation

protocol VocabularyServiceProtocol: AnyObject {
    var allVocabulary: [VocabularyItem] { get }
    var vocabularyByChapter: [String: [VocabularyItem]] { get }
    var chapters: [Chapter] { get }

    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem]
    func vocabularyForLevel(_ level: Int) -> [VocabularyItem]
    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem]
    func words(withIds ids: [String]) -> [VocabularyItem]
    func chaptersForLevel(_ level: Int) -> [Chapter]
    func chapter(withId id: String) -> Chapter?
    func nextChapter(after chapter: Chapter) -> Chapter?
}
