import Foundation

struct Chapter: Identifiable, Codable {
    static let customLevel = 7

    let id: String
    let hskLevel: Int
    let chapterNumber: Int
    let title: String
    let description: String
    let wordCount: Int
    let icon: String

    var displayTitle: String {
        "Chapter \(chapterNumber): \(title)"
    }
}
