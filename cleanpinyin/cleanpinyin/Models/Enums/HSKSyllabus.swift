import Foundation

enum HSKSyllabus: String, Codable, CaseIterable, Identifiable {
    case hsk3
    case hsk2

    var id: String { rawValue }

    var name: String {
        switch self {
        case .hsk3: return "HSK 3.0"
        case .hsk2: return "HSK 2.0"
        }
    }

    var summary: String {
        switch self {
        case .hsk3: return "The new exam from 2026"
        case .hsk2: return "The classic word list"
        }
    }

    // HSK 2.0 keeps the chapter ids it had before HSK 3.0 existed, so saved chapter progress still matches
    var chapterIdPrefix: String {
        switch self {
        case .hsk3: return "hsk3.0_"
        case .hsk2: return ""
        }
    }
}
