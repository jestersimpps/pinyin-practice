import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class FoundationModelsTutor: Tutoring {
    private let model = SystemLanguageModel.default

    private static let instructions = """
    You are a warm, concise Mandarin Chinese tutor inside a pinyin practice app for English-speaking learners. \
    Use plain English. Never use more than two short sentences per field. \
    Trust the pinyin and tones you are given; never invent different ones. \
    Use only Simplified Chinese characters.
    """

    var isAvailable: Bool {
        if case .available = model.availability { return true }
        return false
    }

    func explain(_ mistake: MistakeContext) async throws -> TutorExplanation {
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let response = try await session.respond(
            to: Self.prompt(for: mistake),
            generating: GeneratedExplanation.self,
            options: GenerationOptions(temperature: 0.4)
        )
        return TutorExplanation(summary: response.content.summary, memoryTip: response.content.memoryTip)
    }

    func generateExamples(for word: VocabularyItem, hskLevel: Int) async throws -> [(chinese: String, english: String)] {
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let prompt = """
        Write three short, natural example sentences that use the word 「\(word.simplified)」 (\(word.pinyin), "\(word.shortTranslation)"). \
        Keep each sentence under 15 characters and use only vocabulary a learner at HSK level \(hskLevel) knows. \
        Each sentence must contain 「\(word.simplified)」 exactly as written.
        """
        let response = try await session.respond(
            to: prompt,
            generating: GeneratedExamples.self,
            options: GenerationOptions(temperature: 0.7)
        )
        return response.content.sentences.map { ($0.chinese, $0.english) }
    }

    private static func prompt(for mistake: MistakeContext) -> String {
        let word = mistake.word
        let diagnosis: String
        switch mistake.kind {
        case .tone:
            diagnosis = "The syllables were right but the tones were wrong."
        case .spelling:
            diagnosis = "The syllables themselves were wrong."
        case .skipped:
            diagnosis = "They did not know it and skipped the word."
        }
        let answer = mistake.answer.isEmpty ? "nothing" : "\"\(mistake.answer)\""

        return """
        The learner saw 「\(word.simplified)」, meaning "\(word.shortTranslation)". \
        The correct pinyin is \(word.pinyin): \(ToneDescription.describe(word.toneNumbers)). \
        They answered \(answer). \(diagnosis) \
        Explain briefly what to fix, then give one memorable tip for the correct pronunciation.
        """
    }
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedExplanation {
    @Guide(description: "One or two short sentences explaining what the learner got wrong and the correct pronunciation")
    var summary: String

    @Guide(description: "One short, vivid memory tip for remembering the correct pronunciation and tones")
    var memoryTip: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedSentence {
    @Guide(description: "A short, natural sentence in Simplified Chinese characters only, no pinyin")
    var chinese: String

    @Guide(description: "A natural English translation of the sentence")
    var english: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedExamples {
    @Guide(description: "Three different example sentences", .count(3))
    var sentences: [GeneratedSentence]
}
