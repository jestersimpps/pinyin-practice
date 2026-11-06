import Testing
@testable import cleanpinyin

@Suite("Say it: spoken answers (SPEC §10)")
struct SpokenAnswerTests {
    private let checker = SpokenAnswerChecker()

    private func grade(_ transcript: String, _ simplified: String, _ toneNumbers: String) -> SpokenAnswer {
        checker.evaluate(transcript: transcript, word: .fixture(simplified: simplified, toneNumbers: toneNumbers))
    }

    @Test("Transliteration produces tone-marked pinyin")
    func transliteration() {
        #expect(ChineseTransliterator.pinyin(for: "你好") == "nǐ hǎo")
        #expect(ChineseTransliterator.hanzi(in: "你好！ hello 3") == "你好三")
    }

    @Test("SAY-2 hearing the word itself is correct, ignoring punctuation")
    func exactWord() {
        let spoken = grade("你好。", "你好", "ni3 hao3")
        #expect(spoken.result == .correct)
        #expect(spoken.heardText == "你好")
    }

    @Test("SAY-2 a same-sounding character with the same tones is correct")
    func homophone() {
        #expect(grade("她", "他", "ta1").result == .correct)
    }

    @Test("SAY-2 the right syllables with another tone are partial")
    func wrongTone() {
        let spoken = grade("妈", "马", "ma3")
        #expect(spoken.result == .partial)
        #expect(spoken.heardPinyin == "mā")
    }

    @Test("SAY-2 a different word is incorrect", arguments: ["谢谢", "hello", ""])
    func differentWord(transcript: String) {
        #expect(grade(transcript, "你好", "ni3 hao3").result == .incorrect)
    }

    @Test("SAY-2 digits are read as Chinese numerals")
    func digits() {
        #expect(grade("3", "三", "san1").result == .correct)
    }
}
