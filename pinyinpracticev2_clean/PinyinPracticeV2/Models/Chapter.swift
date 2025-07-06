import Foundation

struct Chapter: Identifiable, Hashable {
    let id: String
    let hskLevel: Int
    let chapterNumber: Int
    let title: String
    let description: String
    let wordCount: Int
    let isUnlocked: Bool
    let icon: String
    
    var formattedTitle: String {
        return "Chapter \(chapterNumber): \(title)"
    }
    
    var displayTitle: String {
        if isCustom {
            return title
        } else {
            return "Chapter \(chapterNumber)"
        }
    }
    
    var isCustom: Bool {
        return hskLevel == Constants.HSK.customLevel
    }
}