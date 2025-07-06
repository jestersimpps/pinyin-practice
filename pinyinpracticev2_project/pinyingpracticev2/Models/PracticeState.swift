import Foundation

struct PracticeState {
    var currentWord: VocabularyItem?
    var userInput: String = ""
    var feedbackState: FeedbackState = .none
    var showHint: Bool = false
    var wasSkipped: Bool = false
    var wordStartTime: Date?
    
    var currentIndex: Int = 0
    var wordsCompleted: Int = 0
    var sessionCorrectAnswers: Int = 0
    var sessionTotalAttempts: Int = 0
    
    var availableWords: [VocabularyItem] = []
    var learningMode: LearningMode?
    
    var isPracticeComplete: Bool {
        currentIndex >= availableWords.count
    }
    
    var isLastWord: Bool {
        currentIndex == availableWords.count - 1
    }
    
    var totalWords: Int {
        availableWords.count
    }
    
    var progressPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsCompleted) / Double(totalWords)
    }
    
    mutating func reset() {
        currentWord = nil
        userInput = ""
        feedbackState = .none
        showHint = false
        wasSkipped = false
        wordStartTime = nil
        currentIndex = 0
        wordsCompleted = 0
        sessionCorrectAnswers = 0
        sessionTotalAttempts = 0
    }
    
    mutating func nextWord() {
        wordsCompleted += 1
        currentIndex += 1
    }
    
    mutating func recordAttempt(isCorrect: Bool) {
        sessionTotalAttempts += 1
        if isCorrect {
            sessionCorrectAnswers += 1
        }
    }
}