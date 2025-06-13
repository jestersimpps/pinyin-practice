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
    @Published var showingPracticeCompletion = false
    @Published var sessionStats: PracticeCompletionView.SessionStats?
    
    private var autoCheckTimer: Timer?
    
    var isPracticeComplete: Bool {
        currentIndex >= availableWords.count
    }
    
    var isLastWord: Bool {
        currentIndex == availableWords.count - 1
    }
    
    private var vocabularyService = VocabularyService.shared
    private var progressService = UserProgressService.shared
    private var availableWords: [VocabularyItem] = []
    private var currentIndex: Int = 0
    private var _currentLearningMode: PracticeSettings.LearningMode?
    
    var currentLearningMode: PracticeSettings.LearningMode? {
        return _currentLearningMode
    }
    
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
        // Reset session tracking for new session
        sessionStartTime = progressService.startNewSession()
        sessionCorrectAnswers = 0
        sessionTotalAttempts = 0
        wordsCompleted = 0
        showingPracticeCompletion = false
        showingChapterCompletion = false
        
        loadWords()
    }
    
    func startCustomPractice(levels: Set<Int>) {
        _currentLearningMode = .levels(levels)
        loadWords()
    }
    
    func startChapterPractice(chapters: Set<String>) {
        _currentLearningMode = .chapters(chapters)
        loadWords()
    }
    
    func startReviewPractice(incorrectWords: Set<String>) {
        _currentLearningMode = .review(incorrectWords)
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
        
        // Determine words to study based on learning mode
        var wordsToStudy: [VocabularyItem] = []
        
        if let learningMode = _currentLearningMode {
            switch learningMode {
            case .levels(let levels):
                wordsToStudy = vocabularyService.getVocabularyForLevels(levels)
                
            case .chapters(let chapters):
                wordsToStudy = vocabularyService.getVocabularyForChapters(chapters)
                
            case .review(let incorrectWords):
                wordsToStudy = vocabularyService.getReviewVocabulary(incorrectWordIds: incorrectWords)
            }
        } else {
            // Fallback to settings-based approach for backward compatibility
            wordsToStudy = vocabularyService.getVocabularyForLevels(settings.selectedHSKLevels)
        }
        
        // Apply ordering based on practice mode (sequential vs random)
        switch settings.practiceMode {
        case .sequential:
            availableWords = wordsToStudy.sorted { $0.frequency < $1.frequency }
            
        case .random:
            availableWords = wordsToStudy
            
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
        }
        
        // Reset current index when reloading
        currentIndex = 0
        wordsCompleted = 0
        
        loadNextWord()
    }
    
    func loadNextWord() {
        guard currentIndex < availableWords.count else {
            // We've completed all words, trigger the appropriate completion screen
            if case .chapters = _currentLearningMode {
                // Chapter completion is handled separately
                if !showingChapterCompletion {
                    checkForChapterCompletion()
                }
            } else {
                // For non-chapter modes, show practice completion
                if !showingPracticeCompletion {
                    endSession()
                }
            }
            // Don't clear currentWord to prevent empty UI state
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
            if case .chapters = _currentLearningMode {
                updateChapterProgress(for: word)
                
                // Check if we should show completion immediately after this word
                if showingChapterCompletion {
                    return // Don't auto-advance if showing completion
                }
            }
            
            // Check if this was the last word
            if currentIndex == availableWords.count - 1 {
                // Last word answered correctly - show completion after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.nextWord()
                }
            } else if !showingChapterCompletion {
                // Auto-advance for non-last words
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.nextWord()
                }
            }
        } else if isPartial {
            feedbackState = .partial
            progressService.recordAnswer(for: word, isCorrect: false)
            
            // Auto-advance after delay to allow user to see correct answer
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.nextWord()
            }
        } else {
            feedbackState = .incorrect
            progressService.recordAnswer(for: word, isCorrect: false)
            
            // Auto-advance after delay to allow user to see correct answer
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.nextWord()
            }
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
                    // Handle different chapter ID formats
                    var chapterNumber: Int? = nil
                    
                    if chapterId.hasPrefix("chapter") && !chapterId.contains("_") {
                        // Format: "chapter1", "chapter15", etc.
                        chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter", with: ""))
                    } else if chapterId.contains("chapter_") {
                        // Legacy format: "chapter_1", "chapter_15", etc.
                        chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter_", with: ""))
                    } else if chapterId.contains("hsk") && chapterId.contains("_chapter") {
                        // Format: "hsk1_chapter1", "hsk2_chapter1", etc.
                        let components = chapterId.components(separatedBy: "_chapter")
                        if components.count == 2 {
                            let levelStr = components[0].replacingOccurrences(of: "hsk", with: "")
                            if let level = Int(levelStr),
                               let localChapterNum = Int(components[1]) {
                            // Convert local chapter number to global chapter number
                            switch level {
                            case 1: chapterNumber = localChapterNum
                            case 2: chapterNumber = 15 + localChapterNum
                            case 3: chapterNumber = 28 + localChapterNum
                            case 4: chapterNumber = 42 + localChapterNum
                            case 5: chapterNumber = 56 + localChapterNum
                            case 6: chapterNumber = 68 + localChapterNum
                            default: break
                            }
                            }
                        }
                    }
                    
                    if let chapterNumber = chapterNumber {
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
        // Don't advance if we're already at the end
        guard currentIndex < availableWords.count else {
            // We're already at the end, trigger completion if not already shown
            if case .chapters = _currentLearningMode {
                if !showingChapterCompletion {
                    checkForChapterCompletion()
                }
            } else {
                if !showingPracticeCompletion {
                    endSession()
                }
            }
            return
        }
        
        wordsCompleted += 1
        currentIndex += 1
        
        loadNextWord()
    }
    
    private func checkForChapterCompletion() {
        // When we've gone through all words in a chapter session, show completion
        // regardless of whether the chapter was already marked complete before
        guard case .chapters(let chapters) = _currentLearningMode else { return }
        
        // Get the first selected chapter (usually only one is selected)
        if let chapterId = chapters.first {
            // Show completion if we've practiced all available words in this session
            if wordsCompleted >= availableWords.count && !showingChapterCompletion {
                // Get or create chapter progress
                let progress = progressService.progress.chapterProgress[chapterId] ?? ChapterProgress(
                    chapterId: chapterId,
                    wordsCompleted: [],
                    totalWords: availableWords.count,
                    isCompleted: false,
                    completionDate: nil
                )
                
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
                        wordCount: availableWords.count,
                        isUnlocked: true,
                        icon: chapterInfo.icon
                    )
                    
                    // Get the chapter progress
                    completedChapterProgress = progress
                    
                    // Show completion view
                    showingChapterCompletion = true
                }
            }
        }
    }
    
    func skipWord() {
        if let word = currentWord {
            progressService.recordAnswer(for: word, isCorrect: false)
        }
        wasSkipped = true
        feedbackState = .incorrect
        
        // Auto-advance after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.nextWord()
        }
    }
    
    
    private func endSession() {
        guard wordsCompleted > 0 else { return }
        
        let duration = Date().timeIntervalSince(sessionStartTime ?? Date())
        
        // Always save the session stats
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
        if case .chapters(let chapters) = _currentLearningMode,
           wordsCompleted >= availableWords.count && 
           !showingChapterCompletion {
            // Get the first selected chapter
            if let chapterId = chapters.first {
                // Get or create chapter progress
                let progress = progressService.progress.chapterProgress[chapterId] ?? ChapterProgress(
                    chapterId: chapterId,
                    wordsCompleted: [],
                    totalWords: availableWords.count,
                    isCompleted: false,
                    completionDate: nil
                )
                
                // Get chapter info
                if let chapterNumber = Int(chapterId.replacingOccurrences(of: "chapter_", with: "")) {
                    let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
                    
                    completedChapter = Chapter(
                        id: chapterId,
                        hskLevel: chapterInfo.hskLevel,
                        chapterNumber: chapterNumber,
                        title: chapterInfo.title,
                        description: chapterInfo.description,
                        wordCount: availableWords.count,
                        isUnlocked: true,
                        icon: chapterInfo.icon
                    )
                    
                    completedChapterProgress = progress
                    showingChapterCompletion = true
                }
            }
        } else if !showingChapterCompletion && !showingPracticeCompletion && wordsCompleted > 0 {
            // Show general practice completion for other modes when we've completed all words
            let practiceModeName = getPracticeModeName()
            
            sessionStats = PracticeCompletionView.SessionStats(
                wordsStudied: wordsCompleted,
                correctAnswers: sessionCorrectAnswers,
                totalAttempts: sessionTotalAttempts,
                practiceMode: practiceModeName,
                duration: duration,
                currentStreak: progressService.progress.currentStreak,
                bestStreak: progressService.progress.bestStreak
            )
            
            // Use async to ensure UI updates properly
            DispatchQueue.main.async {
                self.showingPracticeCompletion = true
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
    
    private func getPracticeModeName() -> String {
        if let mode = _currentLearningMode {
            switch mode {
            case .levels(let levels):
                let levelsStr = levels.sorted().map { "HSK \($0)" }.joined(separator: ", ")
                let practiceType = progressService.settings.practiceMode == .random ? "Random Practice" : "Sequential Practice"
                return "\(practiceType) - \(levelsStr)"
            case .chapters:
                return "Chapter Practice"
            case .review:
                return "Review Mistakes"
            }
        }
        return "Practice"
    }
}