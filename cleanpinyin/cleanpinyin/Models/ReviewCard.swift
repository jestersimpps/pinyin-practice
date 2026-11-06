import Foundation

enum ReviewRating: Int, Codable {
    case again = 1
    case hard
    case good
    case easy
}

struct ReviewCard: Codable, Equatable {
    var stability: Double
    var difficulty: Double
    var due: Date
    var lastReview: Date
    var reps: Int
    var lapses: Int
}
