import Foundation

enum LearningMode: Equatable {
    case levels(Set<Int>)
    case chapters(Set<String>)
    case custom(Set<String>)
    case review

    var lastPracticeMode: LastPracticeMode {
        switch self {
        case .levels: return .quick
        case .chapters: return .chapters
        case .custom: return .custom
        case .review: return .review
        }
    }

    var chapterIds: Set<String> {
        switch self {
        case .chapters(let ids), .custom(let ids): return ids
        case .levels, .review: return []
        }
    }
}

struct PracticeLaunch: Identifiable {
    let id = UUID()
    let mode: LearningMode
}
