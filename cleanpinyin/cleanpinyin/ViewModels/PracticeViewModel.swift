import Foundation
import SwiftUI

class PracticeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userInput: String = "" {
        didSet {
            handleUserInputChange()
        }
    }
    @Published var showHint: Bool = false
    @Published var feedbackState: FeedbackState = .none
    @Published var wasSkipped: Bool = false
    @Published var showingChapterCompletion = false
    @Published var completedChapter: Chapter?
    @Published var completedChapterProgress: ChapterProgress?
    @Published var showingPracticeCompletion = false
    @Published var sessionStats: PracticeCompletionView.SessionStats?
    
    // MARK: - Computed Properties
    var currentWord: VocabularyItem? {
        wordTracker.currentWord
    }
    
    var wordsCompleted: Int {
        sessionManager.wordsCompleted
    }
    
    var totalWords: Int {
        wordTracker.totalWords
    }
    
    var progressPercentage: Double {
        wordTracker.progressPercentage
    }
    
    var isPracticeComplete: Bool {
        wordTracker.isPracticeComplete
    }
    
    var isLastWord: Bool {
        wordTracker.isLastWord
    }
    
    var currentStreak: Int {
        progressService.progress.currentStreak
    }
    
    var accuracy: String {
        progressService.progress.formattedAccuracy
    }
    
    var currentLearningMode: LearningMode? {
        _currentLearningMode
    }
    
    // MARK: - Private Properties
    private let vocabularyService = VocabularyService.shared
    private let progressService = UserProgressService.shared
    private let sessionManager = PracticeSessionManager()
    private let wordTracker = WordProgressTracker()
    private let validator = PinyinValidator()
    private let inputDetector = InputCompletionDetector()
    private let chapterHandler = ChapterProgressHandler()
    private var _currentLearningMode: LearningMode?
    
    // MARK: - Initialization
    init() {
        loadWords()
        _ = sessionManager.startNewSession()
    }
    
    // MARK: - Public Methods
    func reloadWordsIfNeeded() {
        _ = sessionManager.startNewSession()
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
        
        let nextChapterNumber = currentChapter.chapterNumber + 1
        if nextChapterNumber <= ChapterCurriculum.totalChapters {
            progressService.settings.selectedChapters = ["chapter_\(nextChapterNumber)"]
            loadWords()
        }
    }
    
    func checkAnswer() {
        guard let word = currentWord else { return }
        
        let requireTones = progressService.settings.requireTones
        let result = validator.validateAnswer(
            input: userInput,
            word: word,
            requireTones: requireTones
        )
        
        sessionManager.recordAttempt(isCorrect: result == .correct)
        feedbackState = result.feedbackState
        
        switch result {
        case .correct:
            handleCorrectAnswer(for: word)
        case .incorrect, .partial:
            handleIncorrectAnswer(for: word)
        }
    }
    
    func nextWord() {
        guard !wordTracker.isPracticeComplete else {
            checkForCompletion()
            return
        }
        
        sessionManager.recordWordCompletion()
        
        if wordTracker.moveToNextWord() {
            resetWordState()
        } else {
            checkForCompletion()
        }
    }
    
    func skipWord() {
        if let word = currentWord {
            progressService.recordAnswer(for: word, isCorrect: false)
        }
        wasSkipped = true
        feedbackState = .incorrect
    }
    
    func saveSessionOnExit() {
        if wordsCompleted > 0 {
            sessionManager.endSession(progressService: progressService)
        }
    }
    
    // MARK: - Private Methods
    private func loadWords() {
        let settings = progressService.settings
        var wordsToStudy: [VocabularyItem] = []
        
        if let learningMode = _currentLearningMode {
            switch learningMode {
            case .levels(let levels):
                wordsToStudy = vocabularyService.vocabularyForLevels(levels)
            case .chapters(let chapters):
                wordsToStudy = vocabularyService.vocabularyForChapters(chapters)
            case .review(let incorrectWords):
                wordsToStudy = vocabularyService.reviewVocabulary(incorrectWordIds: incorrectWords)
            }
        } else {
            wordsToStudy = vocabularyService.vocabularyForLevels(settings.selectedHSKLevels)
        }
        
        let orderedWords = orderWords(wordsToStudy, mode: settings.practiceMode)
        wordTracker.setWords(orderedWords)
        sessionManager.reset()
        resetWordState()
    }
    
    private func orderWords(_ words: [VocabularyItem], mode: PracticeMode) -> [VocabularyItem] {
        switch mode {
        case .sequential:
            return words.sorted { $0.frequency < $1.frequency }
            
        case .random:
            var shuffled = words.shuffled()
            let seenWords = progressService.progress.seenWords
            
            shuffled.sort { word1, word2 in
                let word1Seen = seenWords.contains(word1.id)
                let word2Seen = seenWords.contains(word2.id)
                
                if word1Seen == word2Seen { return false }
                return !word1Seen && word2Seen
            }
            
            return shuffled
        }
    }
    
    private func resetWordState() {
        userInput = ""
        showHint = false
        feedbackState = .none
        wasSkipped = false
    }
    
    private func handleUserInputChange() {
        checkForAutoSubmit()
        checkForCorrectAnswerAfterIncorrect()
    }
    
    private func checkForAutoSubmit() {
        guard let word = currentWord else { return }
        
        inputDetector.checkForAutoSubmit(
            input: userInput,
            word: word,
            requireTones: progressService.settings.requireTones,
            feedbackState: feedbackState,
            onSubmit: { [weak self] in
                self?.checkAnswer()
            }
        )
    }
    
    private func checkForCorrectAnswerAfterIncorrect() {
        guard feedbackState == .incorrect || feedbackState == .partial,
              let word = currentWord else { return }
        
        let requireTones = progressService.settings.requireTones
        let result = validator.validateAnswer(
            input: userInput,
            word: word,
            requireTones: requireTones
        )
        
        if result == .correct {
            feedbackState = .correct
        }
    }
    
    private func handleCorrectAnswer(for word: VocabularyItem) {
        progressService.recordAnswer(for: word, isCorrect: true)
        
        if case .chapters = _currentLearningMode {
            updateChapterProgress(for: word)
            
            if showingChapterCompletion {
                return
            }
        }
        
        scheduleAutoAdvance()
    }
    
    private func handleIncorrectAnswer(for word: VocabularyItem) {
        progressService.recordAnswer(for: word, isCorrect: false)
    }
    
    private func scheduleAutoAdvance() {
        let delay: TimeInterval = isLastWord ? AppConstants.Timing.lastWordAdvanceDelay : AppConstants.Timing.correctAnswerAdvanceDelay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  !self.showingChapterCompletion else { return }
            self.nextWord()
        }
    }
    
    private func updateChapterProgress(for word: VocabularyItem) {
        let result = chapterHandler.handleChapterProgress(
            for: word,
            vocabularyByChapter: vocabularyService.vocabularyByChapter,
            progressService: progressService
        )
        
        if result.wasCompleted {
            completedChapter = result.chapter
            completedChapterProgress = result.progress
            showingChapterCompletion = true
        }
    }
    
    private func checkForCompletion() {
        if case .chapters = _currentLearningMode {
            if !showingChapterCompletion {
                checkForChapterCompletion()
            }
        } else {
            if !showingPracticeCompletion {
                endSession()
            }
        }
    }
    
    private func checkForChapterCompletion() {
        guard case .chapters(let chapters) = _currentLearningMode else { return }
        
        if let chapterId = chapters.first,
           wordsCompleted >= totalWords && !showingChapterCompletion {
            
            let progress = progressService.progress.chapterProgress[chapterId] ?? ChapterProgress(
                chapterId: chapterId,
                wordsCompleted: [],
                totalWords: totalWords,
                isCompleted: false,
                completionDate: nil
            )
            
            if let chapterNumber = chapterHandler.parseChapterNumber(from: chapterId) {
                completedChapter = chapterHandler.createChapter(
                    chapterId: chapterId,
                    chapterNumber: chapterNumber,
                    wordCount: totalWords
                )
                completedChapterProgress = progress
                showingChapterCompletion = true
            }
        }
    }
    
    private func endSession() {
        guard wordsCompleted > 0 else { return }
        
        sessionManager.endSession(progressService: progressService)
        
        if case .chapters(let chapters) = _currentLearningMode,
           wordsCompleted >= totalWords && !showingChapterCompletion {
            
            if let chapterId = chapters.first {
                let progress = progressService.progress.chapterProgress[chapterId] ?? ChapterProgress(
                    chapterId: chapterId,
                    wordsCompleted: [],
                    totalWords: totalWords,
                    isCompleted: false,
                    completionDate: nil
                )
                
                if let chapterNumber = chapterHandler.parseChapterNumber(from: chapterId) {
                    completedChapter = chapterHandler.createChapter(
                        chapterId: chapterId,
                        chapterNumber: chapterNumber,
                        wordCount: totalWords
                    )
                    completedChapterProgress = progress
                    showingChapterCompletion = true
                }
            }
        } else if !showingChapterCompletion && !showingPracticeCompletion && wordsCompleted > 0 {
            let practiceModeName = getPracticeModeName()
            sessionStats = sessionManager.getSessionStats(
                practiceModeName: practiceModeName,
                currentStreak: progressService.progress.currentStreak,
                bestStreak: progressService.progress.bestStreak
            )
            
            DispatchQueue.main.async {
                self.showingPracticeCompletion = true
            }
        }
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