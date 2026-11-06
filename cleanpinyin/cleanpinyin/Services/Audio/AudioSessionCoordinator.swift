import AVFoundation

// One owner for the shared audio session. Speech and the microphone each set it up for a single utterance or take,
// unless a continuous session (Imprint) holds it, in which case they leave it alone so playback survives the lock screen.
final class AudioSessionCoordinator {
    static let shared = AudioSessionCoordinator()

    private let session = AVAudioSession.sharedInstance()
    private var continuousRecording: Bool?

    var isContinuous: Bool { continuousRecording != nil }

    func activateForSpeech() {
        if continuousRecording == nil, session.category != .playback || session.mode != .spokenAudio {
            try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        }
        try? session.setActive(true)
    }

    func activateForRecording() throws {
        switch continuousRecording {
        case true?:
            break
        case false?:
            throw SpeechRecognitionError.unavailable
        case nil:
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        }
        try session.setActive(true)
    }

    func deactivateIfIdle() {
        guard continuousRecording == nil else { return }
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // Not mixable on purpose: a lesson pauses other audio and shows on the lock screen as Now Playing
    func beginContinuous(recording: Bool) throws {
        if recording {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
        } else {
            try session.setCategory(.playback, mode: .spokenAudio)
        }
        try session.setActive(true)
        continuousRecording = recording
    }

    func endContinuous() {
        guard continuousRecording != nil else { return }
        continuousRecording = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
