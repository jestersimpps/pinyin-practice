import Foundation

struct ChapterCurriculum {
    static let totalChapters = 79
    static let reviewChapters: Set<Int> = [14, 28, 42, 56, 68, 79]
    
    static func chaptersForLevel(_ level: Int) -> Int {
        return Constants.HSK.chaptersPerLevel[level] ?? 0
    }
    
    static func getChapterInfo(chapter: Int) -> (hskLevel: Int, title: String, description: String, icon: String) {
        // Placeholder implementation - you should replace with your actual curriculum data
        let hskLevel: Int
        if chapter <= 14 {
            hskLevel = 1
        } else if chapter <= 28 {
            hskLevel = 2
        } else if chapter <= 42 {
            hskLevel = 3
        } else if chapter <= 56 {
            hskLevel = 4
        } else if chapter <= 68 {
            hskLevel = 5
        } else {
            hskLevel = 6
        }
        
        return (
            hskLevel: hskLevel,
            title: "Chapter \(chapter)",
            description: "Practice vocabulary for Chapter \(chapter)",
            icon: "book.fill"
        )
    }
}