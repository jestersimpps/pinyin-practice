import Foundation

enum Constants {
    enum HSK {
        static let minLevel = 1
        static let maxLevel = 6
        static let customLevel = 7
        
        static let chaptersPerLevel = [
            1: 14,
            2: 14,
            3: 14,
            4: 14,
            5: 12,
            6: 12
        ]
        
        static let chapterOffsets = [
            1: 0,
            2: 14,
            3: 28,
            4: 42,
            5: 56,
            6: 68
        ]
    }
    
    enum Chapter {
        static let completionThreshold: Double = 80.0
        static let fullCompletionThreshold: Double = 100.0
    }
    
    enum Practice {
        static let autoSubmitDelay: TimeInterval = 0.5
        static let correctAnswerDelay: TimeInterval = 1.0
        static let lastWordDelay: TimeInterval = 1.5
        static let focusDelay: TimeInterval = 0.5
    }
    
    enum Animation {
        static let keyboardDuration: TimeInterval = 0.25
    }
    
    enum UI {
        static let swipeThreshold: CGFloat = 100
    }
}