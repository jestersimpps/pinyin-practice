import Foundation
import Testing
@testable import cleanpinyin

@MainActor
@Suite("Practice session flows (SPEC §3–4)", .serialized)
struct PracticeFlowTests {
    private let vocabulary = VocabularyService.shared
    private let progress: UserProgressService
    private let speech = SpeechSpy()

    init() {
        let suite = "cleanpinyin.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        progress = UserProgressService(defaults: defaults)
    }

    private func makeSession(_ mode: LearningMode) -> PracticeViewModel {
        PracticeViewModel(
            mode: mode,
            vocabularyService: vocabulary,
            progressService: progress,
            speech: speech,
            autoSubmitDelay: 0.05,
            advanceDelay: 0.05
        )
    }

    private func answer(for word: VocabularyItem) -> String {
        word.toneNumbers.replacingOccurrences(of: " ", with: "")
    }

    private func settle() async throws {
        try await Task.sleep(for: .milliseconds(200))
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
            progress.recordAnswer(for: word, isCorrect: true)
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

    @Test("MODE-4 review practises each missed word once")
    func reviewMode() throws {
        let words = Array(vocabulary.vocabularyForLevel(1).prefix(3))
        for word in words {
            progress.recordAnswer(for: word, isCorrect: false)
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
        progress.recordAnswer(for: try #require(vocabulary.allVocabulary.first), isCorrect: true)
        progress.resetProgress()
        #expect(progress.progress == UserProgress())
        #expect(progress.sessions.isEmpty)
        #expect(progress.settings.requireTones)
    }
}

final class SpeechSpy: SpeechSpeaking {
    private(set) var spoken: [String] = []

    func speak(chinese: String, completion: (() -> Void)?) {
        spoken.append(chinese)
        completion?()
    }

    func speak(english: String, completion: (() -> Void)?) {
        spoken.append(english)
        completion?()
    }

    func stopSpeaking() {}
}
