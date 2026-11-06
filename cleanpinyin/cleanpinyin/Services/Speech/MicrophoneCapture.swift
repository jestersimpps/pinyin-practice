import AVFoundation

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

    private let maxDuration: TimeInterval = 6
    private let trailingSilence: TimeInterval = 0.9
    private let noSpeechTimeout: TimeInterval = 4

    func start(convertingTo format: AVAudioFormat? = nil, onEnd: @escaping () -> Void) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true)

        lock.withLock {
            self.onEnd = onEnd
            targetFormat = format
            converter = nil
            startTime = Date()
            lastVoiceTime = nil
            noiseFloor = 1
        }

        let input = engine.inputNode
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        callback()
    }

    private func handle(_ buffer: AVAudioPCMBuffer) {
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
            if level > max(0.02, noiseFloor * 4) {
                lastVoiceTime = now
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
