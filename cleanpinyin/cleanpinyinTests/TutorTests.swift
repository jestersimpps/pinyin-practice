import Foundation
import Testing
@testable import cleanpinyin

@Suite("AI tutor (SPEC §11)")
struct TutorFilterTests {
    private let word = VocabularyItem.fixture(simplified: "喜欢", toneNumbers: "xi3 huan5", meanings: ["to like"])

    @Test("TUT-3 keeps sentences that use the word and derives their pinyin")
    func keepsValidSentences() {
        let sentences = ExampleSentenceFilter.validated([("我喜欢茶。", "I like tea.")], for: word)
        #expect(sentences == [ExampleSentence(chinese: "我喜欢茶。", pinyin: ChineseTransliterator.pinyin(for: "我喜欢茶。"), english: "I like tea.")])
        #expect(sentences.first?.pinyin.hasPrefix("wǒ xǐ hu") == true)
    }

    @Test("TUT-3 drops sentences that miss the word, contain Latin letters, run long or repeat")
    func dropsInvalidSentences() {
        let raw: [(chinese: String, english: String)] = [
            ("我爱茶。", "I love tea."),
            ("我喜欢 tea。", "I like tea."),
            ("喜欢", "like"),
            (String(repeating: "我", count: 30) + "喜欢", "Too long"),
            ("他喜欢狗。", ""),
            ("你喜欢吗？", "Do you like it?"),
            ("你喜欢吗？", "Do you like it?"),
        ]
        #expect(ExampleSentenceFilter.validated(raw, for: word).map(\.chinese) == ["你喜欢吗？"])
    }

    @Test("TUT-3 returns at most three sentences")
    func capsSentences() {
        let raw = (1...5).map { ("我\($0 == 1 ? "很" : String(repeating: "也", count: $0))喜欢。", "I like it.") }
        #expect(ExampleSentenceFilter.validated(raw, for: word).count == 3)
    }

    @Test("TUT-2 tones are described for the prompt")
    func toneDescription() {
        #expect(ToneDescription.describe("xi3 huan5") == "xǐ is the 3rd tone (dipping); huan is the neutral tone (light and short)")
    }
}

@MainActor
@Suite("AI tutor flows (SPEC §11)", .serialized)
struct TutorFlowTests {
    private let word = VocabularyItem.fixture(simplified: "喜欢", toneNumbers: "xi3 huan5", meanings: ["to like"])

    private func makeCache() -> TutorExampleCache {
        TutorExampleCache(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("tutor-\(UUID().uuidString).json"))
    }

    @Test("TUT-1 the tutor is hidden when the on-device model is unavailable")
    func unavailable() {
        #expect(!TutorViewModel(tutor: FakeTutor(available: false), cache: makeCache()).isAvailable)
        #expect(!TutorViewModel(tutor: nil, cache: makeCache()).isAvailable)
    }

    @Test("TUT-2 explaining a mistake shows the model's answer")
    func explain() async {
        let tutor = TutorViewModel(tutor: FakeTutor(), cache: makeCache())
        tutor.reset(for: word.id)
        await tutor.explain(MistakeContext(word: word, answer: "xi1huan", kind: .tone))
        #expect(tutor.explanation == .loaded(TutorExplanation(summary: "Tone tip", memoryTip: "Dip it")))
    }

    @Test("TUT-4 example sentences are cached per word")
    func examplesAreCached() async {
        let fake = FakeTutor()
        let cache = makeCache()
        let first = TutorViewModel(tutor: fake, cache: cache)
        first.reset(for: word.id)
        await first.loadExamples(for: word, hskLevel: 1)

        let second = TutorViewModel(tutor: fake, cache: cache)
        second.reset(for: word.id)
        await second.loadExamples(for: word, hskLevel: 1)

        #expect(fake.exampleRequests == 1)
        #expect(second.examples == .loaded(ExampleSentenceFilter.validated(FakeTutor.examples, for: word)))
    }

    @Test("TUT-3 nothing usable from the model shows a failure, not bad content")
    func unusableExamples() async {
        let tutor = TutorViewModel(tutor: FakeTutor(examples: [("我爱你。", "I love you.")]), cache: makeCache())
        tutor.reset(for: word.id)
        await tutor.loadExamples(for: word, hskLevel: 1)
        #expect(tutor.examples == .failed)
    }

    @Test("TUT-2 model errors show a failure")
    func modelError() async {
        let tutor = TutorViewModel(tutor: FakeTutor(fails: true), cache: makeCache())
        tutor.reset(for: word.id)
        await tutor.explain(MistakeContext(word: word, answer: "", kind: .skipped))
        #expect(tutor.explanation == .failed)
    }
}

final class FakeTutor: Tutoring {
    static let examples: [(chinese: String, english: String)] = [("我喜欢茶。", "I like tea."), ("你喜欢吗？", "Do you like it?")]

    let isAvailable: Bool
    private let examples: [(chinese: String, english: String)]
    private let fails: Bool
    private(set) var exampleRequests = 0

    init(available: Bool = true, examples: [(chinese: String, english: String)] = FakeTutor.examples, fails: Bool = false) {
        self.isAvailable = available
        self.examples = examples
        self.fails = fails
    }

    func explain(_ mistake: MistakeContext) async throws -> TutorExplanation {
        if fails { throw CancellationError() }
        return TutorExplanation(summary: "Tone tip", memoryTip: "Dip it")
    }

    func generateExamples(for word: VocabularyItem, hskLevel: Int) async throws -> [(chinese: String, english: String)] {
        exampleRequests += 1
        if fails { throw CancellationError() }
        return examples
    }
}
