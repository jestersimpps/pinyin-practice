import SwiftUI

struct PracticeViewRedesigned: View {
    @StateObject private var viewModel = PracticeViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingSettings = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            Color.primaryBackground
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                NavigationHeader(
                    title: "Practice",
                    subtitle: practiceSubtitle,
                    leftAction: { dismiss() },
                    rightAction: { showingSettings = true },
                    rightIcon: "gearshape.fill"
                )
                
                ProgressBar(progress: viewModel.progressPercentage)
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        if keyboardHeight == 0 {
                            CompactStatsBar(
                                progress: "\(viewModel.wordsCompleted)/\(viewModel.totalWords)",
                                accuracy: viewModel.accuracy,
                                streak: viewModel.currentStreak
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                if let word = viewModel.currentWord {
                                    ResponsiveCharacterDisplay(
                                        character: word.chinese,
                                        translation: word.english,
                                        showTranslation: UserProgressService.shared.settings.showEnglishTranslation,
                                        feedbackState: mapFeedbackState(viewModel.feedbackState),
                                        hint: word.hint,
                                        showHint: viewModel.showHint,
                                        isCompact: keyboardHeight > 0
                                    )
                                    .padding(.horizontal, 20)
                                    .padding(.top, keyboardHeight > 0 ? 12 : 20)
                                }
                                
                                inputSection
                                    .padding(.horizontal, 20)
                                
                                if keyboardHeight > 0 {
                                    Color.clear
                                        .frame(height: keyboardHeight - geometry.safeAreaInsets.bottom + 20)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupKeyboardObservers()
            isInputFocused = true
        }
        .sheet(isPresented: $showingSettings) {
            SettingsViewRefactored()
        }
    }
    
    private var practiceSubtitle: String? {
        switch UserProgressService.shared.settings.practiceMode {
        case .reviewMistakes:
            return "Review Mode"
        case .unlearned:
            return "New Words"
        default:
            return UserProgressService.shared.settings.requireTones ? nil : "Simple Mode"
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 12) {
            if !UserProgressService.shared.settings.requireTones && viewModel.feedbackState == .none {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.vibrantOrange)
                        .font(.caption)
                    Text("Tones not required")
                        .font(Typography.captionFont)
                        .foregroundColor(.vibrantOrange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.vibrantOrange.opacity(0.1))
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            HStack(spacing: 12) {
                PinyinInputField(
                    text: $viewModel.userInput,
                    placeholder: "Enter pinyin...",
                    feedbackState: mapInputFeedbackState(viewModel.feedbackState),
                    isFocused: _isInputFocused,
                    onSubmit: handleSubmit,
                    onClear: { viewModel.userInput = "" }
                )
                
                if keyboardHeight > 0 {
                    actionButtons
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            
            if keyboardHeight == 0 {
                actionButtons
                    .transition(.opacity)
            }
            
            FeedbackMessage(
                feedbackState: mapMessageFeedbackState(viewModel.feedbackState),
                correctAnswer: viewModel.feedbackState == .incorrect ? getCorrectAnswer() : nil,
                requireTones: UserProgressService.shared.settings.requireTones
            )
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if UserProgressService.shared.settings.showHints && 
               viewModel.currentWord?.hint != nil && 
               viewModel.feedbackState == .none {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleHint()
                    }
                }) {
                    Image(systemName: viewModel.showHint ? "lightbulb.fill" : "lightbulb")
                        .font(.title3)
                        .foregroundColor(viewModel.showHint ? .vibrantOrange : .secondaryText)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(viewModel.showHint ? Color.vibrantOrange.opacity(0.15) : Color.secondaryBackground.opacity(0.5))
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            if viewModel.feedbackState != .none {
                Button(action: {
                    withAnimation {
                        viewModel.nextWord()
                        isInputFocused = true
                    }
                }) {
                    HStack {
                        Text("Next")
                            .font(Typography.primaryButtonFont)
                        Image(systemName: "arrow.right")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.midnightGreen)
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func handleSubmit() {
        if viewModel.feedbackState == .none {
            viewModel.checkAnswer()
        } else {
            viewModel.nextWord()
            isInputFocused = true
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func hideKeyboard() {
        isInputFocused = false
    }
    
    private func mapFeedbackState(_ state: PracticeViewModel.FeedbackState) -> ResponsiveCharacterDisplay.FeedbackState {
        switch state {
        case .none: return .none
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
    
    private func mapInputFeedbackState(_ state: PracticeViewModel.FeedbackState) -> PinyinInputField.FeedbackState {
        switch state {
        case .none: return .none
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
    
    private func mapMessageFeedbackState(_ state: PracticeViewModel.FeedbackState) -> FeedbackMessage.FeedbackState {
        switch state {
        case .none: return .none
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
    
    private func getCorrectAnswer() -> String? {
        guard let word = viewModel.currentWord else { return nil }
        return UserProgressService.shared.settings.requireTones ? word.pinyin : removeTones(from: word.pinyin)
    }
    
    private func removeTones(from pinyin: String) -> String {
        var result = pinyin
        
        let toneMap = [
            "ā": "a", "á": "a", "ǎ": "a", "à": "a",
            "ē": "e", "é": "e", "ě": "e", "è": "e",
            "ī": "i", "í": "i", "ǐ": "i", "ì": "i",
            "ō": "o", "ó": "o", "ǒ": "o", "ò": "o",
            "ū": "u", "ú": "u", "ǔ": "u", "ù": "u",
            "ǖ": "ü", "ǘ": "ü", "ǚ": "ü", "ǜ": "ü"
        ]
        
        for (toned, plain) in toneMap {
            result = result.replacingOccurrences(of: toned, with: plain)
        }
        
        result = result.replacingOccurrences(of: "[1-4]", with: "", options: .regularExpression)
        
        return result
    }
}

struct PracticeViewRedesigned_Previews: PreviewProvider {
    static var previews: some View {
        PracticeViewRedesigned()
    }
}