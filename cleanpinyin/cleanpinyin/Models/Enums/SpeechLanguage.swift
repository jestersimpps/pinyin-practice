import Foundation

enum SpeechLanguage: String, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var name: String {
        switch self {
        case .chinese: return "Chinese"
        case .english: return "English"
        }
    }

    // The dialect the app prefers when it picks a voice automatically
    var mainCode: String {
        switch self {
        case .chinese: return "zh-CN"
        case .english: return "en-US"
        }
    }

    var sample: String {
        switch self {
        case .chinese: return "你好，欢迎学习中文"
        case .english: return "Hello, welcome to EchoLingo"
        }
    }

    // Saved per device, since each iPhone has its own installed voices
    var preferenceKey: String { "voice.\(rawValue)" }

    // Mandarin voices from mainland China and Taiwan; Cantonese (zh-HK) is a different spoken language
    func includes(voiceLanguage code: String) -> Bool {
        switch self {
        case .chinese: return code == "zh-CN" || code == "zh-TW"
        case .english: return code.hasPrefix("en-")
        }
    }
}
