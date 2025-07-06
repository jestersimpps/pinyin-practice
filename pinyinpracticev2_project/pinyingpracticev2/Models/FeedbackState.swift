import Foundation

enum FeedbackState {
    case none
    case correct
    case incorrect
    case partial
    
    var isAnswered: Bool {
        switch self {
        case .none:
            return false
        case .correct, .incorrect, .partial:
            return true
        }
    }
    
    var isCorrect: Bool {
        return self == .correct
    }
}