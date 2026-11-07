import Foundation

enum SpeechEngine: String, CaseIterable, Identifiable {
    case apple
    case whisper

    static let preferenceKey = "speech.engine"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .apple: return "Apple"
        case .whisper: return "Whisper"
        }
    }

    var summary: String {
        switch self {
        case .apple: return "Built into iOS. Stops listening the moment it hears the right word."
        case .whisper: return "Whisper small, a one-time 216 MB download. Checks your answer once you stop speaking."
        }
    }

    // Saved per device: the Whisper model is downloaded to this iPhone
    static func current(in defaults: UserDefaults = .standard) -> SpeechEngine {
        defaults.string(forKey: preferenceKey).flatMap(SpeechEngine.init(rawValue:)) ?? .apple
    }
}
