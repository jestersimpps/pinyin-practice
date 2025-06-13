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
    @Published var showingChapterCompletion = false
    @Published var completedChapter: Chapter?
    @Published var completedChapterProgress: ChapterProgress?
    
    private var autoCheckTimer: Timer?
    
    private var vocabularyService = VocabularyService.shared
    private var progressService = UserProgressService.shared
    private var availableWords: [VocabularyItem] = []
    private var currentIndex: Int = 0
    
    // Session tracking
    private var sessionCorrectAnswers: Int = 0
    private var sessionTotalAttempts: Int = 0
    
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
    
    func loadNextChapter() {
        guard let currentChapter = completedChapter else { return }
        
        // Update settings to load next chapter
        let nextChapterNumber = currentChapter.chapterNumber + 1
        if nextChapterNumber <= ChapterCurriculum.totalChapters {
            progressService.settings.selectedChapters = ["chapter_\(nextChapterNumber)"]
            loadWords()
        }
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
            
        case .chapter:
            availableWords = vocabularyService.getVocabularyForChapters(settings.selectedChapters)
            
            // Prioritize words not yet completed in chapters
            let seenWords = progressService.progress.seenWords
            availableWords.sort { word1, word2 in
                let word1Seen = seenWords.contains(word1.id)
                let word2Seen = seenWords.contains(word2.id)
                
                // If both seen or both unseen, maintain order
                if word1Seen == word2Seen { return false }
                
                // Otherwise, prioritize unseen words
                return !word1Seen && word2Seen
            }
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
        
        sessionTotalAttempts += 1
        
        if isCorrect {
            feedbackState = .correct
            progressService.recordAnswer(for: word, isCorrect: true)
            sessionCorrectAnswers += 1
            
            // Update chapter progress if in chapter mode
            if progressService.settings.practiceMode == .chapter {
                updateChapterProgress(for: word)
                
                // Check if we should show completion immediately after this word
                if showingChapterCompletion {
                    return // Don't auto-advance if showing completion
                }
            }
            
            // Only auto-advance if not showing chapter completion
            if !showingChapterCompletion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.nextWord()
                }
            }
        } else if isPartial {
            feedbackState = .partial
            progressService.recordAnswer(for: word, isCorrect: false)
        } else {
            feedbackState = .incorrect
            progressService.recordAnswer(for: word, isCorrect: false)
        }
    }
    
    private func updateChapterProgress(for word: VocabularyItem) {
        
        // Find which chapter this word belongs to
        for (chapterId, words) in vocabularyService.vocabularyByChapter {
            if words.contains(where: { $0.id == word.id }) {
                
                // Record the attempt for chapter stats
                if let chapterProgress = progressService.getChapterProgress(chapterId: chapterId) {
                    var updatedProgress = chapterProgress
                    updatedProgress.recordAttempt(isCorrect: true, practiceTime: 0) // Practice time is tracked at session level
                    progressService.progress.chapterProgress[chapterId] = updatedProgress
                }
                
                let wasCompleted = progressService.updateChapterProgress(
                    chapterId: chapterId,
                    wordId: word.id,
                    totalWords: words.count
                )
                
                
                // Check if chapter was just completed
                if wasCompleted {
                    // Get chapter info from curriculum
                    if let chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter_", with: "")) {
                        let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
                        
                        // Create chapter object
                        completedChapter = Chapter(
                            id: chapterId,
                            hskLevel: chapterInfo.hskLevel,
                            chapterNumber: chapterNumber,
                            title: chapterInfo.title,
                            description: chapterInfo.description,
                            wordCount: words.count,
                            isUnlocked: true,
                            icon: chapterInfo.icon
                        )
                        
                        // Get the chapter progress
                        completedChapterProgress = progressService.progress.chapterProgress[chapterId]
                        
                        // Show completion view
                        showingChapterCompletion = true
                    }
                }
                
                break
            }
        }
    }
    
    func nextWord() {
        wordsCompleted += 1
        currentIndex += 1
        
        // Check if this was the last word in chapter mode
        if progressService.settings.practiceMode == .chapter && 
           currentIndex >= availableWords.count &&
           !showingChapterCompletion {
            checkForChapterCompletion()
        }
        
        loadNextWord()
    }
    
    private func checkForChapterCompletion() {
        
        // Check all selected chapters for completion
        for chapterId in progressService.settings.selectedChapters {
            
            if let progress = progressService.progress.chapterProgress[chapterId] {
                
                if progress.isCompleted && !showingChapterCompletion {
                    
                    // Get chapter info from curriculum
                    if let chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter_", with: "")) {
                        let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
                        
                        // Create chapter object
                        completedChapter = Chapter(
                            id: chapterId,
                            hskLevel: chapterInfo.hskLevel,
                            chapterNumber: chapterNumber,
                            title: chapterInfo.title,
                            description: chapterInfo.description,
                            wordCount: progress.totalWords,
                            isUnlocked: true,
                            icon: chapterInfo.icon
                        )
                        
                        // Get the chapter progress
                        completedChapterProgress = progress
                        
                        // Show completion view
                        showingChapterCompletion = true
                        break
                    }
                }
            } else {
            }
        }
    }
    
    func skipWord() {
        if let word = currentWord {
            progressService.recordAnswer(for: word, isCorrect: false)
        }
        wasSkipped = true
        feedbackState = .incorrect
    }
    
    
    private func endSession() {
        if let startTime = sessionStartTime {
            progressService.endSession(
                startTime: startTime, 
                wordsStudied: wordsCompleted,
                correctAnswers: sessionCorrectAnswers,
                totalAttempts: sessionTotalAttempts
            )
            sessionStartTime = nil // Prevent duplicate saves
        }
        
        // Check if we're in chapter mode and all words have been completed
        if progressService.settings.practiceMode == .chapter && 
           wordsCompleted >= availableWords.count && 
           !showingChapterCompletion {
            // Find the chapter that was just completed
            for chapterId in progressService.settings.selectedChapters {
                if let progress = progressService.progress.chapterProgress[chapterId],
                   progress.isCompleted {
                    // Get chapter info
                    if let chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter_", with: "")) {
                        let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
                        
                        completedChapter = Chapter(
                            id: chapterId,
                            hskLevel: chapterInfo.hskLevel,
                            chapterNumber: chapterNumber,
                            title: chapterInfo.title,
                            description: chapterInfo.description,
                            wordCount: progress.totalWords,
                            isUnlocked: true,
                            icon: chapterInfo.icon
                        )
                        
                        completedChapterProgress = progress
                        showingChapterCompletion = true
                        break
                    }
                }
            }
        }
    }
    
    func saveSessionOnExit() {
        // Only save if we have studied at least one word and haven't already saved
        if wordsCompleted > 0 && sessionStartTime != nil {
            endSession()
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
        let targetNumeric = word.toneNumbers.lowercased()
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