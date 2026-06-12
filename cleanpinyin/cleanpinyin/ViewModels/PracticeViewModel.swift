import Foundation
import SwiftUI

class PracticeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userInput: String = "" {
        didSet {
            handleUserInputChange()
        }
    }
    @Published var feedbackState: FeedbackState = .none
    @Published var wasSkipped: Bool = false
    @Published var showingChapterCompletion = false
    @Published var completedChapter: Chapter?
    @Published var completedChapterProgress: ChapterProgress?
    @Published var showingPracticeCompletion = false
    @Published var sessionStats: SessionStats?

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

    private(set) var currentLearningMode: LearningMode?

    // MARK: - Private Properties
    private let vocabularyService = VocabularyService.shared
    private let progressService = UserProgressService.shared
    private let sessionManager = PracticeSessionManager()
    private let wordTracker = WordProgressTracker()
    private let validator = PinyinValidator()
    private let inputDetector = InputCompletionDetector()
    private let chapterHandler = ChapterProgressHandler()
    private let textToSpeech = TextToSpeechService.shared
    private var hasRecordedIncorrectForCurrentWord = false
    private var autoAdvanceWorkItem: DispatchWorkItem?

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
        currentLearningMode = .levels(levels)
        loadWords()
    }

    func startChapterPractice(chapters: Set<String>) {
        currentLearningMode = .chapters(chapters)
        loadWords()
    }

    func startReviewPractice(incorrectWords: Set<String>) {
        currentLearningMode = .review(incorrectWords)
        loadWords()
    }

    func loadNextChapter() {
        guard let currentChapter = completedChapter else { return }

        let nextChapterNumber = currentChapter.chapterNumber + 1
        if nextChapterNumber <= ChapterCurriculum.totalChapters {
            let nextChapterId = ChapterIdentifier(chapterNumber: nextChapterNumber).value
            progressService.settings.selectedChapters = [nextChapterId]
            currentLearningMode = .chapters([nextChapterId])
            loadWords()
        }
    }

    func checkAnswer() {
        guard let word = currentWord else { return }

        let result = validator.validateAnswer(
            input: userInput,
            word: word,
            requireTones: progressService.settings.requireTones
        )

        sessionManager.recordAttempt(isCorrect: result == .correct)
        feedbackState = result.feedbackState

        switch result {
        case .correct:
            handleCorrectAnswer(for: word, autoAdvance: true)
        case .incorrect, .partial:
            handleIncorrectAnswer(for: word)
        }
    }

    func nextWord() {
        autoAdvanceWorkItem?.cancel()

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
        if let word = currentWord, !hasRecordedIncorrectForCurrentWord {
            recordIncorrect(for: word)
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
        let wordsToStudy: [VocabularyItem]

        switch currentLearningMode {
        case .levels(let levels):
            wordsToStudy = vocabularyService.vocabularyForLevels(levels)
        case .chapters(let chapters):
            wordsToStudy = vocabularyService.vocabularyForChapters(chapters)
        case .review(let incorrectWords):
            wordsToStudy = vocabularyService.reviewVocabulary(incorrectWordIds: incorrectWords)
        case nil:
            wordsToStudy = vocabularyService.vocabularyForLevels(settings.selectedHSKLevels)
        }

        wordTracker.setWords(orderWords(wordsToStudy, mode: settings.practiceMode))
        sessionManager.reset()
        resetWordState()
    }

    private func orderWords(_ words: [VocabularyItem], mode: PracticeMode) -> [VocabularyItem] {
        switch mode {
        case .sequential:
            return words.sorted { $0.frequency < $1.frequency }

        case .random:
            let seenWords = progressService.progress.seenWords
            var shuffled = words.shuffled()
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
        autoAdvanceWorkItem?.cancel()
        userInput = ""
        feedbackState = .none
        wasSkipped = false
        hasRecordedIncorrectForCurrentWord = false
        chapterHandler.resetTimer()
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

        let result = validator.validateAnswer(
            input: userInput,
            word: word,
            requireTones: progressService.settings.requireTones
        )

        guard result == .correct else { return }

        feedbackState = .correct

        if hasRecordedIncorrectForCurrentWord {
            progressService.recordAnswer(for: word, isCorrect: true)
            hasRecordedIncorrectForCurrentWord = false
        }

        // Corrected answers count toward chapter progress, but the user advances manually
        handleCorrectAnswer(for: word, autoAdvance: false, recordGlobalAnswer: false)
    }

    private func handleCorrectAnswer(for word: VocabularyItem, autoAdvance: Bool, recordGlobalAnswer: Bool = true) {
        if recordGlobalAnswer {
            progressService.recordAnswer(for: word, isCorrect: true)
        }

        if progressService.settings.speakOnCorrectAnswer {
            speak(word)
        }

        updateChapterProgress(for: word, isCorrect: true)

        if autoAdvance && !showingChapterCompletion {
            scheduleAutoAdvance()
        }
    }

    private func handleIncorrectAnswer(for word: VocabularyItem) {
        guard !hasRecordedIncorrectForCurrentWord else { return }
        recordIncorrect(for: word)
    }

    private func recordIncorrect(for word: VocabularyItem) {
        progressService.recordAnswer(for: word, isCorrect: false)
        hasRecordedIncorrectForCurrentWord = true
        updateChapterProgress(for: word, isCorrect: false)
    }

    private func speak(_ word: VocabularyItem) {
        textToSpeech.speak(chinese: progressService.settings.useTraditional ? word.traditional : word.simplified)
    }

    private func scheduleAutoAdvance() {
        let delay: TimeInterval = isLastWord ? AppConstants.Timing.lastWordAdvanceDelay : AppConstants.Timing.correctAnswerAdvanceDelay

        autoAdvanceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.showingChapterCompletion else { return }
            self.nextWord()
        }
        autoAdvanceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func updateChapterProgress(for word: VocabularyItem, isCorrect: Bool) {
        guard case .chapters(let activeChapters) = currentLearningMode else { return }

        let completedChapterId = chapterHandler.recordAttempt(
            for: word,
            isCorrect: isCorrect,
            activeChapters: activeChapters,
            vocabularyByChapter: vocabularyService.vocabularyByChapter,
            progressService: progressService
        )

        if let completedChapterId {
            presentChapterCompletion(chapterId: completedChapterId)
        }
    }

    private func checkForCompletion() {
        guard wordsCompleted > 0, !showingChapterCompletion, !showingPracticeCompletion else { return }

        if case .chapters(let chapters) = currentLearningMode,
           chapters.count == 1,
           let chapterId = chapters.first,
           progressService.getChapterProgress(chapterId: chapterId)?.isCompleted == true {
            presentChapterCompletion(chapterId: chapterId)
            return
        }

        sessionManager.endSession(progressService: progressService)
        sessionStats = sessionManager.getSessionStats(
            practiceModeName: practiceModeName(),
            currentStreak: progressService.progress.currentStreak,
            bestStreak: progressService.progress.bestStreak
        )

        DispatchQueue.main.async {
            self.showingPracticeCompletion = true
        }
    }

    private func presentChapterCompletion(chapterId: String) {
        guard let chapter = vocabularyService.chapters.first(where: { $0.id == chapterId }) else { return }

        completedChapter = chapter
        completedChapterProgress = progressService.getChapterProgress(chapterId: chapterId)
        showingChapterCompletion = true
    }

    private func practiceModeName() -> String {
        switch currentLearningMode {
        case .levels(let levels):
            let levelsStr = levels.sorted().map { "HSK \($0)" }.joined(separator: ", ")
            let practiceType = progressService.settings.practiceMode == .random ? "Random Practice" : "Sequential Practice"
            return "\(practiceType) - \(levelsStr)"
        case .chapters:
            return "Chapter Practice"
        case .review:
            return "Review Mistakes"
        case nil:
            return "Practice"
        }
    }
}
