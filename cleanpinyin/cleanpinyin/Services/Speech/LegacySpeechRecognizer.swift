import Speech

// On-device Mandarin recognition for iOS 17–25, and the fallback when SpeechTranscriber lacks Mandarin
final class LegacySpeechRecognizer: SpeechRecognizing {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let capture = MicrophoneCapture()
    private var task: SFSpeechRecognitionTask?

    var isSupported: Bool {
        recognizer?.supportsOnDeviceRecognition == true
    }

    func requestPermission() async -> Bool {
        await SpeechPermissions.request()
    }

    func prepare(status: @escaping (String) -> Void) async throws {
        guard isSupported, recognizer?.isAvailable == true else { throw SpeechRecognitionError.unavailable }
    }

    func listen() async throws -> String {
        guard let recognizer, recognizer.isAvailable else { throw SpeechRecognitionError.unavailable }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.taskHint = .search

        return try await withCheckedThrowingContinuation { continuation in
            let once = OnceContinuation(continuation)

            task = recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    once.resume(with: text.isEmpty ? .failure(SpeechRecognitionError.noSpeech) : .success(text))
                } else if error != nil {
                    once.resume(with: .failure(SpeechRecognitionError.noSpeech))
                }
            }

            capture.onBuffer = { request.append($0) }
            do {
                try capture.start { request.endAudio() }
            } catch {
                task?.cancel()
                once.resume(with: .failure(error))
            }
        }
    }

    func stopListening() {
        capture.finish()
    }
}
