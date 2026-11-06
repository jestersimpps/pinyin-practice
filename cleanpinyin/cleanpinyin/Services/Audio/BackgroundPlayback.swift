import AVFoundation
import MediaPlayer

protocol BackgroundPlaying: AnyObject {
    // Keeps the app running with the screen locked and routes lock-screen play/pause and call interruptions
    func begin(recording: Bool, controls: BackgroundPlaybackControls) throws
    func showNowPlaying(title: String, subtitle: String, isPlaying: Bool)
    // Lets the app sleep while paused; lock-screen play still reaches it
    func pause()
    func end()
}

struct BackgroundPlaybackControls {
    let isPlaying: () -> Bool
    let play: () -> Void
    let pause: () -> Void
}

final class BackgroundPlayback: BackgroundPlaying {
    static let shared = BackgroundPlayback()

    private let coordinator = AudioSessionCoordinator.shared
    // Plays silence between spoken words; iOS suspends a backgrounded app as soon as its audio stops
    private let engine = AVAudioEngine()
    private let silence = AVAudioPlayerNode()
    private var commandTargets: [Any] = []
    private var interruptionObserver: NSObjectProtocol?

    func begin(recording: Bool, controls: BackgroundPlaybackControls) throws {
        try coordinator.beginContinuous(recording: recording)
        try startSilence()
        registerCommands(controls)
        interruptionObserver = interruptionObserver ?? NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { notification in
            let type = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init)
            if type == .began { controls.pause() }
        }
    }

    func pause() {
        silence.stop()
        engine.stop()
    }

    func showNowPlaying(title: String, subtitle: String, isPlaying: Bool) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
    }

    func end() {
        pause()
        let center = MPRemoteCommandCenter.shared()
        for target in commandTargets {
            center.playCommand.removeTarget(target)
            center.pauseCommand.removeTarget(target)
            center.togglePlayPauseCommand.removeTarget(target)
        }
        commandTargets.removeAll()
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        interruptionObserver = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        coordinator.endContinuous()
    }

    private func startSilence() throws {
        guard !engine.isRunning else { return }
        if engine.attachedNodes.contains(silence) == false {
            engine.attach(silence)
        }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(silence, to: engine.mainMixerNode, format: format)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(format.sampleRate)) else { return }
        buffer.frameLength = buffer.frameCapacity
        try engine.start()
        silence.scheduleBuffer(buffer, at: nil, options: .loops)
        silence.play()
    }

    private func registerCommands(_ controls: BackgroundPlaybackControls) {
        guard commandTargets.isEmpty else { return }
        let center = MPRemoteCommandCenter.shared()
        commandTargets = [
            center.playCommand.addTarget { _ in controls.play(); return .success },
            center.pauseCommand.addTarget { _ in controls.pause(); return .success },
            center.togglePlayPauseCommand.addTarget { _ in
                controls.isPlaying() ? controls.pause() : controls.play()
                return .success
            },
        ]
    }
}
