import AVFoundation
import Speech

enum SpeechRecognitionError: LocalizedError, Equatable {
    case permissionDenied
    case unavailable
    case noSpeech

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Allow microphone and speech recognition for EchoLingo in Settings to answer by voice."
        case .unavailable:
            return "Mandarin speech recognition isn't available on this device."
        case .noSpeech:
            return "Didn't catch that. Tap the microphone and try again."
        }
    }
}

protocol SpeechRecognizing: AnyObject {
    var isSupported: Bool { get }
    func requestPermission() async -> Bool
    // Readies on-device recognition, downloading the Mandarin model the first time if needed
    func prepare(status: @escaping (String) -> Void) async throws
    // Records one answer and returns what was heard. isAcceptable sees partial transcripts while the learner is
    // still speaking; returning true ends the take at once with that transcript.
    func listen(isAcceptable: @escaping (String) -> Bool) async throws -> String
    func stopListening()
}

enum SpeechRecognizerFactory {
    static func makeDefault() -> SpeechRecognizing? {
        let recognizer: SpeechRecognizing
        if #available(iOS 26.0, *) {
            recognizer = AnalyzerSpeechRecognizer()
        } else {
            recognizer = LegacySpeechRecognizer()
        }
        return recognizer.isSupported ? recognizer : nil
    }
}

enum SpeechPermissions {
    static func request() async -> Bool {
        guard await AVAudioApplication.requestRecordPermission() else { return false }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

// Collects transcript pieces from a background stream and remembers an early-accepted partial
final class TranscriptBuffer {
    private let lock = NSLock()
    private var finalized = ""
    private var accepted: String?

    var acceptedText: String? { lock.withLock { accepted } }
    var finalizedText: String { lock.withLock { finalized } }

    func appendFinal(_ text: String) {
        lock.withLock { finalized += text }
    }

    func current(withVolatile volatile: String) -> String {
        lock.withLock { finalized + volatile }
    }

    // Returns true only for the first acceptance
    func accept(_ text: String) -> Bool {
        lock.withLock {
            guard accepted == nil else { return false }
            accepted = text
            return true
        }
    }
}

// Resumes a continuation exactly once, whichever callback arrives first
final class OnceContinuation<Value> {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?

    init(_ continuation: CheckedContinuation<Value, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<Value, Error>) {
        let pending: CheckedContinuation<Value, Error>? = lock.withLock {
            defer { continuation = nil }
            return continuation
        }
        pending?.resume(with: result)
    }
}
