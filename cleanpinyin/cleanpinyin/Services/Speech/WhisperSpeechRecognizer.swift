import AVFoundation
import WhisperKit

// Whisper small running on the Neural Engine. It transcribes the whole take once the speaker stops,
// so unlike the Apple recognizer it can't end early on a partial result.
final class WhisperSpeechRecognizer: SpeechRecognizing {
    static let modelVariant = "openai_whisper-small_216MB"
    // Steers Whisper toward simplified Mandarin instead of Cantonese or traditional characters
    private static let mandarinPrompt = "以下是普通话的句子。"
    private static let sampleRate: Double = 16_000

    private let capture = MicrophoneCapture()
    private var whisper: WhisperKit?

    var isSupported: Bool { true }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func prepare(status: @escaping (String) -> Void) async throws {
        guard whisper == nil else { return }
        let base = try Self.modelStorage()
        let folder: URL
        if let downloaded = Self.downloadedModel(in: base) {
            folder = downloaded
        } else {
            status("Downloading the Whisper model…")
            folder = try await WhisperKit.download(variant: Self.modelVariant, downloadBase: base) { progress in
                status("Downloading the Whisper model… \(Int(progress.fractionCompleted * 100))%")
            }
        }
        status("Loading the Whisper model…")
        whisper = try await WhisperKit(WhisperKitConfig(
            downloadBase: base,
            modelFolder: folder.path,
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: false
        ))
    }

    func listen(isAcceptable: @escaping (String) -> Bool) async throws -> String {
        guard whisper != nil,
              let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Self.sampleRate, channels: 1, interleaved: false)
        else { throw SpeechRecognitionError.unavailable }

        let samples = SampleCollector()
        capture.onBuffer = { samples.append($0) }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let once = OnceContinuation(continuation)
            do {
                try capture.start(convertingTo: format) { once.resume(with: .success(())) }
            } catch {
                once.resume(with: .failure(error))
            }
        }

        // Whisper invents words from silence, so a take with no speech never reaches it
        guard capture.didHearVoice else { throw SpeechRecognitionError.noSpeech }

        return try await transcribe(samples.values)
    }

    // 16 kHz mono samples in, Mandarin text out
    func transcribe(_ samples: [Float]) async throws -> String {
        guard let whisper else { throw SpeechRecognitionError.unavailable }
        // Whisper hears nothing in a clip much shorter than a second unless there is silence around it
        let padding = [Float](repeating: 0, count: Int(Self.sampleRate / 2))
        let results = try await whisper.transcribe(audioArray: padding + samples + padding, decodeOptions: decodingOptions(for: whisper))
        let text = results.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw SpeechRecognitionError.noSpeech }
        return text
    }

    func stopListening() {
        capture.finish()
    }

    var lastTake: RecordedTake? {
        capture.lastTake
    }

    private func decodingOptions(for whisper: WhisperKit) -> DecodingOptions {
        var options = DecodingOptions()
        options.task = .transcribe
        options.language = "zh"
        options.detectLanguage = false
        options.temperature = 0
        options.withoutTimestamps = true
        options.skipSpecialTokens = true
        options.suppressBlank = true
        options.noSpeechThreshold = 0.6
        if let tokenizer = whisper.tokenizer {
            options.usePrefillPrompt = true
            options.promptTokens = tokenizer.encode(text: Self.mandarinPrompt)
                .filter { $0 < tokenizer.specialTokens.specialTokenBegin }
        }
        return options
    }

    // Application Support, left out of iCloud backups since the model can be downloaded again
    private static func modelStorage() throws -> URL {
        var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("WhisperModels", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        return url
    }

    // Lets later launches load the model offline instead of checking the download again
    private static func downloadedModel(in base: URL) -> URL? {
        let folder = base.appendingPathComponent("models/argmaxinc/whisperkit-coreml/\(modelVariant)", isDirectory: true)
        let encoder = folder.appendingPathComponent("AudioEncoder.mlmodelc")
        return FileManager.default.fileExists(atPath: encoder.path) ? folder : nil
    }
}

// Gathers converted microphone buffers from the audio thread
private final class SampleCollector {
    private let lock = NSLock()
    private var collected: [Float] = []

    var values: [Float] { lock.withLock { collected } }

    func append(_ buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let chunk = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
        lock.withLock { collected.append(contentsOf: chunk) }
    }
}
