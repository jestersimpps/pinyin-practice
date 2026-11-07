import AVFoundation

enum MyVoiceMode: String, CaseIterable, Identifiable {
    case afterReference
    case insteadOfReference
    case off

    static let preferenceKey = "myVoice.mode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .afterReference: return "After the reference voice"
        case .insteadOfReference: return "Instead of the reference voice"
        case .off: return "Off"
        }
    }

    var summary: String {
        switch self {
        case .afterReference: return "Hear the model pronunciation, then yourself saying it."
        case .insteadOfReference: return "Hear only yourself for words you've said correctly."
        case .off: return "Always use the reference voice."
        }
    }

    // Saved per device, alongside the recordings it plays
    static func current(in defaults: UserDefaults = .standard) -> MyVoiceMode {
        defaults.string(forKey: preferenceKey).flatMap(MyVoiceMode.init(rawValue:)) ?? .afterReference
    }
}

protocol VoiceClipStoring: AnyObject {
    // Keeps the spoken part of a take as the learner's recording of the word, replacing any older one
    func save(_ take: RecordedTake, for word: VocabularyItem)
    func clip(for text: String) -> URL?
    var count: Int { get }
    func deleteAll()
}

// The learner's own correct pronunciations, one short AAC file per word
final class VoiceClipStore: VoiceClipStoring {
    static let shared = VoiceClipStore()

    private static let leadIn: TimeInterval = 0.15
    private static let tail: TimeInterval = 0.25

    private let directory: URL
    // Traditional spellings point at the same recording without counting as another word
    private let aliases: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MyVoice", isDirectory: true)
        self.directory = base
        aliases = base.appendingPathComponent("aliases", isDirectory: true)
        try? FileManager.default.createDirectory(at: aliases, withIntermediateDirectories: true)
    }

    func save(_ take: RecordedTake, for word: VocabularyItem) {
        let clip = directory.appendingPathComponent("\(word.simplified).m4a")
        guard Self.export(take, to: clip) else { return }
        if word.traditional != word.simplified {
            let alias = aliases.appendingPathComponent("\(word.traditional).m4a")
            try? FileManager.default.removeItem(at: alias)
            try? FileManager.default.copyItem(at: clip, to: alias)
        }
    }

    func clip(for text: String) -> URL? {
        [directory, aliases]
            .map { $0.appendingPathComponent("\(text).m4a") }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    var count: Int {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return files.filter { $0.hasSuffix(".m4a") }.count
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: aliases, withIntermediateDirectories: true)
    }

    // Trims to the speech with a little room on each side and encodes it as AAC
    private static func export(_ take: RecordedTake, to destination: URL) -> Bool {
        guard let source = try? AVAudioFile(forReading: take.url) else { return false }
        let format = source.processingFormat
        let start = max(0, take.voicedFrames.lowerBound - AVAudioFramePosition(leadIn * take.sampleRate))
        let end = min(source.length, take.voicedFrames.upperBound + AVAudioFramePosition(tail * take.sampleRate))
        guard end > start,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(end - start)) else { return false }

        source.framePosition = start
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let temporary = destination.deletingLastPathComponent().appendingPathComponent("saving-\(UUID().uuidString).m4a")
        do {
            try source.read(into: buffer, frameCount: AVAudioFrameCount(end - start))
            let output = try AVAudioFile(forWriting: temporary, settings: settings, commonFormat: format.commonFormat, interleaved: format.isInterleaved)
            try output.write(from: buffer)
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            return false
        }
        try? FileManager.default.removeItem(at: destination)
        return (try? FileManager.default.moveItem(at: temporary, to: destination)) != nil
    }
}
