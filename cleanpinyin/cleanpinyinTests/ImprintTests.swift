import Foundation
import Testing
@testable import cleanpinyin

@MainActor
@Suite("Imprint mode (SPEC §6)", .serialized)
struct ImprintTests {
    private let progress: UserProgressService
    private let speech = SpeechSpy()
    private let background = BackgroundSpy()
    private let cue = CueSpy()
    private let clips = ClipSpy()
    private let vocabulary = FourWordVocabulary()

    init() {
        let suite = "cleanpinyin.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        progress = UserProgressService(defaults: defaults)
    }

    private func makeImprint(recognizer: SpeechRecognizing?) -> ImprintViewModel {
        let imprint = ImprintViewModel(
            vocabularyService: vocabulary,
            progressService: progress,
            speech: speech,
            recognizer: recognizer,
            background: background,
            listeningCue: cue,
            voiceClips: clips,
            pauseBeforeChinese: 0,
            pauseAfterWord: 0,
            answerWindow: .seconds(1)
        )
        imprint.chapters = [FourWordVocabulary.chapterId]
        return imprint
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(3)
        while !condition() {
            guard ContinuousClock.now < deadline else { Issue.record("timed out"); return }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("IMP-1 without answering, each word plays English then Chinese, and nothing is recorded")
    func listeningOnly() async throws {
        let imprint = makeImprint(recognizer: nil)
        await imprint.start()
        try await waitUntil { imprint.playbackState == .completed }

        let words = vocabulary.words
        #expect(speech.spoken == words.flatMap { [$0.shortTranslation, $0.simplified] })
        #expect(progress.progress.totalAttempts == 0)
        #expect(imprint.lastScore == nil)
    }

    @Test("IMP-5 spoken answers are graded silently and feed accuracy and Smart Review")
    func answersAreRecorded() async throws {
        let recognizer = FakeRecognizer(transcripts: ["妈", "你好", "再见", ""])
        recognizer.lastTake = RecordedTake(url: URL(fileURLWithPath: "/tmp/take.caf"), sampleRate: 16_000, voicedFrames: 0...1)
        progress.settings.imprintAnswerAloud = true
        let imprint = makeImprint(recognizer: recognizer)

        await imprint.start()
        try await waitUntil { imprint.playbackState == .completed }

        let score = try #require(imprint.lastScore)
        #expect(score.correct == 1 && score.partial == 1 && score.incorrect == 1 && score.answered == 3)
        #expect(score.accuracy == 1.0 / 3.0)
        #expect(score.missedWordIds == ["马", "谢谢"])

        #expect(progress.progress.learnedWords.contains("你好"))
        #expect(!progress.progress.reviewCards.keys.contains("他"), "an unanswered word is ignored")
        #expect(Set(progress.progress.dueWordIds()).isSuperset(of: ["谢谢"]))
        #expect(progress.sessions.last?.accuracy.rounded() == 33)

        let chinese = speech.spoken.filter { word in vocabulary.words.contains { $0.simplified == word } }
        #expect(chinese == vocabulary.words.map(\.simplified), "every word is still read out, right or wrong")
        #expect(cue.plays == 4, "a beep before each answer window")
        #expect(clips.savedWords == ["你好"], "only the correct answer is kept as the learner's recording")
    }

    @Test("IMP-4 playback runs as a lock-screen session and ends cleanly")
    func backgroundSession() async throws {
        let imprint = makeImprint(recognizer: nil)
        await imprint.start()
        #expect(background.began == [false])
        #expect(background.nowPlayingTitles.first == vocabulary.words[0].shortTranslation)

        imprint.pause()
        #expect(background.pauses == 1)
        #expect(!imprint.isPlaying)

        imprint.stop()
        #expect(background.ended)
    }

    @Test("IMP-5 answering out loud needs microphone permission")
    func permissionDenied() async {
        let imprint = makeImprint(recognizer: FakeRecognizer(transcripts: [], permissionGranted: false))
        await imprint.setAnswerAloud(true)
        #expect(!imprint.answersAloud)
        #expect(imprint.message != nil)
    }
}

final class BackgroundSpy: BackgroundPlaying {
    private(set) var began: [Bool] = []
    private(set) var nowPlayingTitles: [String] = []
    private(set) var pauses = 0
    private(set) var ended = false

    func begin(recording: Bool, controls: BackgroundPlaybackControls) throws { began.append(recording) }
    func showNowPlaying(title: String, subtitle: String, isPlaying: Bool) { nowPlayingTitles.append(title) }
    func pause() { pauses += 1 }
    func end() { ended = true }
}

final class FourWordVocabulary: VocabularyServiceProtocol {
    static let chapterId = "test_chapter"

    let words: [VocabularyItem] = [
        .fixture(simplified: "马", toneNumbers: "ma3", meanings: ["horse"]),
        .fixture(simplified: "你好", toneNumbers: "ni3 hao3", meanings: ["hello"]),
        .fixture(simplified: "谢谢", toneNumbers: "xie4 xie5", meanings: ["thanks"]),
        .fixture(simplified: "他", toneNumbers: "ta1", meanings: ["he"]),
    ]

    var allVocabulary: [VocabularyItem] { words }
    var vocabularyByChapter: [String: [VocabularyItem]] { [Self.chapterId: words] }
    var chapters: [Chapter] {
        [Chapter(id: Self.chapterId, kind: .frequencySet, hskLevel: 1, chapterNumber: 1, title: "Test", description: "", wordCount: words.count, icon: "star")]
    }

    func vocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] { words }
    func vocabularyForLevel(_ level: Int) -> [VocabularyItem] { words }
    func vocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] { chapterIds.contains(Self.chapterId) ? words : [] }
    func words(withIds ids: [String]) -> [VocabularyItem] { words.filter { ids.contains($0.id) } }
    func chaptersForLevel(_ level: Int) -> [Chapter] { chapters }
    func chapter(withId id: String) -> Chapter? { chapters.first { $0.id == id } }
    func nextChapter(after chapter: Chapter) -> Chapter? { nil }
}
