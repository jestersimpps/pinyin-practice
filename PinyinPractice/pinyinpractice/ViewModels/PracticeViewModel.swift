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
    @Published var wasSkipped: Bool = false
    
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
    
    func reloadWordsIfNeeded() {
        loadWords()
    }
    
    func loadWords() {
        let settings = progressService.settings
        
        switch settings.practiceMode {
        case .sequential:
            availableWords = vocabularyService.getVocabularyForLevels(settings.selectedHSKLevels)
                .sorted { $0.frequency < $1.frequency }
            
        case .random:
            availableWords = vocabularyService.getVocabularyForLevels(settings.selectedHSKLevels)
            
            // First shuffle all words
            availableWords.shuffle()
            
            // Then prioritize unseen words
            let seenWords = progressService.progress.seenWords
            availableWords.sort { word1, word2 in
                let word1Seen = seenWords.contains(word1.id)
                let word2Seen = seenWords.contains(word2.id)
                
                // If both seen or both unseen, maintain shuffled order
                if word1Seen == word2Seen { return false }
                
                // Otherwise, prioritize unseen words
                return !word1Seen && word2Seen
            }
            
        case .reviewMistakes:
            availableWords = vocabularyService.getReviewVocabulary(
                incorrectWordIds: progressService.progress.incorrectWords
            ).shuffled()
        }
        
        // Reset current index when reloading
        currentIndex = 0
        wordsCompleted = 0
        
        loadNextWord()
    }
    
    func loadNextWord() {
        guard currentIndex < availableWords.count else {
            endSession()
            return
        }
        
        currentWord = availableWords[currentIndex]
        userInput = ""
        showHint = false
        feedbackState = .none
        wasSkipped = false
    }
    
    func checkAnswer() {
        guard let word = currentWord else { return }
        
        let requireTones = progressService.settings.requireTones
        let isCorrect = word.isPinyinCorrect(userInput, requireTones: requireTones)
        
        let isPartial = requireTones && !isCorrect && word.isPinyinPartiallyCorrect(userInput)
        
        if isCorrect {
            feedbackState = .correct
            progressService.recordAnswer(for: word, isCorrect: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.nextWord()
            }
        } else if isPartial {
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
        wasSkipped = true
        feedbackState = .incorrect
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
    }
    
    private func checkIfShouldAutoSubmit() {
        autoCheckTimer?.invalidate()
        
        guard !progressService.settings.requireTones else { return }
        
        guard feedbackState == .none,
              !userInput.isEmpty,
              let word = currentWord else { return }
        
        let inputLooksComplete = isInputLikelyComplete(userInput, for: word)
        
        if inputLooksComplete {
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
        
        if trimmedInput == targetPinyin || trimmedInput == targetNumeric {
            return true
        }
        
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
        
        let inputSyllables = trimmedInput.split(separator: " ").count
        let targetSyllables = max(
            targetPinyin.split(separator: " ").count,
            targetNumeric.split(separator: " ").count
        )
        
        if inputSyllables == targetSyllables {
            if let lastChar = trimmedInput.last {
                if requireTones {
                    let validEndings = ["1", "2", "3", "4", "a", "e", "i", "o", "u", "n", "g", "r"]
                    return validEndings.contains(String(lastChar))
                } else {
                    let validEndings = ["a", "e", "i", "o", "u", "n", "g", "r"]
                    return validEndings.contains(String(lastChar))
                }
            }
        }
        
        return false
    }
}