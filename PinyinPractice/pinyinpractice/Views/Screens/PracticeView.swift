import SwiftUI

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingSettings = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @State private var previousPracticeMode: PracticeSettings.PracticeMode?
    
    var body: some View {
        ZStack {
            Color("PrimaryBackground")
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
                        if viewModel.feedbackState != .incorrect && !viewModel.wasSkipped {
                            CompactStatsBar(
                                progress: "\(viewModel.wordsCompleted)/\(viewModel.totalWords)",
                                accuracy: viewModel.accuracy,
                                streak: viewModel.currentStreak
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.feedbackState)
                        }
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                FeedbackMessage(
                                    feedbackState: mapMessageFeedbackState(viewModel.feedbackState),
                                    correctAnswer: viewModel.feedbackState == .incorrect ? getCorrectAnswer() : nil,
                                    requireTones: UserProgressService.shared.settings.requireTones
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                if let word = viewModel.currentWord {
                                    ResponsiveCharacterDisplay(
                                        character: UserProgressService.shared.settings.useTraditional ? word.traditional : word.simplified,
                                        translation: word.english,
                                        showTranslation: UserProgressService.shared.settings.showEnglishTranslation || viewModel.feedbackState == .incorrect || viewModel.wasSkipped,
                                        feedbackState: mapFeedbackState(viewModel.feedbackState),
                                        hint: generateHint(for: word),
                                        characterHint: word.characterHint,
                                        showHint: viewModel.showHint,
                                        showPronunciationHint: UserProgressService.shared.settings.showPronunciationHints,
                                        showCharacterHint: UserProgressService.shared.settings.showCharacterHints,
                                        isCompact: keyboardHeight > 0,
                                        additionalInfo: ResponsiveCharacterDisplay.AdditionalInfo(
                                            traditional: UserProgressService.shared.settings.useTraditional ? 
                                                (word.simplified != word.traditional ? word.simplified : nil) : 
                                                (word.traditional != word.simplified ? word.traditional : nil),
                                            radical: word.radical,
                                            partOfSpeech: word.partOfSpeech.map(mapPartOfSpeech),
                                            frequency: word.frequency
                                        ),
                                        showAdditionalInfo: UserProgressService.shared.settings.showAdditionalInfo && (viewModel.feedbackState == .incorrect || viewModel.wasSkipped)
                                    )
                                    .padding(.horizontal, 20)
                                    .padding(.top, keyboardHeight > 0 && viewModel.feedbackState != .none ? 4 : (keyboardHeight > 0 ? 12 : 20))
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
            SettingsView()
        }
        .onChange(of: showingSettings) { oldValue, newValue in
            if oldValue && !newValue {
                // Sheet was dismissed
                if previousPracticeMode != UserProgressService.shared.settings.practiceMode {
                    viewModel.reloadWordsIfNeeded()
                }
            } else if !oldValue && newValue {
                // Sheet is being presented
                previousPracticeMode = UserProgressService.shared.settings.practiceMode
            }
        }
    }
    
    private var practiceSubtitle: String? {
        switch UserProgressService.shared.settings.practiceMode {
        case .reviewMistakes:
            return "Review Mode"
        case .random:
            return "Random Mode"
        default:
            return UserProgressService.shared.settings.requireTones ? nil : "Simple Mode"
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 12) {
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
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if UserProgressService.shared.settings.showPronunciationHints && 
               viewModel.feedbackState == .none {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.toggleHint()
                    }
                }) {
                    Image(systemName: viewModel.showHint ? "lightbulb.fill" : "lightbulb")
                        .font(.title3)
                        .foregroundColor(viewModel.showHint ? .orange : Color("SecondaryText"))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(viewModel.showHint ? Color.orange.opacity(0.15) : Color("SecondaryBackground").opacity(0.5))
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            if viewModel.feedbackState == .none {
                Button(action: {
                    withAnimation {
                        viewModel.skipWord()
                        isInputFocused = true
                    }
                }) {
                    HStack {
                        Text("Skip")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "forward.fill")
                            .font(.caption)
                    }
                    .foregroundColor(Color("SecondaryText"))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("SecondaryBackground").opacity(0.5))
                    )
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: {
                    withAnimation {
                        viewModel.nextWord()
                        isInputFocused = true
                    }
                }) {
                    HStack {
                        Text("Next")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.3, blue: 0.4))
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
        if UserProgressService.shared.settings.requireTones {
            return word.pinyin
        } else {
            // Use numeric pinyin and remove numbers for tone-free display
            return word.pinyinNumeric.replacingOccurrences(of: "[1-5]", with: "", options: .regularExpression)
        }
    }
    
    private func generateHint(for word: VocabularyItem) -> String? {
        // Use our enhanced pronunciation hint if available
        if !word.pronunciationHint.isEmpty && 
           !word.pronunciationHint.starts(with: "Pronunciation hint for") {
            return word.pronunciationHint
        }
        
        // Fallback to basic hint
        let syllableCount = word.pinyin.split(separator: " ").count
        let firstChar = word.pinyin.prefix(1)
        
        if syllableCount == 1 {
            return "Starts with '\(firstChar)'"
        } else {
            return "\(syllableCount) syllables, starts with '\(firstChar)'"
        }
    }
    
    private func mapPartOfSpeech(_ pos: String) -> String {
        let mapping: [String: String] = [
            "a": "adj.",
            "ad": "adv.",
            "ag": "adj. morph.",
            "an": "adj./n.",
            "b": "non-pred. adj.",
            "c": "conj.",
            "d": "adv.",
            "dg": "adv. morph.",
            "e": "interj.",
            "f": "direction",
            "g": "morph.",
            "h": "prefix",
            "i": "idiom",
            "j": "abbr.",
            "k": "suffix",
            "l": "fixed expr.",
            "m": "num.",
            "mg": "num. morph.",
            "n": "noun",
            "ng": "noun morph.",
            "nr": "name",
            "ns": "place",
            "nt": "org.",
            "nx": "nom. string",
            "nz": "proper n.",
            "o": "onom.",
            "p": "prep.",
            "q": "class.",
            "qt": "time class.",
            "r": "pron.",
            "rg": "pron. morph.",
            "s": "space",
            "t": "time",
            "tg": "time morph.",
            "u": "aux.",
            "v": "verb",
            "vd": "v. adv.",
            "vg": "verb morph.",
            "vn": "v./n.",
            "w": "punct.",
            "x": "other",
            "y": "modal",
            "z": "desc."
        ]
        return mapping[pos] ?? pos
    }
}