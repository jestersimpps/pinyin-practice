import Foundation

final class PracticeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userInput: String = "" {
        didSet { handleUserInputChange() }
    }
    @Published private(set) var feedbackState: FeedbackState = .none
    @Published private(set) var wasSkipped = false
    @Published var showingChapterCompletion = false
    @Published private(set) var completedChapter: Chapter?
    @Published private(set) var completedChapterProgress: ChapterProgress?
    @Published var showingPracticeCompletion = false
    @Published private(set) var sessionStats: SessionStats?
    @Published private(set) var mode: LearningMode
    @Published private(set) var listeningState: ListeningState = .idle
    @Published private(set) var spokenAnswer: SpokenAnswer?
    @Published var speechMessage: String?
    @Published private(set) var isHandsFree = false
    @Published private(set) var lastMistake: MistakeContext?

    enum ListeningState: Equatable {
        case idle
        case preparing(String)
        case listening
    }

    // MARK: - Computed Properties
    var currentWord: VocabularyItem? { wordTracker.currentWord }
    var wordsCompleted: Int { sessionManager.wordsCompleted }
    var totalWords: Int { wordTracker.totalWords }
    var progressPercentage: Double { wordTracker.progressPercentage }
    var isPracticeComplete: Bool { wordTracker.isPracticeComplete }
    var hasWords: Bool { totalWords > 0 }
    var combo: Int { sessionManager.combo }
    var accuracy: String { progressService.progress.formattedAccuracy }
    var settings: PracticeSettings { progressService.settings }
    var canAnswerBySpeaking: Bool { recognizer != nil }

    var nextChapter: Chapter? {
        completedChapter.flatMap { vocabularyService.nextChapter(after: $0) }
    }

    // MARK: - Dependencies
    private let vocabularyService: VocabularyServiceProtocol
    private let progressService: UserProgressServiceProtocol
    private let speech: SpeechSpeaking?
    private let recognizer: SpeechRecognizing?
    private let spokenChecker = SpokenAnswerChecker()
    private let listenPollInterval: Duration
    private let maximumSilentListens = 3
    private var handsFreeTask: Task<Void, Never>?
    private var isRecognizerPrepared = false
    private var advancePending = false
    private let sessionManager = PracticeSessionManager()
    private let wordTracker = WordProgressTracker()
    private let validator = PinyinValidator()
    private let chapterHandler = ChapterProgressHandler()
    private let autoSubmitDelay: TimeInterval
    private let advanceDelay: TimeInterval

    private var hasRecordedIncorrectForCurrentWord = false
    private var usedHintForCurrentWord = false
    private var autoSubmitWorkItem: DispatchWorkItem?
    private var autoAdvanceWorkItem: DispatchWorkItem?

    // MARK: - Initialization
    init(
        mode: LearningMode,
        vocabularyService: VocabularyServiceProtocol = VocabularyService.shared,
        progressService: UserProgressServiceProtocol = UserProgressService.shared,
        speech: SpeechSpeaking? = TextToSpeechService.shared,
        recognizer: SpeechRecognizing? = SpeechRecognizerFactory.makeDefault(),
        autoSubmitDelay: TimeInterval = AppConstants.Timing.autoSubmitDelay,
        advanceDelay: TimeInterval = AppConstants.Timing.correctAnswerAdvanceDelay,
        listenPollInterval: Duration = .milliseconds(100)
    ) {
        self.mode = mode
        self.vocabularyService = vocabularyService
        self.progressService = progressService
        self.speech = speech
        self.recognizer = recognizer
        self.autoSubmitDelay = autoSubmitDelay
        self.advanceDelay = advanceDelay
        self.listenPollInterval = listenPollInterval
        startRound()
    }

    // MARK: - Public Methods
    func begin() {
        progressService.settings.lastPracticeMode = mode.lastPracticeMode
        if case .chapters(let ids) = mode {
            progressService.settings.selectedChapters = ids
        }
    }

    func startNewRound() {
        showingPracticeCompletion = false
        showingChapterCompletion = false
        startRound()
    }

    func continueToNextChapter() {
        guard let next = nextChapter else { return }
        mode = .chapters([next.id])
        begin()
        startNewRound()
    }

    func checkAnswer() {
        guard let word = currentWord, feedbackState == .none else { return }
        autoSubmitWorkItem?.cancel()

        let result = validator.validateAnswer(input: userInput, word: word, requireTones: settings.requireTones)
        apply(result, for: word)
    }

    func submitSpokenAnswer(_ transcript: String) {
        guard let word = currentWord, feedbackState == .none else { return }
        autoSubmitWorkItem?.cancel()

        let spoken = spokenChecker.evaluate(transcript: transcript, word: word)
        spokenAnswer = spoken
        apply(spoken.result, for: word)

        if spoken.result != .correct {
            revealAnswerAndMoveOn(for: word)
        }
    }

    // A heard miss says the right answer aloud, then moves on once it has been spoken
    private func revealAnswerAndMoveOn(for word: VocabularyItem) {
        scheduleAutoAdvance(delayMultiplier: AppConstants.Timing.spokenMissFallbackMultiplier)
        guard let speech else { return }

        speech.speak(chinese: displayText(for: word)) { [weak self] in
            guard let self, self.currentWord?.id == word.id, self.feedbackState != .none else { return }
            self.scheduleAutoAdvance(delayMultiplier: AppConstants.Timing.afterAnswerSpokenMultiplier)
        }
    }

    // Hands-free voice: once on, the app listens for every word until switched off or it hears silence too often
    @MainActor
    func toggleHandsFree() async {
        if isHandsFree {
            stopHandsFree()
            progressService.settings.handsFreeVoice = false
        } else {
            await startHandsFree()
        }
    }

    @MainActor
    func startHandsFree() async {
        guard let recognizer, !isHandsFree else { return }
        speechMessage = nil
        guard await recognizer.requestPermission() else {
            speechMessage = SpeechRecognitionError.permissionDenied.errorDescription
            progressService.settings.handsFreeVoice = false
            return
        }

        progressService.settings.handsFreeVoice = true
        isHandsFree = true
        handsFreeTask?.cancel()
        handsFreeTask = Task { @MainActor [weak self] in
            await self?.runHandsFreeLoop()
        }
    }

    func stopHandsFree() {
        isHandsFree = false
        handsFreeTask?.cancel()
        handsFreeTask = nil
        recognizer?.stopListening()
        listeningState = .idle
    }

    @MainActor
    private func runHandsFreeLoop() async {
        var silentListens = 0

        while isHandsFree, !Task.isCancelled {
            guard let word = currentWord else {
                stopHandsFree()
                return
            }
            guard canListenNow else {
                try? await Task.sleep(for: listenPollInterval)
                continue
            }

            try? await Task.sleep(for: listenPollInterval)
            guard isHandsFree, canListenNow, currentWord?.id == word.id else { continue }

            do {
                let transcript = try await listenForAnswer()
                silentListens = 0
                guard isHandsFree, currentWord?.id == word.id else { continue }
                handleHeard(transcript, for: word)
            } catch SpeechRecognitionError.noSpeech {
                guard isHandsFree, currentWord?.id == word.id, feedbackState != .correct else { continue }
                silentListens += 1
                if silentListens >= maximumSilentListens {
                    stopHandsFree()
                    speechMessage = "Voice paused. Tap the microphone to keep going."
                    return
                }
            } catch {
                guard isHandsFree, !Task.isCancelled else { return }
                stopHandsFree()
                speechMessage = (error as? LocalizedError)?.errorDescription ?? SpeechRecognitionError.unavailable.errorDescription
                return
            }
        }
    }

    // Never listen while the app is talking, a correct answer is on screen, or a summary sheet is up
    private var canListenNow: Bool {
        feedbackState != .correct
            && !advancePending
            && !showingChapterCompletion
            && !showingPracticeCompletion
            && speech?.isSpeaking != true
    }

    @MainActor
    private func listenForAnswer() async throws -> String {
        guard let recognizer else { throw SpeechRecognitionError.unavailable }
        if !isRecognizerPrepared {
            listeningState = .preparing("Getting ready…")
            try await recognizer.prepare { [weak self] status in
                Task { @MainActor in self?.listeningState = .preparing(status) }
            }
            isRecognizerPrepared = true
        }

        guard let word = currentWord else { throw SpeechRecognitionError.noSpeech }
        let checker = spokenChecker
        listeningState = .listening
        defer { listeningState = .idle }
        // Stop the moment the correct word is heard instead of waiting for the speaker to fall silent
        return try await recognizer.listen { partial in
            checker.evaluate(transcript: partial, word: word).result == .correct
        }
    }

    private func handleHeard(_ transcript: String, for word: VocabularyItem) {
        switch feedbackState {
        case .none:
            submitSpokenAnswer(transcript)
        case .incorrect, .partial:
            let spoken = spokenChecker.evaluate(transcript: transcript, word: word)
            spokenAnswer = spoken
            if spoken.result == .correct {
                acceptCorrection(for: word)
                scheduleAutoAdvance()
            }
        case .correct:
            break
        }
    }

    func nextWord() {
        autoAdvanceWorkItem?.cancel()
        autoSubmitWorkItem?.cancel()
        guard currentWord != nil else { return }

        sessionManager.recordWordCompletion()
        if wordTracker.moveToNextWord() {
            resetWordState()
        } else {
            finishRound()
        }
    }

    func skipWord() {
        guard let word = currentWord, feedbackState == .none else { return }
        autoSubmitWorkItem?.cancel()
        sessionManager.recordAttempt(isCorrect: false)
        recordIncorrect(for: word, rating: .again)
        lastMistake = MistakeContext(word: word, answer: "", kind: .skipped)
        wasSkipped = true
        feedbackState = .incorrect
    }

    func speakCurrentWord() {
        guard let word = currentWord else { return }
        speech?.speak(chinese: displayText(for: word))
    }

    func saveSessionOnExit() {
        autoSubmitWorkItem?.cancel()
        autoAdvanceWorkItem?.cancel()
        stopHandsFree()
        sessionManager.endSession(progressService: progressService, hskLevels: sessionLevels)
    }

    func markHintUsed() {
        usedHintForCurrentWord = true
    }

    func speak(chinese text: String) {
        speech?.speak(chinese: text)
    }

    var currentHSKLevel: Int {
        guard let word = currentWord else { return 1 }
        return PracticeSettings.hskLevels.first { level in
            vocabularyService.vocabularyForLevel(level).contains { $0.id == word.id }
        } ?? 1
    }

    func displayText(for word: VocabularyItem) -> String {
        settings.useTraditional ? word.traditional : word.simplified
    }

    // MARK: - Round lifecycle
    private func startRound() {
        sessionManager.endSession(progressService: progressService, hskLevels: sessionLevels)
        sessionStats = nil
        completedChapter = nil
        completedChapterProgress = nil
        wordTracker.setWords(orderedWords(for: mode))
        sessionManager.startNewSession()
        resetWordState()
    }

    private func finishRound() {
        if case .chapters(let ids) = mode, ids.count == 1, let chapterId = ids.first,
           progressService.getChapterProgress(chapterId: chapterId)?.isCompleted == true,
           completedChapter == nil {
            presentChapterCompletion(chapterId: chapterId)
        }

        sessionStats = sessionManager.getSessionStats(practiceModeName: practiceModeName)
        sessionManager.endSession(progressService: progressService, hskLevels: sessionLevels)

        if !showingChapterCompletion, sessionStats != nil {
            showingPracticeCompletion = true
        }
    }

    private func orderedWords(for mode: LearningMode) -> [VocabularyItem] {
        let words: [VocabularyItem]
        switch mode {
        case .levels(let levels):
            words = vocabularyService.vocabularyForLevels(levels)
        case .chapters(let ids), .custom(let ids):
            words = vocabularyService.vocabularyForChapters(ids)
        case .review:
            return vocabularyService.words(withIds: progressService.progress.dueWordIds(at: Date()))
        }

        let progress = progressService.progress
        switch settings.practiceMode {
        case .sequential:
            let byFrequency = words.sorted { $0.frequency < $1.frequency }
            let unlearned = byFrequency.filter { !progress.learnedWords.contains($0.id) }
            let learned = byFrequency.filter { progress.learnedWords.contains($0.id) }
            return unlearned + learned
        case .random:
            let shuffled = words.shuffled()
            return shuffled.filter { !progress.seenWords.contains($0.id) }
                + shuffled.filter { progress.seenWords.contains($0.id) }
        }
    }

    private func resetWordState() {
        autoSubmitWorkItem?.cancel()
        autoAdvanceWorkItem?.cancel()
        recognizer?.stopListening()
        spokenAnswer = nil
        speechMessage = nil
        lastMistake = nil
        userInput = ""
        feedbackState = .none
        wasSkipped = false
        hasRecordedIncorrectForCurrentWord = false
        usedHintForCurrentWord = false
        advancePending = false
        chapterHandler.resetTimer()
    }

    // MARK: - Input handling
    private func handleUserInputChange() {
        autoSubmitWorkItem?.cancel()
        guard let word = currentWord, !userInput.isEmpty else { return }

        let result = validator.validateAnswer(input: userInput, word: word, requireTones: settings.requireTones)

        switch feedbackState {
        case .none where result == .correct:
            scheduleAutoSubmit()
        case .incorrect where result == .correct, .partial where result == .correct:
            acceptCorrection(for: word)
        default:
            break
        }
    }

    private func scheduleAutoSubmit() {
        let workItem = DispatchWorkItem { [weak self] in self?.checkAnswer() }
        autoSubmitWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoSubmitDelay, execute: workItem)
    }

    // A retyped answer after a miss turns green and counts toward the chapter, but the learner advances manually
    private func acceptCorrection(for word: VocabularyItem) {
        feedbackState = .correct
        if hasRecordedIncorrectForCurrentWord {
            progressService.recordAnswer(for: word, isCorrect: true, rating: nil)
            hasRecordedIncorrectForCurrentWord = false
        }
        if settings.speakOnCorrectAnswer {
            speech?.speak(chinese: displayText(for: word))
        }
        updateChapterProgress(for: word, isCorrect: true)
    }

    // MARK: - Answer outcomes
    private func apply(_ result: AnswerValidationResult, for word: VocabularyItem) {
        sessionManager.recordAttempt(isCorrect: result == .correct)
        feedbackState = result.feedbackState

        if result == .correct {
            handleCorrectAnswer(for: word)
        } else {
            lastMistake = MistakeContext(
                word: word,
                answer: spokenAnswer?.heardPinyin ?? userInput,
                kind: result == .partial ? .tone : .spelling
            )
            recordIncorrect(for: word, rating: result == .partial ? .hard : .again)
        }
    }

    private func handleCorrectAnswer(for word: VocabularyItem) {
        progressService.recordAnswer(for: word, isCorrect: true, rating: usedHintForCurrentWord ? .hard : .good)
        if settings.speakOnCorrectAnswer {
            speech?.speak(chinese: displayText(for: word))
        }
        updateChapterProgress(for: word, isCorrect: true)

        if !showingChapterCompletion {
            scheduleAutoAdvance()
        }
    }

    private func recordIncorrect(for word: VocabularyItem, rating: ReviewRating) {
        guard !hasRecordedIncorrectForCurrentWord else { return }
        progressService.recordAnswer(for: word, isCorrect: false, rating: rating)
        hasRecordedIncorrectForCurrentWord = true
        updateChapterProgress(for: word, isCorrect: false)
    }

    private func scheduleAutoAdvance(delayMultiplier: Double = 1) {
        autoAdvanceWorkItem?.cancel()
        let base = advanceDelay * delayMultiplier
        let delay = wordTracker.isLastWord ? base * 1.5 : base
        advancePending = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.showingChapterCompletion else { return }
            self.nextWord()
        }
        autoAdvanceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    // MARK: - Chapters
    private func updateChapterProgress(for word: VocabularyItem, isCorrect: Bool) {
        let activeChapters = mode.chapterIds
        guard !activeChapters.isEmpty else { return }

        let completedChapterId = chapterHandler.recordAttempt(
            for: word,
            isCorrect: isCorrect,
            activeChapters: activeChapters,
            vocabularyByChapter: vocabularyService.vocabularyByChapter,
            progressService: progressService
        )

        if let completedChapterId {
            autoAdvanceWorkItem?.cancel()
            presentChapterCompletion(chapterId: completedChapterId)
        }
    }

    private func presentChapterCompletion(chapterId: String) {
        guard let chapter = vocabularyService.chapter(withId: chapterId) else { return }
        completedChapter = chapter
        completedChapterProgress = progressService.getChapterProgress(chapterId: chapterId)
        showingChapterCompletion = true
    }

    // MARK: - Labels
    private var sessionLevels: [Int] {
        switch mode {
        case .levels(let levels):
            return levels.sorted()
        case .chapters(let ids), .custom(let ids):
            return Array(Set(ids.compactMap { vocabularyService.chapter(withId: $0)?.hskLevel })).sorted()
        case .review:
            return []
        }
    }

    private var practiceModeName: String {
        switch mode {
        case .levels(let levels):
            let levelNames = levels.sorted().map { "HSK \($0)" }.joined(separator: ", ")
            return settings.practiceMode == .random ? "Random · \(levelNames)" : levelNames
        case .chapters:
            return "Chapter Practice"
        case .custom:
            return "Custom Practice"
        case .review:
            return "Smart Review"
        }
    }
}
