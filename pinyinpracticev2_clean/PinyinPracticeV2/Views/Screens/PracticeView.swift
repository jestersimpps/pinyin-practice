import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel: PracticeViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.diContainer) var diContainer
    
    @State private var showingSettings = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var showHint = false
    
    init() {
        _viewModel = StateObject(wrappedValue: DIContainer.shared.makePracticeViewModel())
    }
    
    var body: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
                .onTapGesture {
                    if keyboardHeight > 0 {
                        isInputFocused = false
                    }
                }
            
            VStack(spacing: 0) {
                header
                practiceContent
                inputZone
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: handleOnAppear)
        .onDisappear(perform: viewModel.saveSessionOnExit)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showingChapterCompletion) {
            chapterCompletionView
        }
        .sheet(isPresented: $viewModel.showingPracticeCompletion) {
            practiceCompletionView
        }
        .onChange(of: viewModel.state.feedbackState) { _, newState in
            handleFeedbackChange(newState)
        }
        .gesture(swipeGesture)
        .keyboardAware { height in
            keyboardHeight = height
        }
    }
    
    private var header: some View {
        PracticeHeader(
            title: "Practice",
            subtitle: practiceSubtitle,
            progress: viewModel.state.progressPercentage,
            wordsCompleted: viewModel.state.wordsCompleted,
            totalWords: viewModel.state.totalWords,
            accuracy: viewModel.accuracy,
            streak: viewModel.currentStreak,
            onBack: { dismiss() },
            onSettings: { showingSettings = true }
        )
    }
    
    private var practiceContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if let word = viewModel.state.currentWord {
                        AdaptiveCharacterDisplay(
                            word: word,
                            feedbackState: viewModel.state.feedbackState,
                            showHint: showHint,
                            isKeyboardVisible: keyboardHeight > 0,
                            onHintToggle: { showHint.toggle() }
                        )
                        .padding(.horizontal, 16)
                        .id("character")
                    }
                    
                    if keyboardHeight > 0 {
                        Color.clear
                            .frame(height: keyboardHeight - 100)
                    }
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                if keyboardHeight > 0 {
                    isInputFocused = false
                }
            }
            .onChange(of: keyboardHeight) { _, newValue in
                if newValue > 0 {
                    withAnimation {
                        proxy.scrollTo("character", anchor: .top)
                    }
                }
            }
        }
    }
    
    private var inputZone: some View {
        MobileInputZone(
            text: $viewModel.state.userInput,
            isFocused: $isInputFocused,
            feedbackState: viewModel.state.feedbackState,
            onSubmit: handleSubmit,
            onSkip: handleSkip,
            onHintToggle: { showHint.toggle() },
            showHintButton: diContainer.makeProgressService().settings.showPronunciationHints && viewModel.state.feedbackState == .none,
            showSkipButton: viewModel.state.feedbackState == .none
        )
        .disabled(viewModel.state.isPracticeComplete)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var chapterCompletionView: some View {
        Group {
            if let chapter = viewModel.completedChapter,
               let progress = viewModel.completedChapterProgress {
                ChapterCompletionView(
                    chapter: chapter,
                    chapterProgress: progress,
                    onContinue: {
                        viewModel.showingChapterCompletion = false
                        viewModel.loadNextChapter()
                        resetForNewChapter()
                    },
                    onReview: {
                        viewModel.showingChapterCompletion = false
                        viewModel.reloadWords()
                    }
                )
            }
        }
    }
    
    private var practiceCompletionView: some View {
        Group {
            if let stats = viewModel.sessionStats {
                PracticeCompletionView(
                    sessionStats: stats,
                    onContinue: {
                        viewModel.showingPracticeCompletion = false
                        viewModel.reloadWords()
                        resetForNewSession()
                    },
                    onReview: {
                        dismiss()
                    }
                )
            }
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                if value.translation.width > Constants.UI.swipeThreshold && viewModel.state.feedbackState == .none {
                    handleSkip()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else if value.translation.width < -Constants.UI.swipeThreshold && 
                          diContainer.makeProgressService().settings.showPronunciationHints {
                    showHint.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
    
    private func handleOnAppear() {
        let progressService = diContainer.makeProgressService()
        let settings = progressService.settings
        
        if settings.isReviewMode {
            let incorrectWords = progressService.getIncorrectWords()
            viewModel.startPractice(mode: .review(incorrectWords))
            progressService.updateSettings { $0.isReviewMode = false }
            progressService.updateSettings { $0.lastPracticeMode = .review }
        } else if !settings.selectedChapters.isEmpty {
            viewModel.startPractice(mode: .chapters(settings.selectedChapters))
            progressService.updateSettings { $0.lastPracticeMode = .chapters }
        } else {
            viewModel.startPractice(mode: .levels(settings.selectedHSKLevels))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Practice.focusDelay) {
            isInputFocused = true
        }
    }
    
    private func handleSubmit() {
        guard !viewModel.state.isPracticeComplete else { return }
        
        if viewModel.state.feedbackState == .none {
            viewModel.checkAnswer()
        } else {
            viewModel.nextWord()
            showHint = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
    
    private func handleSkip() {
        viewModel.skipWord()
        showHint = false
        isInputFocused = true
    }
    
    private func handleFeedbackChange(_ newState: FeedbackState) {
        switch newState {
        case .correct:
            showHint = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .incorrect:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        default:
            break
        }
    }
    
    private func resetForNewChapter() {
        showHint = false
        isInputFocused = true
    }
    
    private func resetForNewSession() {
        showHint = false
        isInputFocused = true
    }
    
    private var practiceSubtitle: String? {
        guard let learningMode = viewModel.state.learningMode else { return nil }
        
        switch learningMode {
        case .chapters:
            return "Chapter Practice"
        case .review:
            return "Review Mode"
        case .levels:
            let progressService = diContainer.makeProgressService()
            return progressService.settings.practiceMode == .random ? "Random Mode" : nil
        }
    }
    
}