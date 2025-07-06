import Foundation

class WordProgressTracker {
    private(set) var availableWords: [VocabularyItem] = []
    private(set) var currentIndex: Int = 0
    private(set) var currentWord: VocabularyItem?
    
    var totalWords: Int {
        availableWords.count
    }
    
    var progressPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(currentIndex) / Double(totalWords)
    }
    
    var isPracticeComplete: Bool {
        currentIndex >= availableWords.count
    }
    
    var isLastWord: Bool {
        currentIndex == availableWords.count - 1
    }
    
    func setWords(_ words: [VocabularyItem]) {
        availableWords = words
        currentIndex = 0
        loadCurrentWord()
    }
    
    func moveToNextWord() -> Bool {
        guard currentIndex < availableWords.count else {
            return false
        }
        
        currentIndex += 1
        
        if currentIndex < availableWords.count {
            loadCurrentWord()
            return true
        } else {
            currentWord = nil
            return false
        }
    }
    
    func loadCurrentWord() {
        guard currentIndex < availableWords.count else {
            currentWord = nil
            return
        }
        
        currentWord = availableWords[currentIndex]
    }
    
    func reset() {
        currentIndex = 0
        loadCurrentWord()
    }
}