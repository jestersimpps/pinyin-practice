import AVFoundation

protocol ListeningCueing: AnyObject {
    // Plays a short beep and returns once it has finished, so the microphone never records it
    func playReadyCue() async
}

final class ListeningCue: ListeningCueing {
    static let shared = ListeningCue()

    private static let sampleRate = 44_100
    private static let duration: TimeInterval = 0.12
    private let tone = ListeningCue.makeTone(frequency: 1_046.5)
    private var player: AVAudioPlayer?

    func playReadyCue() async {
        try? AudioSessionCoordinator.shared.activateForRecording()
        guard let player = try? AVAudioPlayer(data: tone) else { return }
        self.player = player
        player.volume = 0.5
        player.play()
        try? await Task.sleep(for: .seconds(Self.duration + 0.06))
    }

    // A soft sine tone with short fades, wrapped as 16-bit mono WAV
    private static func makeTone(frequency: Double) -> Data {
        let frameCount = Int(Double(sampleRate) * duration)
        let fadeFrames = Int(Double(sampleRate) * 0.015)
        var samples = Data(capacity: frameCount * 2)
        for frame in 0..<frameCount {
            let envelope = min(1, Double(min(frame, frameCount - frame)) / Double(fadeFrames))
            let value = sin(2 * .pi * frequency * Double(frame) / Double(sampleRate)) * envelope
            withUnsafeBytes(of: Int16(value * Double(Int16.max)).littleEndian) { samples.append(contentsOf: $0) }
        }

        var wav = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) }
        }
        wav.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36 + samples.count))
        wav.append(contentsOf: Array("WAVEfmt ".utf8))
        append(UInt32(16))
        append(UInt16(1))
        append(UInt16(1))
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2))
        append(UInt16(2))
        append(UInt16(16))
        wav.append(contentsOf: Array("data".utf8))
        append(UInt32(samples.count))
        wav.append(samples)
        return wav
    }
}
