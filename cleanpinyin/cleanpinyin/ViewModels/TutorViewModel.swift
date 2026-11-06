import Foundation

@MainActor
final class TutorViewModel: ObservableObject {
    enum LoadState<Value: Equatable>: Equatable {
        case idle
        case loading
        case loaded(Value)
        case failed
    }

    @Published private(set) var explanation: LoadState<TutorExplanation> = .idle
    @Published private(set) var examples: LoadState<[ExampleSentence]> = .idle
    @Published private(set) var isAvailable = false

    private let tutor: Tutoring?
    private let cache: TutorExampleCache
    private var currentWordId: String?

    init(tutor: Tutoring? = TutorFactory.makeDefault(), cache: TutorExampleCache = .shared) {
        self.tutor = tutor
        self.cache = cache
        isAvailable = tutor?.isAvailable == true
    }

    // Availability is re-checked per word because the model can finish downloading mid-session
    func reset(for wordId: String?) {
        guard wordId != currentWordId else { return }
        currentWordId = wordId
        isAvailable = tutor?.isAvailable == true
        explanation = .idle
        examples = .idle
    }

    func explain(_ mistake: MistakeContext) async {
        guard let tutor, explanation != .loading else { return }
        explanation = .loading
        do {
            let result = try await tutor.explain(mistake)
            guard currentWordId == mistake.word.id else { return }
            explanation = .loaded(result)
        } catch {
            guard currentWordId == mistake.word.id else { return }
            explanation = .failed
        }
    }

    func loadExamples(for word: VocabularyItem, hskLevel: Int) async {
        guard examples != .loading else { return }
        if let cached = cache.sentences(for: word.id) {
            examples = .loaded(cached)
            return
        }
        guard let tutor else { return }

        examples = .loading
        do {
            let sentences = ExampleSentenceFilter.validated(
                try await tutor.generateExamples(for: word, hskLevel: hskLevel),
                for: word
            )
            guard currentWordId == word.id else { return }
            if sentences.isEmpty {
                examples = .failed
            } else {
                cache.store(sentences, for: word.id)
                examples = .loaded(sentences)
            }
        } catch {
            guard currentWordId == word.id else { return }
            examples = .failed
        }
    }
}
