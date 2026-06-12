import Foundation
import AVFoundation

final class TextToSpeechService: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = TextToSpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false

    private override init() {
        super.init()
        synthesizer.delegate = self
        configureSpeechSession()
    }

    private func configureSpeechSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func speak(chinese: String, rate: Float = 0.5) {
        speak(text: chinese, language: "zh-CN", rate: rate)
    }

    func speak(english: String, rate: Float = 0.4) {
        speak(text: english, language: "en-US", rate: rate)
    }

    private func speak(text: String, language: String, rate: Float) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
