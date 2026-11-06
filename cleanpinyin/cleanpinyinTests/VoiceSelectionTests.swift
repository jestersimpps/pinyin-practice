import AVFoundation
import Foundation
import Testing
@testable import cleanpinyin

@Suite("Voice selection (SPEC §8)")
struct VoiceSelectionTests {
    private let defaults: UserDefaults
    private let speech: TextToSpeechService

    init() {
        let suite = "cleanpinyin.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        speech = TextToSpeechService(defaults: defaults)
    }

    @Test("SET-8 the voice lists hold only Mandarin or English voices, best quality first", arguments: SpeechLanguage.allCases)
    func installedVoices(language: SpeechLanguage) {
        let voices = speech.installedVoices(for: language)
        #expect(voices.allSatisfy { language.includes(voiceLanguage: $0.language) })
        #expect(voices.map(\.quality.rawValue) == voices.map(\.quality.rawValue).sorted(by: >))
        #expect(!voices.contains { $0.language == "zh-HK" })
    }

    @Test("SET-8 Automatic uses the best installed voice in the main dialect", arguments: SpeechLanguage.allCases)
    func automaticVoice(language: SpeechLanguage) throws {
        let best = try #require(speech.voice(for: language))
        #expect(best == speech.bestVoice(for: language))
        let sameDialect = speech.installedVoices(for: language).filter { $0.language == language.mainCode }
        if let topQuality = sameDialect.map(\.quality.rawValue).max() {
            #expect(best.language == language.mainCode)
            #expect(best.quality.rawValue == topQuality)
        }
    }

    @Test("SET-8 a chosen voice is used, and a missing one falls back to Automatic", arguments: SpeechLanguage.allCases)
    func chosenVoice(language: SpeechLanguage) throws {
        let chosen = try #require(speech.installedVoices(for: language).last)
        defaults.set(chosen.identifier, forKey: language.preferenceKey)
        #expect(speech.voice(for: language)?.identifier == chosen.identifier)

        defaults.set("com.apple.voice.removed", forKey: language.preferenceKey)
        #expect(speech.voice(for: language) == speech.bestVoice(for: language))
    }
}
