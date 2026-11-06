import Foundation
import AVFoundation

protocol SpeechSpeaking: AnyObject {
    var isSpeaking: Bool { get }
    func speak(chinese: String, completion: (() -> Void)?)
    func speak(english: String, completion: (() -> Void)?)
    // Speaks after whatever is playing now instead of cutting it off
    func speakAfterCurrent(english: String)
    func stopSpeaking()
}

extension SpeechSpeaking {
    func speak(chinese: String) { speak(chinese: chinese, completion: nil) }
}

final class TextToSpeechService: NSObject, ObservableObject, SpeechSpeaking {
    static let shared = TextToSpeechService()
    static let chineseLanguage = "zh-CN"
    static let englishLanguage = "en-US"

    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var completions: [ObjectIdentifier: () -> Void] = [:]
    private var voices: [String: AVSpeechSynthesisVoice] = [:]

    private override init() {
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(
            forName: AVSpeechSynthesizer.availableVoicesDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.voices.removeAll()
        }
    }

    func speak(chinese: String, completion: (() -> Void)? = nil) {
        speak(text: chinese, language: Self.chineseLanguage, completion: completion)
    }

    func speak(english: String, completion: (() -> Void)? = nil) {
        speak(text: english, language: Self.englishLanguage, completion: completion)
    }

    func speakAfterCurrent(english: String) {
        enqueue(text: english, language: Self.englishLanguage, completion: nil)
    }

    // The best voice installed for a language: Premium, then Enhanced, then the system default
    func voice(forLanguage language: String) -> AVSpeechSynthesisVoice? {
        if let cached = voices[language] { return cached }
        let fallback = AVSpeechSynthesisVoice(language: language)
        let rank = { (voice: AVSpeechSynthesisVoice) in
            (voice.quality.rawValue, voice.identifier == fallback?.identifier ? 1 : 0)
        }
        let best = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language && $0.voiceTraits.isDisjoint(with: [.isNoveltyVoice, .isPersonalVoice]) }
            .max { rank($0) < rank($1) }
            ?? fallback
        voices[language] = best
        return best
    }

    func stopSpeaking() {
        completions.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speak(text: String, language: String, completion: (() -> Void)?) {
        stopSpeaking()
        enqueue(text: text, language: language, completion: completion)
    }

    private func enqueue(text: String, language: String, completion: (() -> Void)?) {
        AudioSessionCoordinator.shared.activateForSpeech()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(forLanguage: language)
        utterance.rate = 0.45
        if let completion {
            completions[ObjectIdentifier(utterance)] = completion
        }
        synthesizer.speak(utterance)
    }

    private func finish(_ utterance: AVSpeechUtterance, runCompletion: Bool) {
        let completion = completions.removeValue(forKey: ObjectIdentifier(utterance))

        if !synthesizer.isSpeaking {
            isSpeaking = false
            AudioSessionCoordinator.shared.deactivateIfIdle()
        }
        if runCompletion { completion?() }
    }
}

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.finish(utterance, runCompletion: true) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.finish(utterance, runCompletion: false) }
    }
}
