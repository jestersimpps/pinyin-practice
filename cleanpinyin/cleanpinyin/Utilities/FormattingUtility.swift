import Foundation

struct FormattingUtility {
    // MARK: - Number Formatting
    static func formatAccuracy(_ accuracy: Double) -> String {
        return String(format: "%.0f%%", accuracy)
    }
    
    static func formatPercentage(_ value: Double, decimalPlaces: Int = 0) -> String {
        return String(format: "%.\(decimalPlaces)f%%", value)
    }
    
    static func formatSessionCount(_ count: Int) -> String {
        if count == 1 {
            return "1 session"
        } else {
            return "\(count) sessions"
        }
    }
    
    // MARK: - Time Formatting
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes == 0 {
            return "\(remainingSeconds)s"
        } else if remainingSeconds == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Progress Formatting
    static func formatWordCount(_ count: Int) -> String {
        if count == 1 {
            return "1 word"
        } else {
            return "\(count) words"
        }
    }
    
    static func formatChapterProgress(completed: Int, total: Int) -> String {
        return "\(completed)/\(total)"
    }
    
    static func formatStreak(_ streak: Int) -> String {
        if streak == 1 {
            return "1 day streak"
        } else {
            return "\(streak) day streak"
        }
    }
    
    // MARK: - Level Formatting
    static func formatHSKLevel(_ level: Int) -> String {
        return "HSK \(level)"
    }
    
    static func formatLevelRange(_ levels: Set<Int>) -> String {
        let sortedLevels = levels.sorted()
        if sortedLevels.isEmpty {
            return "No levels selected"
        } else if sortedLevels.count == 1 {
            return formatHSKLevel(sortedLevels[0])
        } else {
            return sortedLevels.map { formatHSKLevel($0) }.joined(separator: ", ")
        }
    }
    
    // MARK: - Chapter Formatting
    static func formatChapterName(_ chapterNumber: Int) -> String {
        return "Chapter \(chapterNumber)"
    }
    
    static func formatChapterIdentifier(_ chapterId: String) -> String {
        if let number = extractChapterNumber(from: chapterId) {
            return formatChapterName(number)
        }
        return chapterId
    }
    
    private static func extractChapterNumber(from chapterId: String) -> Int? {
        let components = chapterId.split(separator: "_")
        if components.count == 2, components[0] == "chapter", let number = Int(components[1]) {
            return number
        }
        return nil
    }
}