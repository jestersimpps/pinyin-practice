import Foundation

struct PracticeSession: Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let wordsStudied: Int
    let correctAnswers: Int
    let accuracy: Double
    let hskLevels: [Int]
    
    init(id: UUID = UUID(), date: Date, duration: TimeInterval, wordsStudied: Int, correctAnswers: Int, accuracy: Double, hskLevels: [Int]) {
        self.id = id
        self.date = date
        self.duration = duration
        self.wordsStudied = wordsStudied
        self.correctAnswers = correctAnswers
        self.accuracy = accuracy
        self.hskLevels = hskLevels
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}