import AVFoundation

// One microphone take saved to a temporary file, with where the speech starts and ends
struct RecordedTake: Equatable {
    let url: URL
    let sampleRate: Double
    let voicedFrames: ClosedRange<AVAudioFramePosition>
}

// Streams microphone audio and ends the take automatically once the speaker falls silent
final class MicrophoneCapture {
    var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var onEnd: (() -> Void)?
    private var converter: AVAudioConverter?
    private var targetFormat: AVAudioFormat?
    private var startTime = Date()
    private var lastVoiceTime: Date?
    private var noiseFloor: Float = 1
    private var peakLevel: Float = 0
    private var takeFile: AVAudioFile?
    private var framesRecorded: AVAudioFramePosition = 0
    private var firstVoiceFrame: AVAudioFramePosition?
    private var lastVoiceFrame: AVAudioFramePosition?
    private var latestTake: RecordedTake?

    // The last take that contained speech; the file is replaced by the next take unless moved away first
    var lastTake: RecordedTake? {
        lock.withLock { latestTake }
    }

    // Whether the last take had any speech in it, judged by volume
    var didHearVoice: Bool {
        lock.withLock { lastVoiceTime != nil }
    }

    private let maxDuration: TimeInterval = 10
    private let trailingSilence: TimeInterval = 0.5
    private let noSpeechTimeout: TimeInterval = 8

    func start(convertingTo format: AVAudioFormat? = nil, onEnd: @escaping () -> Void) throws {
        try AudioSessionCoordinator.shared.activateForRecording()
        let input = engine.inputNode
        let takeURL = FileManager.default.temporaryDirectory.appendingPathComponent("take-\(UUID().uuidString).caf")
        let file = try? AVAudioFile(forWriting: takeURL, settings: input.outputFormat(forBus: 0).settings)

        lock.withLock {
            if let previous = latestTake?.url {
                try? FileManager.default.removeItem(at: previous)
            }
            latestTake = nil
            takeFile = file
            framesRecorded = 0
            firstVoiceFrame = nil
            lastVoiceFrame = nil
            self.onEnd = onEnd
            targetFormat = format
            converter = nil
            startTime = Date()
            lastVoiceTime = nil
            noiseFloor = 1
            peakLevel = 0
        }

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.handle(buffer)
        }
        engine.prepare()
        try engine.start()
    }

    // Ends the take now; safe to call more than once
    func finish() {
        let callback: (() -> Void)? = lock.withLock {
            defer { onEnd = nil }
            return onEnd
        }
        guard let callback else { return }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        closeTake()
        AudioSessionCoordinator.shared.deactivateIfIdle()
        callback()
    }

    private func closeTake() {
        lock.withLock {
            guard let file = takeFile else { return }
            takeFile = nil
            if let first = firstVoiceFrame, let last = lastVoiceFrame {
                latestTake = RecordedTake(url: file.url, sampleRate: file.processingFormat.sampleRate, voicedFrames: first...last)
            } else {
                try? FileManager.default.removeItem(at: file.url)
            }
        }
    }

    private func handle(_ buffer: AVAudioPCMBuffer) {
        lock.withLock { try? takeFile?.write(from: buffer) }
        if let output = convert(buffer) {
            onBuffer?(output)
        }
        if shouldEnd(after: buffer) {
            DispatchQueue.main.async { self.finish() }
        }
    }

    private func shouldEnd(after buffer: AVAudioPCMBuffer) -> Bool {
        let level = Self.rms(of: buffer)
        let now = Date()

        return lock.withLock {
            noiseFloor = min(noiseFloor, max(level, 0.001))
            let speechThreshold = max(0.02, noiseFloor * 4)
            if level > speechThreshold {
                peakLevel = max(peakLevel, level)
            }
            // Relative to the speaker's own volume, so steady background noise doesn't count as talking
            let bufferStart = framesRecorded
            framesRecorded += AVAudioFramePosition(buffer.frameLength)
            if level > max(speechThreshold, peakLevel * 0.2) {
                lastVoiceTime = now
                firstVoiceFrame = firstVoiceFrame ?? bufferStart
                lastVoiceFrame = framesRecorded
            }

            let elapsed = now.timeIntervalSince(startTime)
            if elapsed > maxDuration { return true }
            guard let lastVoiceTime else { return elapsed > noSpeechTimeout }
            return now.timeIntervalSince(lastVoiceTime) > trailingSilence
        }
    }

    private func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let targetFormat = lock.withLock({ self.targetFormat }), buffer.format != targetFormat else { return buffer }

        if converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: targetFormat)
        }
        guard let converter else { return nil }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return nil }

        var supplied = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil ? output : nil
    }

    private static func rms(of buffer: AVAudioPCMBuffer) -> Float {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<count {
            sum += samples[index] * samples[index]
        }
        return (sum / Float(count)).squareRoot()
    }
}
