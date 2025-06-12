import SwiftUI

@main
struct PinyinPracticeApp: App {
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    
    init() {
        // Initialize services
        _ = VocabularyService.shared
        _ = UserProgressService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch preferredColorScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}