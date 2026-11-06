import Foundation
import Testing
@testable import cleanpinyin

@MainActor
@Suite("Practice session flows (SPEC §3–4)", .serialized)
struct PracticeFlowTests {
    private let vocabulary = VocabularyService.shared
    private let progress: UserProgressService
    private let speech = SpeechSpy()
    private let cue = CueSpy()

    init() {
        let suite = "cleanpinyin.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        progress = UserProgressService(defaults: defaults)
    }

    private func makeSession(_ mode: LearningMode, recognizer: SpeechRecognizing? = nil) -> PracticeViewModel {
        PracticeViewModel(
            mode: mode,
            vocabularyService: vocabulary,
            progressService: progress,
            speech: speech,
            recognizer: recognizer,
            listeningCue: cue,
            autoSubmitDelay: 0.05,
            advanceDelay: 0.05,
            listenPollInterval: .milliseconds(10)
        )
    }

    private func answer(for word: VocabularyItem) -> String {
        word.toneNumbers.replacingOccurrences(of: " ", with: "")
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    @Test("PRA-10 each new word's English meaning is read aloud, after the previous answer")
    func meaningIsSpoken() async throws {
        let session = makeSession(.levels([1]))
        session.begin()
        let first = try #require(session.currentWord)
        #expect(speech.spoken == [first.shortTranslation])

        session.userInput = answer(for: first)
        session.checkAnswer()
        try await waitUntil { session.wordsCompleted == 1 }
        let second = try #require(session.currentWord)
        #expect(speech.spoken == [first.shortTranslation, first.simplified, second.shortTranslation])
    }

    @Test("PRA-10 the spoken meaning can be switched off")
    func meaningCanBeSilenced() {
        progress.settings.speakMeaningOnNewWord = false
        let session = makeSession(.levels([1]))
        session.begin()
        #expect(speech.spoken.isEmpty)
    }

    @Test("PRA-2 a correct answer is recorded, spoken and auto-advances")
    func correctAnswerAdvances() async throws {
        let session = makeSession(.levels([1]))
        let first = try #require(session.currentWord)

        session.userInput = answer(for: first)
        session.checkAnswer()

        #expect(session.feedbackState == .correct)
        #expect(progress.progress.learnedWords.contains(first.id))
        #expect(speech.spoken == [first.simplified])

        try await settle()
        #expect(session.currentWord?.id != first.id)
        #expect(session.wordsCompleted == 1)
        #expect(session.feedbackState == .none)
    }

    @Test("ANS-7 a correct answer submits itself; an incomplete one never does")
    func autoSubmitOnlyWhenCorrect() async throws {
        let session = makeSession(.levels([1]))
        let word = try #require(session.currentWord)
        let full = answer(for: word).filter(\.isLetter)

        session.userInput = String(full.dropLast())
        try await settle()
        #expect(session.feedbackState == .none)
        #expect(progress.progress.totalAttempts == 0)

        session.userInput = full
        #expect(session.feedbackState == .none, "submission waits for a pause in typing")
        try await settle()
        #expect(progress.progress.totalAttempts == 1)
        #expect(progress.progress.learnedWords == [word.id])
    }

    @Test("PRA-3 a miss is recorded once and the learner can retype the answer")
    func incorrectThenRetype() async throws {
        let session = makeSession(.levels([1]))
        let word = try #require(session.currentWord)

        session.userInput = "zzz"
        session.checkAnswer()
        session.checkAnswer()
        #expect(session.feedbackState == .incorrect)
        #expect(progress.progress.totalAttempts == 1)
        #expect(progress.progress.incorrectWords == [word.id])

        session.userInput = answer(for: word)
        #expect(session.feedbackState == .correct)

        try await settle()
        #expect(session.currentWord?.id == word.id, "a corrected answer waits for Next")

        session.nextWord()
        #expect(session.currentWord?.id != word.id)
    }

    @Test("TUT-1 each kind of miss is described for the tutor")
    func mistakeKinds() throws {
        progress.settings.requireTones = true
        let session = makeSession(.levels([1]))
        while let word = session.currentWord, !word.toneNumbers.contains(where: { "1234".contains($0) }) {
            session.skipWord()
            session.nextWord()
        }
        let first = try #require(session.currentWord)
        session.userInput = first.toneNumbers.filter(\.isLetter)
        session.checkAnswer()
        #expect(session.lastMistake?.kind == .tone)
        #expect(session.lastMistake?.answer == first.toneNumbers.filter(\.isLetter))

        session.nextWord()
        #expect(session.lastMistake == nil)
        session.userInput = "zzz"
        session.checkAnswer()
        #expect(session.lastMistake?.kind == .spelling)

        session.nextWord()
        session.skipWord()
        #expect(session.lastMistake?.kind == .skipped)
    }

    @Test("PRA-4 skipping counts as a miss and reveals the answer")
    func skip() throws {
        let session = makeSession(.levels([1]))
        let word = try #require(session.currentWord)

        session.skipWord()
        #expect(session.feedbackState == .incorrect)
        #expect(session.wasSkipped)
        #expect(progress.progress.incorrectWords.contains(word.id))
    }

    @Test("PRA-7 finishing a round shows stats and saves the session")
    func finishingSavesSession() throws {
        let chapter = try #require(vocabulary.chaptersForLevel(1).first { $0.wordCount <= 6 })
        let session = makeSession(.chapters([chapter.id]))

        while let word = session.currentWord {
            session.userInput = word.id == session.currentWord?.id && session.wordsCompleted == 0 ? "wrong" : answer(for: word)
            session.checkAnswer()
            session.nextWord()
        }

        let stats = try #require(session.sessionStats)
        #expect(stats.wordsStudied == chapter.wordCount)
        #expect(stats.totalAttempts == chapter.wordCount)
        #expect(stats.correctAnswers == chapter.wordCount - 1)
        #expect(progress.sessions.count == 1)
        #expect(session.showingPracticeCompletion)
    }

    @Test("PRA-8 leaving early saves the session once")
    func leavingEarlySaves() throws {
        let session = makeSession(.levels([1]))
        let word = try #require(session.currentWord)
        session.userInput = answer(for: word)
        session.checkAnswer()
        session.nextWord()

        session.saveSessionOnExit()
        session.saveSessionOnExit()
        #expect(progress.sessions.count == 1)
    }

    @Test("PRA-9 an empty selection has no words instead of a blank session")
    func emptySelection() {
        let session = makeSession(.chapters(["does-not-exist"]))
        #expect(!session.hasWords)
        #expect(session.currentWord == nil)
    }

    @Test("MODE-1 sequential practice continues with words not yet learned")
    func sequentialResumes() throws {
        let levelWords = vocabulary.vocabularyForLevel(1)
        for word in levelWords.prefix(3) {
            progress.recordAnswer(for: word, isCorrect: true, rating: .good)
        }
        let session = makeSession(.levels([1]))
        #expect(session.currentWord?.id == levelWords[3].id)
        #expect(session.totalWords == levelWords.count)
    }

    @Test("MODE-3 custom practice does not change Quick Practice levels or chapter selection")
    func customPracticeIsOneOff() throws {
        progress.settings.selectedHSKLevels = [2]
        progress.settings.selectedChapters = ["chapter1"]
        let chapter = try #require(vocabulary.chaptersForLevel(4).first)

        let session = makeSession(.custom([chapter.id]))
        session.begin()

        #expect(progress.settings.selectedHSKLevels == [2])
        #expect(progress.settings.selectedChapters == ["chapter1"])
        #expect(session.totalWords == chapter.wordCount)
    }

    @Test("REV-3 answers are rated: correct is good, a hint makes it hard, a miss is again")
    func answersAreRated() throws {
        let session = makeSession(.levels([1]))
        let first = try #require(session.currentWord)
        session.userInput = answer(for: first)
        session.checkAnswer()
        session.nextWord()

        let second = try #require(session.currentWord)
        session.markHintUsed()
        session.userInput = answer(for: second)
        session.checkAnswer()
        session.nextWord()

        let third = try #require(session.currentWord)
        session.skipWord()

        let cards = progress.progress.reviewCards
        let scheduler = FSRSScheduler()
        let now = Date()
        #expect(cards[first.id]?.stability == scheduler.review(nil, rating: .good, at: now).stability)
        #expect(cards[second.id]?.stability == scheduler.review(nil, rating: .hard, at: now).stability)
        #expect(cards[third.id]?.stability == scheduler.review(nil, rating: .again, at: now).stability)
        #expect(progress.progress.dueWordIds() == [third.id])
    }

    @Test("REV-3 retyping after a miss does not reschedule the word")
    func correctionKeepsSchedule() throws {
        let session = makeSession(.levels([1]))
        let word = try #require(session.currentWord)
        session.userInput = "zzz"
        session.checkAnswer()
        let afterMiss = progress.progress.reviewCards[word.id]

        session.userInput = answer(for: word)
        #expect(session.feedbackState == .correct)
        #expect(progress.progress.reviewCards[word.id] == afterMiss)
    }

    @Test("MODE-4 review practises each missed word once")
    func reviewMode() throws {
        let words = Array(vocabulary.vocabularyForLevel(1).prefix(3))
        for word in words {
            progress.recordAnswer(for: word, isCorrect: false, rating: .again)
        }
        let session = makeSession(.review)
        #expect(session.totalWords == 3)
    }

    @Test("CH-5 completing a chapter offers the next one and continues there")
    func chapterCompletion() throws {
        let chapters = vocabulary.chaptersForLevel(1)
        let chapter = chapters[0]
        let session = makeSession(.chapters([chapter.id]))
        session.begin()

        while let word = session.currentWord, !session.showingChapterCompletion {
            session.userInput = answer(for: word)
            session.checkAnswer()
            if !session.showingChapterCompletion { session.nextWord() }
        }

        #expect(session.showingChapterCompletion)
        #expect(session.completedChapter == chapter)
        #expect(session.nextChapter == chapters[1])
        #expect(progress.isChapterUnlocked(chapters[1], vocabulary: vocabulary))

        session.continueToNextChapter()
        #expect(session.mode == .chapters([chapters[1].id]))
        #expect(progress.settings.selectedChapters == [chapters[1].id])
        #expect(session.totalWords == chapters[1].wordCount)
    }

    @Test("PROG-6 resetting progress keeps settings")
    func resetKeepsSettings() throws {
        progress.settings.requireTones = true
        progress.recordAnswer(for: try #require(vocabulary.allVocabulary.first), isCorrect: true, rating: .good)
        progress.resetProgress()
        #expect(progress.progress == UserProgress())
        #expect(progress.sessions.isEmpty)
        #expect(progress.settings.requireTones)
    }

    @Test("SAY-5 hands-free voice answers each word in turn without tapping")
    func handsFreeAnswersEachWord() async throws {
        let first = try #require(makeSession(.levels([1])).currentWord)
        let second = vocabulary.vocabularyForLevel(1).first { $0.id != first.id && !progress.progress.learnedWords.contains($0.id) }!
        let recognizer = FakeRecognizer(transcripts: ["\(first.simplified)。", second.simplified])
        let session = makeSession(.levels([1]), recognizer: recognizer)

        await session.startHandsFree()
        #expect(session.isHandsFree)
        #expect(progress.settings.handsFreeVoice)

        try await waitUntil { session.wordsCompleted == 2 }
        #expect(progress.progress.learnedWords.isSuperset(of: [first.id, second.id]))
        #expect(recognizer.acceptedEarly == ["\(first.simplified)。", second.simplified], "the recognizer is told each word's correct answer so it can stop early")
        #expect(session.listeningState != .preparing("Getting ready…"))
        #expect(cue.plays >= 2, "a beep each time the app starts listening for a new word")
    }

    @Test("SAY-6 a heard miss shows and says the answer, then moves on by itself")
    func handsFreeMissMovesOn() async throws {
        let first = try #require(makeSession(.levels([1])).currentWord)
        let second = vocabulary.vocabularyForLevel(1).first { $0.id != first.id }!
        let recognizer = FakeRecognizer(transcripts: ["谢谢", second.simplified])
        progress.settings.speakOnCorrectAnswer = false
        let session = makeSession(.levels([1]), recognizer: recognizer)

        await session.startHandsFree()
        try await waitUntil { session.currentWord?.id == second.id }
        #expect(speech.spoken == [first.simplified], "the correct answer is read aloud after a miss, even with speak-on-correct off")
        #expect(progress.progress.incorrectWords.contains(first.id))

        try await waitUntil { session.wordsCompleted == 2 }
        #expect(progress.progress.learnedWords.contains(second.id))
        #expect(recognizer.acceptedEarly == [second.simplified], "a wrong word is never accepted early")
    }

    @Test("SAY-6 the app does not listen while a missed word is waiting to move on")
    func noListeningDuringMissPause() async throws {
        let recognizer = FakeRecognizer(transcripts: ["谢谢", "的", "的"])
        let session = makeSession(.levels([1]), recognizer: recognizer)
        let first = try #require(session.currentWord)

        await session.startHandsFree()
        try await waitUntil { session.currentWord?.id != first.id }
        #expect(progress.progress.totalAttempts >= 1)
        #expect(progress.progress.reviewCards[first.id]?.lapses == 1)
        #expect(!progress.progress.learnedWords.contains(first.id), "nothing heard during the pause counts for the missed word")
    }

    @Test("SAY-7 repeated silence pauses voice but keeps the preference")
    func handsFreePausesOnSilence() async throws {
        let session = makeSession(.levels([1]), recognizer: FakeRecognizer(transcripts: []))

        await session.startHandsFree()
        try await waitUntil { !session.isHandsFree }

        #expect(session.speechMessage == "Voice paused. Tap the microphone to keep going.")
        #expect(cue.plays == 1, "listening again for the same word doesn't beep again")
        #expect(progress.settings.handsFreeVoice)
        #expect(progress.progress.totalAttempts == 0)
    }

    @Test("SAY-5 the microphone switch turns voice on and off and remembers it")
    func handsFreeToggle() async throws {
        let session = makeSession(.levels([1]), recognizer: FakeRecognizer(transcripts: [], silenceDelay: .seconds(5)))

        await session.toggleHandsFree()
        #expect(session.isHandsFree && progress.settings.handsFreeVoice)

        await session.toggleHandsFree()
        #expect(!session.isHandsFree && !progress.settings.handsFreeVoice)
    }

    @Test("SAY-4 without permission voice stays off and the learner is told why")
    func handsFreeNeedsPermission() async {
        let session = makeSession(.levels([1]), recognizer: FakeRecognizer(transcripts: ["的"], permissionGranted: false))

        await session.startHandsFree()

        #expect(!session.isHandsFree)
        #expect(!progress.settings.handsFreeVoice)
        #expect(progress.progress.totalAttempts == 0)
        #expect(session.speechMessage == SpeechRecognitionError.permissionDenied.errorDescription)
    }

    @Test("SAY-3 a spoken answer is graded and recorded like a typed one")
    func spokenAnswerIsGraded() throws {
        let session = makeSession(.levels([1]))
        let word = try #require(session.currentWord)

        session.submitSpokenAnswer("的。")

        #expect(session.spokenAnswer?.heardText == "的")
        #expect(session.feedbackState == .correct)
        #expect(progress.progress.learnedWords == [word.id])
    }

    private func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else {
                Issue.record("condition not met within \(timeout)")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}

final class FakeRecognizer: SpeechRecognizing {
    private var transcripts: [String]
    private let permissionGranted: Bool
    private let silenceDelay: Duration

    init(transcripts: [String], permissionGranted: Bool = true, silenceDelay: Duration = .milliseconds(20)) {
        self.transcripts = transcripts
        self.permissionGranted = permissionGranted
        self.silenceDelay = silenceDelay
    }

    var isSupported: Bool { true }
    func requestPermission() async -> Bool { permissionGranted }
    func prepare(status: @escaping (String) -> Void) async throws {}
    func stopListening() {}

    private(set) var acceptedEarly: [String] = []

    func listen(isAcceptable: @escaping (String) -> Bool) async throws -> String {
        guard !transcripts.isEmpty else {
            try await Task.sleep(for: silenceDelay)
            throw SpeechRecognitionError.noSpeech
        }
        try await Task.sleep(for: .milliseconds(20))
        let transcript = transcripts.removeFirst()
        // An empty transcript stands for a turn where the learner says nothing
        guard !transcript.isEmpty else { throw SpeechRecognitionError.noSpeech }
        if isAcceptable(transcript) {
            acceptedEarly.append(transcript)
        }
        return transcript
    }
}

final class SpeechSpy: SpeechSpeaking {
    private(set) var spoken: [String] = []
    let isSpeaking = false

    func speak(chinese: String, completion: (() -> Void)?) {
        spoken.append(chinese)
        completion?()
    }

    func speak(english: String, completion: (() -> Void)?) {
        spoken.append(english)
        completion?()
    }

    func speakAfterCurrent(english: String) {
        spoken.append(english)
    }

    func stopSpeaking() {}
}

final class CueSpy: ListeningCueing {
    private(set) var plays = 0
    func playReadyCue() async { plays += 1 }
}
