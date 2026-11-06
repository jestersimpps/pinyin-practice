import Foundation
import AVFoundation

protocol SpeechSpeaking: AnyObject {
    func speak(chinese: String, completion: (() -> Void)?)
    func speak(english: String, completion: (() -> Void)?)
    func stopSpeaking()
}

extension SpeechSpeaking {
    func speak(chinese: String) { speak(chinese: chinese, completion: nil) }
}

final class TextToSpeechService: NSObject, ObservableObject, SpeechSpeaking {
    static let shared = TextToSpeechService()

    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var completions: [ObjectIdentifier: () -> Void] = [:]

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(chinese: String, completion: (() -> Void)? = nil) {
        speak(text: chinese, language: "zh-CN", rate: 0.45, completion: completion)
    }

    func speak(english: String, completion: (() -> Void)? = nil) {
        speak(text: english, language: "en-US", rate: 0.45, completion: completion)
    }

    func stopSpeaking() {
        completions.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speak(text: String, language: String, rate: Float, completion: (() -> Void)?) {
        stopSpeaking()
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback || session.mode != .spokenAudio {
            try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        }
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        if let completion {
            completions[ObjectIdentifier(utterance)] = completion
        }
        synthesizer.speak(utterance)
    }

    private func finish(_ utterance: AVSpeechUtterance, runCompletion: Bool) {
        let completion = completions.removeValue(forKey: ObjectIdentifier(utterance))

        if !synthesizer.isSpeaking {
            isSpeaking = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
