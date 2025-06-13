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
                .onTapGesture {
                    if keyboardHeight > 0 {
                        isInputFocused = false
                    }
                }
            
            VStack(spacing: 0) {
                // Always use compact header
                compactHeader
                
                // Main content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Character display
                            if let word = viewModel.currentWord {
                                AdaptiveCharacterDisplay(
                                    word: word,
                                    feedbackState: mapFeedbackState(viewModel.feedbackState),
                                    showHint: showHint,
                                    isKeyboardVisible: keyboardHeight > 0,
                                    onHintToggle: { showHint.toggle() }
                                )
                                .padding(.horizontal, 16)
                                .id("character")
                            }
                            
                            
                            // Spacer for keyboard
                            if keyboardHeight > 0 {
                                Color.clear
                                    .frame(height: keyboardHeight - 100)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: keyboardHeight) { _, newValue in
                        if newValue > 0 {
                            withAnimation {
                                proxy.scrollTo("character", anchor: .top)
                            }
                        }
                    }
                }
                
                // Input zone
                MobileInputZone(
                    text: $viewModel.userInput,
                    isFocused: $isInputFocused,
                    feedbackState: mapInputFeedbackState(viewModel.feedbackState),
                    onSubmit: handleSubmit,
                    onSkip: {
                        viewModel.skipWord()
                        showHint = false
                        isInputFocused = true
                    },
                    onHintToggle: { showHint.toggle() },
                    showHintButton: UserProgressService.shared.settings.showPronunciationHints && viewModel.feedbackState == .none,
                    showSkipButton: viewModel.feedbackState == .none
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupKeyboardObservers()
            
            // Initialize learning mode based on current settings
            let settings = UserProgressService.shared.settings
            if !settings.selectedChapters.isEmpty {
                viewModel.startChapterPractice(chapters: settings.selectedChapters)
            } else if !UserProgressService.shared.progress.incorrectWords.isEmpty && 
                      UserProgressService.shared.canPracticeReview {
                viewModel.startReviewPractice(incorrectWords: UserProgressService.shared.progress.incorrectWords)
            } else {
                viewModel.startCustomPractice(levels: settings.selectedHSKLevels)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
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
                        // Load next chapter
                        viewModel.showingChapterCompletion = false
                        viewModel.loadNextChapter()
                        // Reset state for new chapter
                        showHint = false
                        isInputFocused = true
                    },
                    onReview: {
                        // Start review mode for this chapter
                        viewModel.showingChapterCompletion = false
                        viewModel.reloadWordsIfNeeded()
                    }
                )
            }
        }
        .onChange(of: viewModel.feedbackState) { _, newState in
            if newState == .correct {
                showHint = false
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if newState == .incorrect {
                // Haptic feedback
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && viewModel.feedbackState == .none {
                        // Swipe right to skip
                        viewModel.skipWord()
                        showHint = false
                        isInputFocused = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else if value.translation.width < -100 && UserProgressService.shared.settings.showPronunciationHints {
                        // Swipe left to toggle hints
                        showHint.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
        )
    }
    
    // MARK: - Headers
    
    private var fullHeader: some View {
        VStack(spacing: 0) {
            NavigationHeader(
                title: "Practice",
                subtitle: practiceSubtitle,
                leftAction: { dismiss() },
                rightAction: { showingSettings = true },
                rightIcon: "gearshape.fill"
            )
            
            ProgressBar(progress: viewModel.progressPercentage)
            
            // Stats row
            HStack(spacing: 20) {
                // Progress
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(viewModel.wordsCompleted)/\(viewModel.totalWords)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Accuracy
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(viewModel.accuracy == "0%" ? Color("SecondaryText") : Color(red: 0.2, green: 0.8, blue: 0.4))
                    Text(viewModel.accuracy)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Streak
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(viewModel.currentStreak == 0 ? Color("SecondaryText") : .orange)
                    Text("\(viewModel.currentStreak)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(Color("PrimaryText"))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("SecondaryBackground").opacity(0.3))
        }
    }
    
    private var compactHeader: some View {
        VStack(spacing: 0) {
            // Navigation row with title
            HStack {
                // Back button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color("PrimaryText"))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color("SecondaryBackground").opacity(0.5))
                        )
                }
                
                Spacer()
                
                // Title with subtitle
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
                
                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("SecondaryText"))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color("SecondaryBackground").opacity(0.5))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Progress bar
            ProgressBar(progress: viewModel.progressPercentage)
            
            // Stats row
            HStack(spacing: 20) {
                // Progress
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(viewModel.wordsCompleted)/\(viewModel.totalWords)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Accuracy
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(viewModel.accuracy == "0%" ? Color("SecondaryText") : Color(red: 0.2, green: 0.8, blue: 0.4))
                    Text(viewModel.accuracy)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Streak
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(viewModel.currentStreak == 0 ? Color("SecondaryText") : .orange)
                    Text("\(viewModel.currentStreak)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(Color("PrimaryText"))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color("SecondaryBackground").opacity(0.3))
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSubmit() {
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
        // Determine subtitle based on the actual learning mode being used
        if let learningMode = viewModel.currentLearningMode {
            switch learningMode {
            case .chapters:
                return "Chapter Practice"
            case .review:
                return "Review Mode"
            case .levels:
                // For custom practice, show the ordering mode
                return UserProgressService.shared.settings.practiceMode == .random ? "Random Mode" : nil
            }
        }
        return nil
    }
    
    // MARK: - State Mapping
    
    private func mapFeedbackState(_ state: PracticeViewModel.FeedbackState) -> AdaptiveCharacterDisplay.FeedbackState {
        switch state {
        case .none: return .none
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
    
    private func mapInputFeedbackState(_ state: PracticeViewModel.FeedbackState) -> MobileInputZone.FeedbackState {
        switch state {
        case .none: return .none
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
    
}

// MARK: - Supporting Views

