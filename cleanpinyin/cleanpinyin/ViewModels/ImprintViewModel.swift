import Foundation

struct ImprintScore: Equatable {
    var correct = 0
    var partial = 0
    var incorrect = 0
    var silent = 0
    var missedWordIds: [String] = []

    var answered: Int { correct + partial + incorrect }

    var accuracy: Double? {
        answered > 0 ? Double(correct) / Double(answered) : nil
    }
}

@MainActor
final class ImprintViewModel: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentWord: VocabularyItem?
    @Published private(set) var currentIndex = 0
    @Published private(set) var totalWords = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var score = ImprintScore()
    @Published private(set) var lastScore: ImprintScore?
    @Published private(set) var message: String?
    @Published var chapters: Set<String> = []

    enum PlaybackState {
        case idle
        case speakingEnglish
        case listening
        case pausing
        case speakingChinese
        case completed

        var description: String {
            switch self {
            case .idle: return "Ready"
            case .speakingEnglish: return "English"
            case .listening: return "Your turn…"
            case .pausing: return "Think…"
            case .speakingChinese: return "Chinese"
            case .completed: return "Completed"
            }
        }
    }

    private let vocabularyService: VocabularyServiceProtocol
    private let progressService: UserProgressServiceProtocol
    private let speech: SpeechSpeaking
    private let recognizer: SpeechRecognizing?
    private let background: BackgroundPlaying?
    private let spokenChecker = SpokenAnswerChecker()
    private let pauseBeforeChinese: TimeInterval
    private let pauseAfterWord: TimeInterval
    private let answerWindow: Duration
    private var words: [VocabularyItem] = []
    // Invalidates pending playback steps after pause/stop/restart
    private var playbackGeneration = 0
    private var sessionStart: Date?
    private var isRecognizerPrepared = false
    private var listensThisSession = false

    init(
        vocabularyService: VocabularyServiceProtocol = VocabularyService.shared,
        progressService: UserProgressServiceProtocol = UserProgressService.shared,
        speech: SpeechSpeaking = TextToSpeechService.shared,
        recognizer: SpeechRecognizing? = SpeechRecognizerFactory.makeDefault(),
        background: BackgroundPlaying? = BackgroundPlayback.shared,
        pauseBeforeChinese: TimeInterval = 2.0,
        pauseAfterWord: TimeInterval = 1.5,
        answerWindow: Duration = .seconds(5)
    ) {
        self.vocabularyService = vocabularyService
        self.progressService = progressService
        self.speech = speech
        self.recognizer = recognizer
        self.background = background
        self.pauseBeforeChinese = pauseBeforeChinese
        self.pauseAfterWord = pauseAfterWord
        self.answerWindow = answerWindow
    }

    var canAnswerAloud: Bool {
        recognizer != nil
    }

    var answersAloud: Bool {
        canAnswerAloud && progressService.settings.imprintAnswerAloud
    }

    var canResume: Bool {
        !words.isEmpty && currentIndex < words.count && currentWord != nil
    }

    func setAnswerAloud(_ isOn: Bool) async {
        message = nil
        guard isOn, let recognizer else {
            progressService.settings.imprintAnswerAloud = false
            objectWillChange.send()
            return
        }
        let granted = await recognizer.requestPermission()
        progressService.settings.imprintAnswerAloud = granted
        message = granted ? nil : SpeechRecognitionError.permissionDenied.errorDescription
        objectWillChange.send()
    }

    func start() async {
        if !canResume {
            words = vocabularyService.vocabularyForChapters(chapters)
            guard !words.isEmpty else { return }
            currentIndex = 0
            score = ImprintScore()
            sessionStart = Date()
            listensThisSession = await prepareListening()
        }

        totalWords = words.count
        isPlaying = true
        try? background?.begin(recording: listensThisSession, controls: BackgroundPlaybackControls(
            isPlaying: { [weak self] in self?.isPlaying ?? false },
            play: { [weak self] in Task { @MainActor in await self?.start() } },
            pause: { [weak self] in Task { @MainActor in self?.pause() } }
        ))
        playCurrentWord()
    }

    func pause() {
        guard isPlaying else { return }
        playbackGeneration += 1
        isPlaying = false
        playbackState = .idle
        speech.stopSpeaking()
        recognizer?.stopListening()
        background?.pause()
        updateNowPlaying()
    }

    func stop() {
        pause()
        finishSession()
        currentIndex = 0
        progress = 0
        currentWord = nil
        words = []
        background?.end()
    }

    // MARK: - Playback
    private func prepareListening() async -> Bool {
        guard answersAloud, let recognizer else { return false }
        guard !isRecognizerPrepared else { return true }
        do {
            try await recognizer.prepare { [weak self] status in
                Task { @MainActor in self?.message = status }
            }
            isRecognizerPrepared = true
            message = nil
            return true
        } catch {
            message = "Answering out loud isn't available right now, so this session just plays."
            return false
        }
    }

    private func playCurrentWord() {
        guard currentIndex < words.count else {
            completePlayback()
            return
        }

        let word = words[currentIndex]
        currentWord = word
        progress = Double(currentIndex) / Double(totalWords)
        playbackGeneration += 1
        let generation = playbackGeneration
        updateNowPlaying()

        playbackState = .speakingEnglish
        speech.speak(english: word.shortTranslation) { [weak self] in
            self?.step(generation: generation, after: 0) { this in
                if this.listensThisSession {
                    this.listenForAnswer(to: word, generation: generation)
                } else {
                    this.playbackState = .pausing
                    this.step(generation: generation, after: this.pauseBeforeChinese) { this in
                        this.speakChinese(word, generation: generation)
                    }
                }
            }
        }
    }

    private func speakChinese(_ word: VocabularyItem, generation: Int) {
        playbackState = .speakingChinese
        let chinese = progressService.settings.useTraditional ? word.traditional : word.simplified
        speech.speak(chinese: chinese) { [weak self] in
            self?.step(generation: generation, after: self?.pauseAfterWord ?? 0) { this in
                this.currentIndex += 1
                this.playCurrentWord()
            }
        }
    }

    // Nothing is corrected out loud: the answer is graded silently, then the Chinese plays as usual
    private func listenForAnswer(to word: VocabularyItem, generation: Int) {
        guard let recognizer else { return }
        playbackState = .listening
        let checker = spokenChecker
        let window = answerWindow

        Task { @MainActor [weak self] in
            let deadline = Task {
                try await Task.sleep(for: window)
                recognizer.stopListening()
            }
            let heard = try? await recognizer.listen { partial in
                checker.evaluate(transcript: partial, word: word).result == .correct
            }
            deadline.cancel()

            guard let self, self.isPlaying, self.playbackGeneration == generation else { return }
            self.record(heard, for: word)
            self.speakChinese(word, generation: generation)
        }
    }

    private func record(_ heard: String?, for word: VocabularyItem) {
        guard let heard, !heard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            score.silent += 1
            return
        }

        switch spokenChecker.evaluate(transcript: heard, word: word).result {
        case .correct:
            score.correct += 1
            progressService.recordAnswer(for: word, isCorrect: true, rating: .good)
        case .partial:
            score.partial += 1
            score.missedWordIds.append(word.id)
            progressService.recordAnswer(for: word, isCorrect: false, rating: .hard)
        case .incorrect:
            score.incorrect += 1
            score.missedWordIds.append(word.id)
            progressService.recordAnswer(for: word, isCorrect: false, rating: .again)
        }
    }

    private func step(generation: Int, after delay: TimeInterval, action: @escaping (ImprintViewModel) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isPlaying, self.playbackGeneration == generation else { return }
            action(self)
        }
    }

    private func completePlayback() {
        isPlaying = false
        playbackState = .completed
        progress = 1.0
        finishSession()
        words = []
        currentIndex = 0
        background?.end()
    }

    // Spoken sessions count toward accuracy and history like typed ones; listening-only sessions don't
    private func finishSession() {
        defer {
            score = ImprintScore()
            sessionStart = nil
        }
        guard listensThisSession, score.answered + score.silent > 0 else { return }
        lastScore = score
        guard score.answered > 0 else { return }

        let levels = Set(chapters.compactMap { vocabularyService.chapter(withId: $0)?.hskLevel })
        progressService.endSession(
            startTime: sessionStart ?? Date(),
            wordsStudied: score.answered,
            correctAnswers: score.correct,
            totalAttempts: score.answered,
            hskLevels: levels.sorted()
        )
    }

    private func updateNowPlaying() {
        guard let word = currentWord else { return }
        background?.showNowPlaying(
            title: word.shortTranslation,
            subtitle: "EchoLingo Imprint · \(currentIndex + 1) of \(totalWords)",
            isPlaying: isPlaying
        )
    }
}
