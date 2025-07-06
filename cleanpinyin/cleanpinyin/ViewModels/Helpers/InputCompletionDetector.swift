import Foundation

class InputCompletionDetector {
    private var autoCheckTimer: Timer?
    private let validator = PinyinValidator()
    
    func checkForAutoSubmit(
        input: String,
        word: VocabularyItem,
        requireTones: Bool,
        feedbackState: FeedbackState,
        onSubmit: @escaping () -> Void
    ) {
        autoCheckTimer?.invalidate()
        
        guard !requireTones else { return }
        
        guard feedbackState == .none,
              !input.isEmpty else { return }
        
        let inputLooksComplete = validator.isInputLikelyComplete(
            input,
            for: word,
            requireTones: requireTones
        )
        
        if inputLooksComplete {
            autoCheckTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timing.autoSubmitDelay, repeats: false) { _ in
                onSubmit()
            }
        }
    }
    
    func cancelPendingChecks() {
        autoCheckTimer?.invalidate()
        autoCheckTimer = nil
    }
    
    deinit {
        cancelPendingChecks()
    }
}