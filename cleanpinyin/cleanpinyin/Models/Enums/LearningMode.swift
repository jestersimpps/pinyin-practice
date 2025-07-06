import Foundation

enum LearningMode {
    case levels(Set<Int>)
    case chapters(Set<String>)
    case review(Set<String>)
}