import Foundation

struct Chapter: Identifiable, Codable {
    let id: String
    let hskLevel: Int
    let chapterNumber: Int
    let title: String
    let description: String
    let wordCount: Int
    let isUnlocked: Bool
    
    var displayTitle: String {
        "Chapter \(chapterNumber): \(title)"
    }
}

struct ChapterProgress: Codable {
    let chapterId: String
    var wordsCompleted: Set<String>
    var totalWords: Int
    var isCompleted: Bool
    var completionDate: Date?
    
    var completionPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsCompleted.count) / Double(totalWords) * 100
    }
    
    var isUnlocked: Bool {
        // First chapter of each level is always unlocked
        // Other chapters unlock when previous chapter is 80% complete
        return true // Will be calculated based on previous chapter progress
    }
    
    mutating func markWordCompleted(_ wordId: String) {
        wordsCompleted.insert(wordId)
        if wordsCompleted.count == totalWords && !isCompleted {
            isCompleted = true
            completionDate = Date()
        }
    }
}

struct ChapterConfiguration {
    static let chaptersPerLevel: [Int: Int] = [
        1: 10,  // HSK1: 150 words / 10 chapters = 15 words per chapter
        2: 10,  // HSK2: 300 words / 10 chapters = 30 words per chapter
        3: 12,  // HSK3: 600 words / 12 chapters = 50 words per chapter
        4: 12,  // HSK4: 1200 words / 12 chapters = 100 words per chapter
        5: 15,  // HSK5: 2500 words / 15 chapters = ~167 words per chapter
        6: 20   // HSK6: 5000 words / 20 chapters = 250 words per chapter
    ]
    
    static let chapterTitles: [Int: [String]] = [
        1: [
            "Greetings & Basic Phrases",
            "Numbers & Time",
            "Family & People",
            "Food & Drinks",
            "Daily Activities",
            "Places & Directions",
            "Shopping & Money",
            "Weather & Seasons",
            "Hobbies & Interests",
            "Review & Practice"
        ],
        2: [
            "Extended Greetings",
            "Transportation",
            "Health & Body",
            "School & Education",
            "Work & Career",
            "Entertainment",
            "Emotions & Feelings",
            "Nature & Environment",
            "Technology & Modern Life",
            "Advanced Review"
        ],
        // Add more titles for other levels as needed
    ]
    
    static func getChapterTitle(level: Int, chapter: Int) -> String {
        if let titles = chapterTitles[level], chapter <= titles.count {
            return titles[chapter - 1]
        }
        return "Chapter \(chapter)"
    }
}