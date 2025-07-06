import Foundation
import SwiftUI

final class DIContainer: ObservableObject {
    private lazy var storage: StorageService = UserDefaultsStorage()
    
    private lazy var vocabularyLoader: VocabularyLoading = VocabularyLoader()
    private lazy var chapterOrganizer: ChapterOrganizing = ChapterOrganizer()
    
    private(set) lazy var vocabularyService: VocabularyService = {
        VocabularyService(loader: vocabularyLoader, organizer: chapterOrganizer)
    }()
    
    private lazy var progressTracker: ProgressTracking = ProgressTracker(storage: storage)
    private lazy var settingsManager: SettingsManaging = SettingsManager(storage: storage)
    private lazy var sessionManager: SessionManaging = SessionManager(storage: storage, settings: settingsManager.settings)
    
    private lazy var wordLoader: WordLoading = WordLoader(
        vocabularyService: vocabularyService,
        progressTracker: progressTracker
    )
    
    private lazy var inputValidator: InputValidating = InputValidator()
    
    private lazy var chapterProgressManager: ChapterProgressManaging = ChapterProgressManager(
        vocabularyService: vocabularyService,
        progressTracker: progressTracker
    )
    
    func makePracticeViewModel() -> PracticeViewModel {
        return PracticeViewModel(
            wordLoader: wordLoader,
            inputValidator: inputValidator,
            chapterProgressManager: chapterProgressManager,
            progressTracker: progressTracker,
            sessionManager: sessionManager,
            settingsManager: settingsManager
        )
    }
    
    func makeProgressService() -> UserProgressService {
        return UserProgressService(
            progressTracker: progressTracker,
            settingsManager: settingsManager,
            sessionManager: sessionManager
        )
    }
}

extension DIContainer {
    static let shared = DIContainer()
}

struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}