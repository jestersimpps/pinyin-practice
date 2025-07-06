import Foundation
import SwiftUI

class PracticeViewModel: ObservableObject {
    @Published var state = PracticeState()
    @Published var showingChapterCompletion = false
    @Published var showingPracticeCompletion = false
    @Published var completedChapter: Chapter?
    @Published var completedChapterProgress: ChapterProgress?
    @Published var sessionStats: SessionStatistics?
    
    private let wordLoader: WordLoading
    private let inputValidator: InputValidating
    private let chapterProgressManager: ChapterProgressManaging
    private let progressTracker: ProgressTracking
    private let sessionManager: SessionManaging
    private let settingsManager: SettingsManaging
    
    private var sessionStartTime: Date?
    private var autoCheckTimer: Timer?
    
    var currentStreak: Int { progressTracker.currentStreak }
    var accuracy: String { progressTracker.formattedAccuracy }
    
    init(
        wordLoader: WordLoading,
        inputValidator: InputValidating,
        chapterProgressManager: ChapterProgressManaging,
        progressTracker: ProgressTracking,
        sessionManager: SessionManaging,
        settingsManager: SettingsManaging
    ) {
        self.wordLoader = wordLoader
        self.inputValidator = inputValidator
        self.chapterProgressManager = chapterProgressManager
        self.progressTracker = progressTracker
        self.sessionManager = sessionManager
        self.settingsManager = settingsManager
        
        sessionStartTime = sessionManager.startNewSession()
    }
    
    func startPractice(mode: LearningMode) {
        state.learningMode = mode
        loadWords()
    }
    
    func loadNextChapter() {
        guard let currentChapter = completedChapter else { return }
        
        let nextChapterNumber = currentChapter.chapterNumber + 1
        if nextChapterNumber <= ChapterCurriculum.totalChapters {
            let nextChapterId = ChapterIdentifier.fromGlobalNumber(nextChapterNumber)
            settingsManager.updateSettings { settings in
                settings.selectedChapters = [nextChapterId.rawValue]
            }
            loadWords()
        }
    }
    
    func checkAnswer() {
        guard let word = state.currentWord else { return }
        
        let requireTones = settingsManager.settings.requireTones
        state.feedbackState = inputValidator.validateAnswer(state.userInput, for: word, requireTones: requireTones)
        
        state.recordAttempt(isCorrect: state.feedbackState.isCorrect)
        
        let responseTime = state.wordStartTime != nil ? Date().timeIntervalSince(state.wordStartTime!) : 0
        progressTracker.recordWordDifficulty(wordId: word.id, isCorrect: state.feedbackState.isCorrect, responseTime: responseTime)
        progressTracker.recordAnswer(for: word, isCorrect: state.feedbackState.isCorrect)
        
        if case .chapters = state.learningMode {
            handleChapterProgress(for: word, isCorrect: state.feedbackState.isCorrect)
        }
        
        if state.feedbackState.isCorrect {
            scheduleAutoAdvance()
        }
    }
    
    func skipWord() {
        guard let word = state.currentWord else { return }
        
        progressTracker.recordAnswer(for: word, isCorrect: false)
        
        let responseTime = state.wordStartTime != nil ? Date().timeIntervalSince(state.wordStartTime!) : 0
        progressTracker.recordWordDifficulty(wordId: word.id, isCorrect: false, responseTime: responseTime)
        
        if case .chapters = state.learningMode {
            handleChapterProgress(for: word, isCorrect: false)
        }
        
        state.wasSkipped = true
        state.feedbackState = .incorrect
    }
    
    func nextWord() {
        guard state.currentIndex < state.availableWords.count else {
            handlePracticeCompletion()
            return
        }
        
        state.nextWord()
        loadCurrentWord()
    }
    
    func saveSessionOnExit() {
        if state.wordsCompleted > 0 && sessionStartTime != nil {
            endSession()
        }
    }
    
    func reloadWords() {
        loadWords()
    }
    
    private func loadWords() {
        guard let mode = state.learningMode else { return }
        
        state.availableWords = wordLoader.loadWords(for: mode, settings: settingsManager.settings)
        state.reset()
        loadCurrentWord()
    }
    
    private func loadCurrentWord() {
        guard state.currentIndex < state.availableWords.count else {
            handlePracticeCompletion()
            return
        }
        
        state.currentWord = state.availableWords[state.currentIndex]
        state.userInput = ""
        state.showHint = false
        state.feedbackState = .none
        state.wasSkipped = false
        state.wordStartTime = Date()
    }
    
    private func handleChapterProgress(for word: VocabularyItem, isCorrect: Bool) {
        guard case .chapters(let chapters) = state.learningMode,
              let chapterId = chapters.first else { return }
        
        if let completedInfo = chapterProgressManager.updateProgress(for: word, in: chapterId, isCorrect: isCorrect) {
            completedChapter = completedInfo.chapter
            completedChapterProgress = completedInfo.progress
            showingChapterCompletion = true
        }
    }
    
    private func handlePracticeCompletion() {
        if case .chapters = state.learningMode {
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
        guard case .chapters(let chapters) = state.learningMode,
              let chapterId = chapters.first else { return }
        
        if let completedInfo = chapterProgressManager.checkForChapterCompletion(
            chapterId: chapterId,
            wordsCompleted: state.wordsCompleted,
            availableWords: state.availableWords.count
        ) {
            completedChapter = completedInfo.chapter
            completedChapterProgress = completedInfo.progress
            showingChapterCompletion = true
        }
    }
    
    private func endSession() {
        guard state.wordsCompleted > 0 else { return }
        
        let duration = Date().timeIntervalSince(sessionStartTime ?? Date())
        
        if let startTime = sessionStartTime {
            sessionManager.endSession(
                startTime: startTime,
                wordsStudied: state.wordsCompleted,
                correctAnswers: state.sessionCorrectAnswers,
                totalAttempts: state.sessionTotalAttempts
            )
            sessionStartTime = nil
        }
        
        if !showingChapterCompletion && !showingPracticeCompletion && state.wordsCompleted > 0 {
            sessionStats = SessionStatistics(
                wordsStudied: state.wordsCompleted,
                correctAnswers: state.sessionCorrectAnswers,
                totalAttempts: state.sessionTotalAttempts,
                practiceMode: getPracticeModeName(),
                duration: duration,
                currentStreak: progressTracker.currentStreak,
                bestStreak: progressTracker.bestStreak
            )
            
            DispatchQueue.main.async {
                self.showingPracticeCompletion = true
            }
        }
    }
    
    private func scheduleAutoAdvance() {
        let delay = state.isLastWord ? Constants.Practice.lastWordDelay : Constants.Practice.correctAnswerDelay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if !self.showingChapterCompletion {
                self.nextWord()
            }
        }
    }
    
    private func getPracticeModeName() -> String {
        guard let mode = state.learningMode else { return "Practice" }
        
        switch mode {
        case .levels(let levels):
            let levelsStr = levels.sorted().map { "HSK \($0)" }.joined(separator: ", ")
            let practiceType = settingsManager.settings.practiceMode == .random ? "Random Practice" : "Sequential Practice"
            return "\(practiceType) - \(levelsStr)"
        case .chapters:
            return "Chapter Practice"
        case .review:
            return "Review Mistakes"
        }
    }
}