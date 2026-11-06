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

    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private let defaults: UserDefaults
    private var completions: [ObjectIdentifier: () -> Void] = [:]
    private var bestVoices: [SpeechLanguage: AVSpeechSynthesisVoice] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(
            forName: AVSpeechSynthesizer.availableVoicesDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.bestVoices.removeAll()
        }
    }

    func speak(chinese: String, completion: (() -> Void)? = nil) {
        speak(chinese, in: .chinese, completion: completion)
    }

    func speak(english: String, completion: (() -> Void)? = nil) {
        speak(english, in: .english, completion: completion)
    }

    func speakAfterCurrent(english: String) {
        enqueue(english, in: .english, completion: nil)
    }

    func speak(_ text: String, in language: SpeechLanguage, completion: (() -> Void)? = nil) {
        stopSpeaking()
        enqueue(text, in: language, completion: completion)
    }

    // Best first: Premium, then Enhanced, then Standard, alphabetically within each
    func installedVoices(for language: SpeechLanguage) -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { language.includes(voiceLanguage: $0.language) && $0.voiceTraits.isDisjoint(with: [.isNoveltyVoice, .isPersonalVoice]) }
            .sorted { ($0.quality.rawValue, $1.name) > ($1.quality.rawValue, $0.name) }
    }

    // The voice the learner picked, or the best one installed when they haven't picked or it was removed
    func voice(for language: SpeechLanguage) -> AVSpeechSynthesisVoice? {
        if let identifier = defaults.string(forKey: language.preferenceKey), !identifier.isEmpty,
           let chosen = AVSpeechSynthesisVoice(identifier: identifier) {
            return chosen
        }
        return bestVoice(for: language)
    }

    // Prefers the main dialect (mainland Mandarin, US English), then quality, then the system default
    func bestVoice(for language: SpeechLanguage) -> AVSpeechSynthesisVoice? {
        if let cached = bestVoices[language] { return cached }
        let fallback = AVSpeechSynthesisVoice(language: language.mainCode)
        let rank = { (voice: AVSpeechSynthesisVoice) in
            (voice.language == language.mainCode ? 1 : 0, voice.quality.rawValue, voice.identifier == fallback?.identifier ? 1 : 0)
        }
        let best = installedVoices(for: language).max { rank($0) < rank($1) } ?? fallback
        bestVoices[language] = best
        return best
    }

    func stopSpeaking() {
        completions.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func enqueue(_ text: String, in language: SpeechLanguage, completion: (() -> Void)?) {
        AudioSessionCoordinator.shared.activateForSpeech()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: language)
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
