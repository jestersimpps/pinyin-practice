import Foundation

struct Chapter: Identifiable, Equatable {
    static let customLevel = 7

    enum Kind: Equatable {
        case curriculum
        case frequencySet
        case custom
    }

    let id: String
    let kind: Kind
    let hskLevel: Int
    let chapterNumber: Int
    let title: String
    let description: String
    let wordCount: Int
    let icon: String

    var displayTitle: String {
        switch kind {
        case .curriculum: return "Chapter \(chapterNumber): \(title)"
        case .frequencySet: return "Set \(chapterNumber): \(title)"
        case .custom: return title
        }
    }
}
