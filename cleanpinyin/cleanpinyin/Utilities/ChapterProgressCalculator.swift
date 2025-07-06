import Foundation

struct ChapterProgressCalculator {
    // Calculate overall progress percentage for a chapter
    static func calculateProgress(for chapter: ChapterProgress) -> Double {
        guard chapter.totalWords > 0 else { return 0 }
        return Double(chapter.wordsCompleted.count) / Double(chapter.totalWords) * 100
    }
    
    // Calculate accuracy for a chapter
    static func calculateAccuracy(for chapter: ChapterProgress) -> Double {
        guard chapter.totalAttempts > 0 else { return 0 }
        return Double(chapter.correctAttempts) / Double(chapter.totalAttempts) * 100
    }
    
    // Calculate estimated time to complete a chapter
    static func estimateTimeToComplete(
        wordsRemaining: Int,
        averageTimePerWord: TimeInterval,
        practiceMode: PracticeMode
    ) -> TimeInterval {
        var timePerWord = averageTimePerWord
        
        // Adjust based on practice mode
        if practiceMode == .random {
            timePerWord *= 1.1 // Random mode might take slightly longer
        }
        
        return TimeInterval(wordsRemaining) * timePerWord
    }
    
    // Calculate chapter difficulty score based on user performance
    static func calculateDifficultyScore(for chapter: ChapterProgress) -> Double {
        guard chapter.totalAttempts > 0 else { return 0 }
        
        let accuracy = calculateAccuracy(for: chapter)
        let averageAttemptsPerWord = Double(chapter.totalAttempts) / Double(max(chapter.wordsCompleted.count, 1))
        
        // Lower accuracy and more attempts per word = higher difficulty
        let difficultyFromAccuracy = (100 - accuracy) / 100
        let difficultyFromAttempts = min((averageAttemptsPerWord - 1) / 3, 1.0)
        
        return (difficultyFromAccuracy * 0.7) + (difficultyFromAttempts * 0.3)
    }
    
    // Calculate practice efficiency (words learned per minute)
    static func calculateEfficiency(
        wordsCompleted: Int,
        practiceTime: TimeInterval
    ) -> Double {
        guard practiceTime > 0 else { return 0 }
        return Double(wordsCompleted) / (practiceTime / 60)
    }
    
    // Get recommended review interval based on performance
    static func recommendedReviewInterval(for chapter: ChapterProgress) -> TimeInterval {
        let accuracy = calculateAccuracy(for: chapter)
        let baseInterval: TimeInterval = 24 * 60 * 60 // 1 day
        
        if accuracy >= 90 {
            return baseInterval * 7 // Review in 1 week
        } else if accuracy >= 80 {
            return baseInterval * 3 // Review in 3 days
        } else if accuracy >= 70 {
            return baseInterval * 1 // Review in 1 day
        } else {
            return baseInterval * 0.5 // Review in 12 hours
        }
    }
    
    // Calculate mastery level (0-5 stars)
    static func calculateMasteryLevel(for chapter: ChapterProgress) -> Int {
        let progress = calculateProgress(for: chapter)
        let accuracy = calculateAccuracy(for: chapter)
        
        // Weighted score: 40% progress, 60% accuracy
        let score = (progress * 0.4) + (accuracy * 0.6)
        
        switch score {
        case 95...100: return 5
        case 85..<95: return 4
        case 70..<85: return 3
        case 50..<70: return 2
        case 25..<50: return 1
        default: return 0
        }
    }
    
    // Calculate streak bonus multiplier
    static func calculateStreakMultiplier(currentStreak: Int) -> Double {
        switch currentStreak {
        case 0...2: return 1.0
        case 3...6: return 1.1
        case 7...13: return 1.2
        case 14...29: return 1.3
        case 30...59: return 1.4
        default: return 1.5
        }
    }
    
    // Get progress milestones
    static func getNextMilestone(currentProgress: Double) -> (milestone: Int, remaining: Double) {
        let milestones = [25, 50, 75, 100]
        
        for milestone in milestones {
            if currentProgress < Double(milestone) {
                return (milestone, Double(milestone) - currentProgress)
            }
        }
        
        return (100, 0)
    }
    
    // Calculate total progress across all chapters
    static func calculateOverallProgress(chapters: [ChapterProgress]) -> Double {
        guard !chapters.isEmpty else { return 0 }
        
        let totalWords = chapters.reduce(0) { $0 + $1.totalWords }
        let completedWords = chapters.reduce(0) { $0 + $1.wordsCompleted.count }
        
        guard totalWords > 0 else { return 0 }
        return Double(completedWords) / Double(totalWords) * 100
    }
}