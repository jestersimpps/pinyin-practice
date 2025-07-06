import Foundation
import SwiftUI

enum AppConstants {
    // MARK: - Timing Constants
    enum Timing {
        static let autoSubmitDelay: TimeInterval = 0.5
        static let correctAnswerAdvanceDelay: TimeInterval = 1.0
        static let lastWordAdvanceDelay: TimeInterval = 1.5
        static let animationDuration: TimeInterval = 0.25
        static let keyboardAnimationDuration: TimeInterval = 0.25
    }
    
    // MARK: - UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let largeCornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 8
        
        static let standardPadding: CGFloat = 16
        static let compactPadding: CGFloat = 8
        static let largePadding: CGFloat = 20
        
        static let buttonHeight: CGFloat = 44
        static let smallButtonSize: CGFloat = 36
        
        static let shadowRadius: CGFloat = 2
        static let shadowOpacity: Double = 0.05
        
        static let borderWidth: CGFloat = 2
        static let thinBorderWidth: CGFloat = 1
    }
    
    // MARK: - Colors
    enum Colors {
        static let correctGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let incorrectRed = Color.red
        static let partialOrange = Color.orange
        static let primaryBlue = Color(red: 0.1, green: 0.3, blue: 0.4)
    }
    
    // MARK: - Font Sizes
    enum FontSize {
        static let tiny: CGFloat = 12
        static let small: CGFloat = 14
        static let regular: CGFloat = 16
        static let medium: CGFloat = 18
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
        static let huge: CGFloat = 32
    }
    
    // MARK: - Practice Settings
    enum Practice {
        static let minWordsForSession = 1
        static let defaultSessionSize = 20
        static let maxSessionSize = 100
        
        static let reviewSessionSize = 15
        static let chapterBatchSize = 10
    }
    
    // MARK: - Progress Thresholds
    enum Progress {
        static let masteryThreshold = 0.9 // 90% accuracy for mastery
        static let proficiencyThreshold = 0.8 // 80% for proficiency
        static let familiarityThreshold = 0.6 // 60% for familiarity
        
        static let minimumSessionsForStats = 3
        static let recentSessionsCount = 10
    }
    
    // MARK: - Storage Keys
    enum StorageKeys {
        static let userProgress = "UserProgress"
        static let practiceSettings = "PracticeSettings"
        static let practiceSessions = "PracticeSessions"
        static let lastPracticeDate = "LastPracticeDate"
        static let preferredColorScheme = "preferredColorScheme"
    }
    
    // MARK: - File Names
    enum FileNames {
        static let vocabularyFilePrefix = "hsk"
        static let vocabularyFileExtension = "json"
        static let customDataFolder = "CustomData"
        static let dataFolder = "Data"
        
        static func vocabularyFileName(for level: Int) -> String {
            return "\(level).min.json"
        }
    }
    
    // MARK: - Chapter Constants
    enum Chapters {
        static let totalChapters = 80
        static let chaptersPerHSKLevel = [
            1: 14,
            2: 14,
            3: 14,
            4: 14,
            5: 12,
            6: 12
        ]
        
        static let wordsPerChapterRange = 10...25
        static let unlockRequirement = 0.8 // 80% completion to unlock next
    }
    
    // MARK: - Validation
    enum Validation {
        static let validToneNumbers = ["1", "2", "3", "4"]
        static let validPinyinEndings = ["a", "e", "i", "o", "u", "n", "g", "r"]
        static let validPinyinEndingsWithTones = validPinyinEndings + validToneNumbers
    }
    
    // MARK: - Animation
    enum Animation {
        static let springResponse = 0.5
        static let springDampingFraction = 0.8
        static let feedbackDelay = 0.1
    }
}