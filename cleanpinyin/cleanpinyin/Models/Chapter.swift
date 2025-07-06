import Foundation

struct Chapter: Identifiable, Codable {
    let id: String
    let hskLevel: Int
    let chapterNumber: Int
    let title: String
    let description: String
    let wordCount: Int
    let isUnlocked: Bool
    let icon: String
    
    var displayTitle: String {
        "Chapter \(chapterNumber): \(title)"
    }
}
