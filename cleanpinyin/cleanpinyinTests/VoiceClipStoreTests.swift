import AVFoundation
import Foundation
import Testing
@testable import cleanpinyin

@Suite("My voice recordings (SPEC §10)")
struct VoiceClipStoreTests {
    private let folder = FileManager.default.temporaryDirectory.appendingPathComponent("voice-clips-\(UUID().uuidString)")

    // One second of silence, half a second of tone, one second of silence
    private func makeTake() throws -> RecordedTake {
        let sampleRate = 16_000.0
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("take-\(UUID().uuidString).caf")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(sampleRate * 2.5)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        let voiced = AVAudioFramePosition(sampleRate)...AVAudioFramePosition(sampleRate * 1.5)
        for frame in 0..<Int(frames) {
            buffer.floatChannelData![0][frame] = voiced.contains(AVAudioFramePosition(frame)) ? Float(sin(Double(frame) * 0.2)) * 0.5 : 0
        }
        try file.write(from: buffer)
        return RecordedTake(url: url, sampleRate: sampleRate, voicedFrames: voiced)
    }

    @Test("SAY-11 a recording is trimmed to the speech and found by simplified or traditional spelling")
    func savesTrimmedClip() throws {
        let store = VoiceClipStore(directory: folder)
        let word = VocabularyItem.fixture(simplified: "学生", toneNumbers: "xue2 sheng1")
        let traditionalWord = VocabularyItem(s: "学生", t: "學生", r: "", q: 1, p: [], m: ["student"], c: nil, ch: nil, ph: nil, tn: "xue2 sheng1", lv: nil, cp: nil)

        store.save(try makeTake(), for: traditionalWord)

        let clip = try #require(store.clip(for: word.simplified))
        #expect(store.clip(for: "學生") != nil)
        let duration = try AVAudioPlayer(contentsOf: clip).duration
        #expect(duration > 0.6 && duration < 1.2, "half a second of speech plus a short lead-in and tail, not the silence")
        #expect(store.count == 1)
    }

    @Test("SAY-11 deleting recordings removes them all")
    func deletesAll() throws {
        let store = VoiceClipStore(directory: folder)
        store.save(try makeTake(), for: .fixture(simplified: "你好"))
        #expect(store.count == 1)

        store.deleteAll()
        #expect(store.count == 0)
        #expect(store.clip(for: "你好") == nil)
    }

    @Test("SAY-11 the default is to play the learner's recording after the reference voice")
    func defaultMode() {
        let suite = "cleanpinyin.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        #expect(MyVoiceMode.current(in: defaults) == .afterReference)
        defaults.set(MyVoiceMode.insteadOfReference.rawValue, forKey: MyVoiceMode.preferenceKey)
        #expect(MyVoiceMode.current(in: defaults) == .insteadOfReference)
    }
}
