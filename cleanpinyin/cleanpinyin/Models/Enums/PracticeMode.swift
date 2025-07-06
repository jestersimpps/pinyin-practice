import Foundation

enum PracticeMode: String, CaseIterable, Codable {
    case sequential = "Sequential"
    case random = "Random"
    
    var icon: String {
        switch self {
        case .sequential: return "list.number"
        case .random: return "shuffle"
        }
    }
    
    var description: String {
        switch self {
        case .sequential: return "Study words in HSK order"
        case .random: return "Random order, prioritizing new words"
        }
    }
}