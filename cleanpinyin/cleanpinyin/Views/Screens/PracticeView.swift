import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingSettings = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var showHint = false

    var body: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
                .onTapGesture(perform: dismissKeyboard)

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if let word = viewModel.currentWord {
                                AdaptiveCharacterDisplay(
                                    word: word,
                                    feedbackState: viewModel.feedbackState,
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
                    .onTapGesture(perform: dismissKeyboard)
                    .onChange(of: keyboardHeight) { _, newValue in
                        if newValue > 0 {
                            withAnimation {
                                proxy.scrollTo("character", anchor: .top)
                            }
                        }
                    }
                }

                MobileInputZone(
                    text: $viewModel.userInput,
                    isFocused: $isInputFocused,
                    feedbackState: viewModel.feedbackState,
                    onSubmit: handleSubmit,
                    onSkip: skipWord,
                    onHintToggle: { showHint.toggle() },
                    showHintButton: UserProgressService.shared.settings.showPronunciationHints && viewModel.feedbackState == .none,
                    showSkipButton: viewModel.feedbackState == .none
                )
                .disabled(viewModel.isPracticeComplete)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: startPractice)
        .onDisappear {
            viewModel.saveSessionOnExit()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showingChapterCompletion) {
            if let chapter = viewModel.completedChapter,
               let progress = viewModel.completedChapterProgress {
                ChapterCompletionView(
                    chapter: chapter,
                    chapterProgress: progress,
                    onContinue: {
                        viewModel.showingChapterCompletion = false
                        viewModel.loadNextChapter()
                        resetForNewRound()
                    },
                    onReview: {
                        viewModel.showingChapterCompletion = false
                        viewModel.reloadWordsIfNeeded()
                        resetForNewRound()
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingPracticeCompletion) {
            if let stats = viewModel.sessionStats {
                PracticeCompletionView(
                    sessionStats: stats,
                    onContinue: {
                        viewModel.showingPracticeCompletion = false
                        viewModel.reloadWordsIfNeeded()
                        resetForNewRound()
                    },
                    onReview: {
                        dismiss()
                    }
                )
            }
        }
        .onChange(of: viewModel.feedbackState) { _, newState in
            if newState == .correct {
                showHint = false
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if newState == .incorrect {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && viewModel.feedbackState == .none {
                        skipWord()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else if value.translation.width < -100 && UserProgressService.shared.settings.showPronunciationHints {
                        showHint.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                headerButton(icon: "chevron.left", color: Color("PrimaryText")) { dismiss() }

                Spacer()

                VStack(spacing: 2) {
                    Text("Practice")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("PrimaryText"))

                    if let subtitle = practiceSubtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("SecondaryText"))
                    }
                }

                Spacer()

                headerButton(icon: "gearshape.fill", color: Color("SecondaryText")) { showingSettings = true }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            ProgressBar(progress: viewModel.progressPercentage)

            statsRow
        }
    }

    private func headerButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color("SecondaryBackground").opacity(0.5))
                )
        }
    }

    private var statsRow: some View {
        HStack(spacing: 20) {
            statItem(
                icon: "flag.fill",
                color: .blue,
                text: "\(viewModel.wordsCompleted)/\(viewModel.totalWords)"
            )

            statItem(
                icon: "target",
                color: viewModel.accuracy == "0%" ? Color("SecondaryText") : Color("SuccessGreen"),
                text: viewModel.accuracy
            )

            statItem(
                icon: "flame.fill",
                color: viewModel.currentStreak == 0 ? Color("SecondaryText") : .orange,
                text: "\(viewModel.currentStreak)"
            )
        }
        .foregroundColor(Color("PrimaryText"))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color("SecondaryBackground").opacity(0.3))
    }

    private func statItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Actions

    private func startPractice() {
        setupKeyboardObservers()

        let progressService = UserProgressService.shared
        let settings = progressService.settings

        if settings.isReviewMode {
            viewModel.startReviewPractice(incorrectWords: progressService.progress.incorrectWords)
            progressService.settings.isReviewMode = false
            progressService.settings.lastPracticeMode = .review
        } else if !settings.selectedChapters.isEmpty {
            viewModel.startChapterPractice(chapters: settings.selectedChapters)
            progressService.settings.lastPracticeMode = .chapters
        } else {
            viewModel.startCustomPractice(levels: settings.selectedHSKLevels)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isInputFocused = true
        }
    }

    private func handleSubmit() {
        guard !viewModel.isPracticeComplete else { return }

        if viewModel.feedbackState == .none {
            viewModel.checkAnswer()
        } else {
            viewModel.nextWord()
            showHint = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }

    private func skipWord() {
        viewModel.skipWord()
        showHint = false
        isInputFocused = true
    }

    private func resetForNewRound() {
        showHint = false
        isInputFocused = true
    }

    private func dismissKeyboard() {
        if keyboardHeight > 0 {
            isInputFocused = false
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

    // MARK: - Computed Properties

    private var practiceSubtitle: String? {
        switch viewModel.currentLearningMode {
        case .chapters:
            return "Chapter Practice"
        case .review:
            return "Review Mode"
        case .levels:
            return UserProgressService.shared.settings.practiceMode == .random ? "Random Mode" : nil
        case nil:
            return nil
        }
    }
}
