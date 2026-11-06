import Testing
@testable import cleanpinyin

@Suite("Answer checking (SPEC §2)")
struct AnswerCheckingTests {
    private let validator = PinyinValidator()

    private func result(_ input: String, _ toneNumbers: String, requireTones: Bool = false) -> AnswerValidationResult {
        validator.validateAnswer(input: input, word: .fixture(toneNumbers: toneNumbers), requireTones: requireTones)
    }

    @Test("ANS-1 spaces between syllables are optional", arguments: ["baba", "ba ba", "Ba Ba", "  baba "])
    func ignoresSpacingAndCase(input: String) {
        #expect(result(input, "ba4 ba5") == .correct)
    }

    @Test("ANS-1 tone numbers without spaces", arguments: ["ni3hao3", "ni3 hao3", "NI3HAO3"])
    func toneNumbersWithoutSpaces(input: String) {
        #expect(result(input, "ni3 hao3", requireTones: true) == .correct)
    }

    @Test("ANS-2 tone marks are accepted", arguments: ["nǐhǎo", "nǐ hǎo", "Nǐ Hǎo"])
    func toneMarks(input: String) {
        #expect(result(input, "ni3 hao3", requireTones: true) == .correct)
    }

    @Test("ANS-3 ü can be typed as v, ü, u: or u", arguments: ["nv3", "nü3", "nu:3", "nu3", "nǚ"])
    func umlautVariants(input: String) {
        #expect(result(input, "nv3", requireTones: true) == .correct)
    }

    @Test("ANS-4 neutral tone may be 5, 0 or omitted", arguments: ["ba4ba5", "ba4ba0", "ba4ba", "ba4 ba"])
    func neutralTone(input: String) {
        #expect(result(input, "ba4 ba5", requireTones: true) == .correct)
    }

    @Test("ANS-5 tones are ignored when not required", arguments: ["ni3hao3", "ni1hao1", "nihao", "nīhāo"])
    func tonesIgnoredWhenNotRequired(input: String) {
        #expect(result(input, "ni3 hao3") == .correct)
    }

    @Test("ANS-6 wrong or missing tones are partial when tones are required", arguments: ["nihao", "ni1hao3", "ni3hao"])
    func partialWhenTonesWrong(input: String) {
        #expect(result(input, "ni3 hao3", requireTones: true) == .partial)
    }

    @Test("ANS-6 a tone on the wrong syllable is not accepted")
    func toneOnWrongSyllable() {
        #expect(result("ma ma1", "ma1 ma5", requireTones: true) != .correct)
    }

    @Test("Wrong letters are incorrect", arguments: ["nihai", "ni", "", "hao ni"])
    func wrongLetters(input: String) {
        #expect(result(input, "ni3 hao3") == .incorrect)
    }

    @Test("Capitalised proper-noun readings match lowercase input")
    func properNoun() {
        #expect(result("beijing", "Bei3 jing1") == .correct)
        #expect(result("Běijīng", "Bei3 jing1", requireTones: true) == .correct)
    }
}

@Suite("Pinyin display")
struct PinyinConverterTests {
    @Test("Tone numbers become tone marks", arguments: [
        ("ni3 hao3", "nǐ hǎo"),
        ("ba4 ba5", "bà ba"),
        ("nv3 er2", "nǚ ér"),
        ("lve4 wei1", "lüè wēi"),
        ("dou1", "dōu"),
        ("gui4", "guì"),
        ("liu2", "liú"),
        ("Bei3 jing1", "Běi jīng"),
        ("Ou1 zhou1", "Ōu zhōu"),
    ])
    func convertsToToneMarks(input: String, expected: String) {
        #expect(PinyinConverter.convertToToneMarks(input) == expected)
    }
}

extension VocabularyItem {
    static func fixture(
        simplified: String = "你好",
        toneNumbers: String = "ni3 hao3",
        meanings: [String] = ["hello"],
        frequency: Int = 1
    ) -> VocabularyItem {
        VocabularyItem(
            s: simplified, t: simplified, r: "", q: frequency, p: [], m: meanings, c: nil,
            ch: nil, ph: nil, tn: toneNumbers, lv: nil, cp: nil
        )
    }
}
