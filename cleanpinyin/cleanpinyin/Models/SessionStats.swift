import Foundation

struct SessionStats: Equatable {
    let wordsStudied: Int
    let correctAnswers: Int
    let totalAttempts: Int
    let practiceMode: String
    let duration: TimeInterval
    let bestCombo: Int

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAttempts) * 100
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
