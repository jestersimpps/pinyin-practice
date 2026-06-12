import Foundation

enum AppConstants {
    enum Timing {
        static let autoSubmitDelay: TimeInterval = 0.5
        static let correctAnswerAdvanceDelay: TimeInterval = 1.0
        static let lastWordAdvanceDelay: TimeInterval = 1.5
    }

    enum Chapters {
        static let unlockRequirement = 0.8 // 80% completion to unlock next
    }

    enum Validation {
        static let validToneNumbers = ["1", "2", "3", "4"]
        static let validPinyinEndings = ["a", "e", "i", "o", "u", "n", "g", "r"]
        static let validPinyinEndingsWithTones = validPinyinEndings + validToneNumbers
    }
}
