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

    // A synthesized phrase or one of the learner's own recordings, played one after another
    private enum Segment {
        case speech(String, SpeechLanguage)
        case recording(URL)
    }

    private struct QueuedSegment {
        let segment: Segment
        let completion: (() -> Void)?
    }

    private let synthesizer = AVSpeechSynthesizer()
    private let defaults: UserDefaults
    private let voiceClips: VoiceClipStoring
    private var queue: [QueuedSegment] = []
    private var current: QueuedSegment?
    private var currentUtterance: AVSpeechUtterance?
    private var player: AVAudioPlayer?
    private var bestVoices: [SpeechLanguage: AVSpeechSynthesisVoice] = [:]

    init(defaults: UserDefaults = .standard, voiceClips: VoiceClipStoring = VoiceClipStore.shared) {
        self.defaults = defaults
        self.voiceClips = voiceClips
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(
            forName: AVSpeechSynthesizer.availableVoicesDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.bestVoices.removeAll()
        }
    }

    func speak(chinese: String, completion: (() -> Void)? = nil) {
        stopSpeaking()
        enqueue(chineseSegments(for: chinese), completion: completion)
    }

    func speak(english: String, completion: (() -> Void)? = nil) {
        speak(english, in: .english, completion: completion)
    }

    func speakAfterCurrent(english: String) {
        enqueue([.speech(english, .english)], completion: nil)
    }

    func speak(_ text: String, in language: SpeechLanguage, completion: (() -> Void)? = nil) {
        stopSpeaking()
        enqueue([.speech(text, language)], completion: completion)
    }

    // The learner's own recording, when there is one, follows or replaces the reference voice
    private func chineseSegments(for text: String) -> [Segment] {
        guard let recording = voiceClips.clip(for: text) else { return [.speech(text, .chinese)] }
        switch MyVoiceMode.current(in: defaults) {
        case .afterReference: return [.speech(text, .chinese), .recording(recording)]
        case .insteadOfReference: return [.recording(recording)]
        case .off: return [.speech(text, .chinese)]
        }
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
        queue.removeAll()
        current = nil
        currentUtterance = nil
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        // Hands the audio back to other apps unless something new started speaking straight away
        DispatchQueue.main.async {
            guard self.current == nil else { return }
            AudioSessionCoordinator.shared.deactivateIfIdle()
        }
    }

    private func enqueue(_ segments: [Segment], completion: (() -> Void)?) {
        for (index, segment) in segments.enumerated() {
            queue.append(QueuedSegment(segment: segment, completion: index == segments.count - 1 ? completion : nil))
        }
        if current == nil {
            playNext()
        }
    }

    private func playNext() {
        guard !queue.isEmpty else {
            isSpeaking = false
            AudioSessionCoordinator.shared.deactivateIfIdle()
            return
        }
        let next = queue.removeFirst()
        current = next
        isSpeaking = true
        AudioSessionCoordinator.shared.activateForSpeech()

        switch next.segment {
        case let .speech(text, language):
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice(for: language)
            utterance.rate = 0.45
            currentUtterance = utterance
            synthesizer.speak(utterance)
        case let .recording(url):
            player = try? AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            if player?.play() != true {
                finishCurrent()
            }
        }
    }

    private func finishCurrent() {
        let finished = current
        current = nil
        currentUtterance = nil
        player = nil
        playNext()
        finished?.completion?()
    }
}

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            guard utterance === self.currentUtterance else { return }
            self.finishCurrent()
        }
    }
}

extension TextToSpeechService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            guard player === self.player else { return }
            self.finishCurrent()
        }
    }
}
