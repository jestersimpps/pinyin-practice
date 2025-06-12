import Foundation
import SwiftUI

class PracticeViewModel: ObservableObject {
    @Published var currentWord: VocabularyItem?
    @Published var userInput: String = "" {
        didSet {
            checkIfShouldAutoSubmit()
        }
    }
    @Published var showHint: Bool = false
    @Published var feedbackState: FeedbackState = .none
    @Published var wordsCompleted: Int = 0
    @Published var sessionStartTime: Date?
    
    private var autoCheckTimer: Timer?
    
    private var vocabularyService = VocabularyService.shared
    private var progressService = UserProgressService.shared
    private var availableWords: [VocabularyItem] = []
    private var currentIndex: Int = 0
    
    enum FeedbackState {
        case none
        case correct
        case incorrect
        case partial
    }
    
    var totalWords: Int {
        availableWords.count
    }
    
    var progressPercentage: Double {
        guard totalWords > 0 else { return 0 }
        return Double(wordsCompleted) / Double(totalWords)
    }
    
    var currentStreak: Int {
        progressService.progress.currentStreak
    }
    
    var accuracy: String {
        progressService.progress.formattedAccuracy
    }
    
    init() {
        loadWords()
        sessionStartTime = progressService.startNewSession()
    }
    
    func loadWords() {
        let settings = progressService.settings
        
        switch settings.practiceMode {
        case .sequential:
            availableWords = vocabularyService.getFilteredVocabulary(
                levels: settings.selectedHSKLevels,
                categories: settings.selectedCategories
            ).sorted { $0.id < $1.id }
            
        case .random:
            availableWords = vocabularyService.getFilteredVocabulary(
                levels: settings.selectedHSKLevels,
                categories: settings.selectedCategories
            ).shuffled()
            
            // Prioritize new words
            let seenWords = progressService.progress.seenWords
            availableWords.sort { word1, word2 in
                let word1Seen = seenWords.contains(word1.id)
                let word2Seen = seenWords.contains(word2.id)
                if word1Seen == word2Seen { return false }
                return !word1Seen && word2Seen
            }
            
        case .reviewMistakes:
            availableWords = vocabularyService.getReviewVocabulary(
                incorrectWordIds: progressService.progress.incorrectWords
            ).shuffled()
        }
        
        loadNextWord()
    }
    
    func loadNextWord() {
        guard currentIndex < availableWords.count else {
            // Session complete
            endSession()
            return
        }
        
        currentWord = availableWords[currentIndex]
        userInput = ""
        showHint = false
        feedbackState = .none
    }
    
    func checkAnswer() {
        guard let word = currentWord else { return }
        
        let requireTones = progressService.settings.requireTones
        let isCorrect = word.isPinyinCorrect(userInput, requireTones: requireTones)
        
        // Only check for partial if tones are required
        let isPartial = requireTones && !isCorrect && word.isPinyinPartiallyCorrect(userInput)
        
        if isCorrect {
            feedbackState = .correct
            progressService.recordAnswer(for: word, isCorrect: true)
            
            // Automatically move to next word after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.nextWord()
            }
        } else if isPartial {
            // This only happens when requireTones is true
            feedbackState = .partial
            progressService.recordAnswer(for: word, isCorrect: false)
        } else {
            feedbackState = .incorrect
            progressService.recordAnswer(for: word, isCorrect: false)
        }
    }
    
    func nextWord() {
        wordsCompleted += 1
        currentIndex += 1
        loadNextWord()
    }
    
    func skipWord() {
        if let word = currentWord {
            progressService.recordAnswer(for: word, isCorrect: false)
        }
        nextWord()
    }
    
    func toggleHint() {
        showHint.toggle()
    }
    
    func tryAgain() {
        userInput = ""
        feedbackState = .none
    }
    
    private func endSession() {
        if let startTime = sessionStartTime {
            progressService.endSession(startTime: startTime, wordsStudied: wordsCompleted)
        }
        // Navigate to results or setup screen
    }
    
    private func checkIfShouldAutoSubmit() {
        // Cancel any existing timer
        autoCheckTimer?.invalidate()
        
        // Only auto-check if tones are not required
        guard !progressService.settings.requireTones else { return }
        
        // Only auto-check if we haven't already checked
        guard feedbackState == .none,
              !userInput.isEmpty,
              let word = currentWord else { return }
        
        // Check if the input looks complete
        let inputLooksComplete = isInputLikelyComplete(userInput, for: word)
        
        if inputLooksComplete {
            // Wait a short moment before auto-checking
            autoCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.checkAnswer()
            }
        }
    }
    
    private func isInputLikelyComplete(_ input: String, for word: VocabularyItem) -> Bool {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetPinyin = word.pinyin.lowercased()
        let targetNumeric = word.pinyinNumeric.lowercased()
        let requireTones = progressService.settings.requireTones
        
        // Exact match
        if trimmedInput == targetPinyin || trimmedInput == targetNumeric {
            return true
        }
        
        // For tone-less mode, check if the base syllables match
        if !requireTones {
            let inputWithoutSpaces = trimmedInput.replacingOccurrences(of: " ", with: "")
            let targetWithoutTonesAndSpaces = word.pinyin.lowercased()
                .replacingOccurrences(of: "ā", with: "a").replacingOccurrences(of: "á", with: "a")
                .replacingOccurrences(of: "ǎ", with: "a").replacingOccurrences(of: "à", with: "a")
                .replacingOccurrences(of: "ē", with: "e").replacingOccurrences(of: "é", with: "e")
                .replacingOccurrences(of: "ě", with: "e").replacingOccurrences(of: "è", with: "e")
                .replacingOccurrences(of: "ī", with: "i").replacingOccurrences(of: "í", with: "i")
                .replacingOccurrences(of: "ǐ", with: "i").replacingOccurrences(of: "ì", with: "i")
                .replacingOccurrences(of: "ō", with: "o").replacingOccurrences(of: "ó", with: "o")
                .replacingOccurrences(of: "ǒ", with: "o").replacingOccurrences(of: "ò", with: "o")
                .replacingOccurrences(of: "ū", with: "u").replacingOccurrences(of: "ú", with: "u")
                .replacingOccurrences(of: "ǔ", with: "u").replacingOccurrences(of: "ù", with: "u")
                .replacingOccurrences(of: "ǖ", with: "ü").replacingOccurrences(of: "ǘ", with: "ü")
                .replacingOccurrences(of: "ǚ", with: "ü").replacingOccurrences(of: "ǜ", with: "ü")
                .replacingOccurrences(of: " ", with: "")
            
            if inputWithoutSpaces == targetWithoutTonesAndSpaces {
                return true
            }
        }
        
        // Check if input has all syllables (by counting spaces)
        let inputSyllables = trimmedInput.split(separator: " ").count
        let targetSyllables = max(
            targetPinyin.split(separator: " ").count,
            targetNumeric.split(separator: " ").count
        )
        
        // If we have the right number of syllables and the last character is appropriate
        if inputSyllables == targetSyllables {
            if let lastChar = trimmedInput.last {
                if requireTones {
                    // Check if ends with tone number (1-4) or a valid pinyin ending letter
                    let validEndings = ["1", "2", "3", "4", "a", "e", "i", "o", "u", "n", "g", "r"]
                    return validEndings.contains(String(lastChar))
                } else {
                    // For tone-less mode, just check if it ends with a valid pinyin letter
                    let validEndings = ["a", "e", "i", "o", "u", "n", "g", "r"]
                    return validEndings.contains(String(lastChar))
                }
            }
        }
        
        return false
    }
}