import Foundation

protocol SettingsManaging {
    var settings: PracticeSettings { get }
    func updateSettings(_ update: (inout PracticeSettings) -> Void)
    func cleanupSelectedChapters(unlockedChecker: (Int, Int) -> Bool)
}

final class SettingsManager: SettingsManaging {
    private let storage: StorageService
    private let settingsKey = "PracticeSettings"
    private(set) var settings: PracticeSettings
    
    init(storage: StorageService) {
        self.storage = storage
        
        if let loadedSettings = try? storage.load(PracticeSettings.self, forKey: settingsKey) {
            self.settings = loadedSettings
        } else {
            self.settings = PracticeSettings()
        }
        
        saveSettings()
    }
    
    private func saveSettings() {
        try? storage.save(settings, forKey: settingsKey)
    }
    
    func updateSettings(_ update: (inout PracticeSettings) -> Void) {
        update(&settings)
        saveSettings()
    }
    
    func cleanupSelectedChapters(unlockedChecker: (Int, Int) -> Bool) {
        var validChapters: Set<String> = []
        
        for chapterId in settings.selectedChapters {
            let identifier = ChapterIdentifier(chapterId)
            if let chapterNumber = identifier.globalChapterNumber {
                let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNumber)
                if unlockedChecker(chapterInfo.hskLevel, chapterNumber) {
                    validChapters.insert(chapterId)
                }
            }
        }
        
        settings.selectedChapters = validChapters
        saveSettings()
    }
}