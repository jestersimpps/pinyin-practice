import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel: PracticeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var showHint = false

    init(mode: LearningMode) {
        _viewModel = StateObject(wrappedValue: PracticeViewModel(mode: mode))
    }

    var body: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
                .onTapGesture(perform: dismissKeyboard)

            VStack(spacing: 0) {
                header

                if viewModel.hasWords {
                    practiceContent
                } else {
                    emptyState
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: startPractice)
        .onDisappear(perform: viewModel.saveSessionOnExit)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = frame.height }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showingChapterCompletion) {
            if let chapter = viewModel.completedChapter, let progress = viewModel.completedChapterProgress {
                ChapterCompletionView(
                    chapter: chapter,
                    chapterProgress: progress,
                    nextChapter: viewModel.nextChapter,
                    onContinue: {
                        viewModel.continueToNextChapter()
                        resetForNewRound()
                    },
                    onReview: {
                        viewModel.startNewRound()
                        resetForNewRound()
                    },
                    onBackToChapters: { dismiss() }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingPracticeCompletion) {
            if let stats = viewModel.sessionStats {
                PracticeCompletionView(
                    sessionStats: stats,
                    onContinue: {
                        viewModel.startNewRound()
                        resetForNewRound()
                    },
                    onFinish: { dismiss() }
                )
                .interactiveDismissDisabled()
            }
        }
        .onChange(of: viewModel.feedbackState) { _, newState in
            switch newState {
            case .correct:
                showHint = false
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .incorrect, .partial:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .none:
                break
            }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width > 100, viewModel.feedbackState == .none {
                        skipWord()
                    } else if value.translation.width < -100, hintsAvailable {
                        toggleHint()
                    }
                }
        )
    }

    // MARK: - Content

    private var practiceContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if let word = viewModel.currentWord {
                            AdaptiveCharacterDisplay(
                                word: word,
                                displayText: viewModel.displayText(for: word),
                                settings: viewModel.settings,
                                feedbackState: viewModel.feedbackState,
                                showHint: showHint,
                                isKeyboardVisible: keyboardHeight > 0,
                                spokenAnswer: viewModel.spokenAnswer,
                                speechMessage: viewModel.speechMessage ?? preparingStatus,
                                onSpeak: viewModel.speakCurrentWord
                            )
                            .padding(.horizontal, 16)
                            .id("character")
                        }
                    }
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: keyboardHeight) { _, newValue in
                    guard newValue > 0 else { return }
                    withAnimation { proxy.scrollTo("character", anchor: .top) }
                }
            }

            MobileInputZone(
                text: $viewModel.userInput,
                isFocused: $isInputFocused,
                feedbackState: viewModel.feedbackState,
                showHintButton: hintsAvailable && viewModel.feedbackState == .none,
                micState: micState,
                onMicTap: { Task { await viewModel.toggleListening() } },
                onCheck: viewModel.checkAnswer,
                onNext: goToNextWord,
                onSkip: skipWord,
                onHintToggle: toggleHint
            )
            .disabled(viewModel.isPracticeComplete)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color("SecondaryText"))
            Text("Nothing to practise")
                .font(.title3.weight(.semibold))
                .foregroundColor(Color("PrimaryText"))
            Text("There are no words in this selection yet. Pick other levels or chapters to continue.")
                .font(.body)
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            PrimaryButton(title: "Back", icon: "chevron.left", action: { dismiss() })
                .frame(width: 160)
            Spacer()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                headerButton(icon: "chevron.left", color: Color("PrimaryText"), label: "Close practice") { dismiss() }

                Spacer()

                VStack(spacing: 2) {
                    Text("Practice")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("PrimaryText"))

                    Text(practiceSubtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))
                }

                Spacer()

                headerButton(icon: "gearshape.fill", color: Color("SecondaryText"), label: "Settings") { showingSettings = true }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            if viewModel.hasWords {
                ProgressBar(progress: viewModel.progressPercentage)
                statsRow
            }
        }
    }

    private func headerButton(icon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color("SecondaryBackground").opacity(0.5)))
        }
        .accessibilityLabel(label)
    }

    private var statsRow: some View {
        HStack(spacing: 20) {
            statItem(icon: "flag.fill", color: .blue, text: "\(viewModel.wordsCompleted)/\(viewModel.totalWords)")
                .accessibilityLabel("\(viewModel.wordsCompleted) of \(viewModel.totalWords) words done")

            statItem(
                icon: "target",
                color: viewModel.accuracy == "0%" ? Color("SecondaryText") : Color("SuccessGreen"),
                text: viewModel.accuracy
            )
            .accessibilityLabel("Accuracy \(viewModel.accuracy)")

            statItem(
                icon: "bolt.fill",
                color: viewModel.combo == 0 ? Color("SecondaryText") : .orange,
                text: "\(viewModel.combo)"
            )
            .accessibilityLabel("\(viewModel.combo) correct in a row")
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
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
    }

    // MARK: - Actions

    private var hintsAvailable: Bool {
        viewModel.settings.showPronunciationHints || viewModel.settings.showCharacterHints
    }

    private func startPractice() {
        viewModel.begin()
        guard viewModel.hasWords else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isInputFocused = true
        }
    }

    private func goToNextWord() {
        viewModel.nextWord()
        showHint = false
        isInputFocused = true
    }

    private func skipWord() {
        viewModel.skipWord()
        showHint = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func toggleHint() {
        showHint.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

    private var preparingStatus: String? {
        if case .preparing(let status) = viewModel.listeningState { return status }
        return nil
    }

    private var micState: MobileInputZone.MicState? {
        guard viewModel.canAnswerBySpeaking else { return nil }
        switch viewModel.listeningState {
        case .idle: return .idle
        case .preparing: return .preparing
        case .listening: return .listening
        }
    }

    private var practiceSubtitle: String {
        switch viewModel.mode {
        case .chapters: return "Chapter Practice"
        case .custom: return "Custom Practice"
        case .review: return "Review Mistakes"
        case .levels(let levels):
            let names = levels.sorted().map { "HSK \($0)" }.joined(separator: ", ")
            return viewModel.settings.practiceMode == .random ? "\(names) · Random" : names
        }
    }
}
