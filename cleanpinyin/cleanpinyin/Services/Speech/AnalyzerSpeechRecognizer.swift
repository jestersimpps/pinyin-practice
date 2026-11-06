import AVFoundation
import Speech

// iOS 26 on-device recognition with SpeechAnalyzer; falls back to SFSpeechRecognizer when Mandarin isn't offered
@available(iOS 26.0, *)
final class AnalyzerSpeechRecognizer: SpeechRecognizing {
    private let requestedLocale = Locale(identifier: "zh-CN")
    private let fallback = LegacySpeechRecognizer()
    private let capture = MicrophoneCapture()
    private var resolvedLocale: Locale?
    private var usesFallback = false

    var isSupported: Bool {
        SpeechTranscriber.isAvailable || fallback.isSupported
    }

    func requestPermission() async -> Bool {
        await SpeechPermissions.request()
    }

    func prepare(status: @escaping (String) -> Void) async throws {
        guard resolvedLocale == nil, !usesFallback else { return }

        guard SpeechTranscriber.isAvailable,
              let locale = await SpeechTranscriber.supportedLocale(equivalentTo: requestedLocale) else {
            usesFallback = true
            try await fallback.prepare(status: status)
            return
        }

        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
        if let installation = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            status("Downloading the Mandarin speech model…")
            try await installation.downloadAndInstall()
        }
        resolvedLocale = locale
    }

    func listen() async throws -> String {
        if usesFallback {
            return try await fallback.listen()
        }
        guard let resolvedLocale else { throw SpeechRecognitionError.unavailable }

        let transcriber = SpeechTranscriber(locale: resolvedLocale, preset: .transcription)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw SpeechRecognitionError.unavailable
        }

        let (inputSequence, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
        let collector = Task {
            var text = ""
            for try await result in transcriber.results {
                text += String(result.text.characters)
            }
            return text
        }

        try await analyzer.start(inputSequence: inputSequence)
        capture.onBuffer = { inputContinuation.yield(AnalyzerInput(buffer: $0)) }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let once = OnceContinuation(continuation)
            do {
                try capture.start(convertingTo: format) { once.resume(with: .success(())) }
            } catch {
                once.resume(with: .failure(error))
            }
        }

        inputContinuation.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        let text = try await collector.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw SpeechRecognitionError.noSpeech }
        return text
    }

    func stopListening() {
        usesFallback ? fallback.stopListening() : capture.finish()
    }
}
