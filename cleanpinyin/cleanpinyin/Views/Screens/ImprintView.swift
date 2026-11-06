import SwiftUI

struct ImprintView: View {
    @StateObject private var viewModel = ImprintViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedChapters: Set<String> = []
    @State private var showingChapterSelection = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    headerSection

                    if viewModel.isPlaying {
                        playingSection
                    } else {
                        setupSection
                    }

                    Spacer()

                    controlsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.chapters = selectedChapters
            }
            .onDisappear {
                viewModel.stop()
            }
            .sheet(isPresented: $showingChapterSelection) {
                ImprintChapterSelectionView(selectedChapters: $selectedChapters) {
                    viewModel.chapters = selectedChapters
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Close") {
                    viewModel.stop()
                    dismiss()
                }
                .foregroundColor(.orange)

                Spacer()

                Text("Imprint Mode")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryText"))

                Spacer()

                // Balances the Cancel button so the title stays centered
                Text("Close")
                    .opacity(0)
                    .accessibilityHidden(true)
            }

            Text("Audio-focused learning with visual support")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("SecondaryText"))
                .multilineTextAlignment(.center)
        }
    }

    private var setupSection: some View {
        VStack(spacing: 20) {
            Button(action: { showingChapterSelection = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Chapters")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("PrimaryText"))

                        Text(chaptersDescription)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("SecondaryText"))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("SecondaryBackground"))
                )
            }
            .accessibilityIdentifier("imprint.selectChapters")

            VStack(alignment: .leading, spacing: 12) {
                Text("How Imprint Mode Works:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("PrimaryText"))

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow("1", "You hear the English meaning")
                    instructionRow("2", "A short pause to recall the Chinese")
                    instructionRow("3", "You hear the Chinese word")
                    instructionRow("4", "The character, pinyin and meaning stay on screen")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("SecondaryBackground"))
            )
        }
    }

    private var playingSection: some View {
        VStack(spacing: 24) {
            if let word = viewModel.currentWord {
                VStack(spacing: 16) {
                    Text(UserProgressService.shared.settings.useTraditional ? word.traditional : word.simplified)
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundColor(Color("PrimaryText"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .frame(height: 120)
                        .opacity(isRevealed ? 1 : 0)
                        .accessibilityHidden(!isRevealed)

                    Text(word.shortTranslation)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Text(word.pinyin)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("PrimaryText").opacity(0.7))
                        .opacity(isRevealed ? 1 : 0)
                        .accessibilityHidden(!isRevealed)
                }
                .animation(.easeInOut(duration: 0.3), value: isRevealed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("SecondaryBackground").opacity(0.3))
                )
            }

            VStack(spacing: 8) {
                HStack {
                    Text("\(viewModel.currentIndex + 1) of \(viewModel.totalWords)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))

                    Spacer()

                    Text(viewModel.playbackState.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }

                ProgressView(value: viewModel.progress)
                    .tint(.orange)
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 20) {
            if viewModel.isPlaying {
                Button(action: { viewModel.pause() }) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }
                .accessibilityLabel("Pause")

                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("SecondaryText"))
                }
                .accessibilityLabel("Stop")
            } else {
                Button(action: { viewModel.start() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))

                        Text(viewModel.canResume ? "Resume" : "Start Imprint")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.orange)
                    )
                }
                .disabled(selectedChapters.isEmpty)
                .opacity(selectedChapters.isEmpty ? 0.5 : 1.0)
            }
        }
    }

    private var isRevealed: Bool {
        switch viewModel.playbackState {
        case .speakingEnglish, .pausing: return false
        case .idle, .speakingChinese, .completed: return true
        }
    }

    private var chaptersDescription: String {
        switch selectedChapters.count {
        case 0: return "No chapters selected"
        case 1: return "1 chapter selected"
        default: return "\(selectedChapters.count.counted("chapter")) selected"
        }
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color("VibrantOrange"))
                )

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("SecondaryText"))

            Spacer()
        }
    }
}

final class ImprintViewModel: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentWord: VocabularyItem?
    @Published private(set) var currentIndex = 0
    @Published private(set) var totalWords = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published var chapters: Set<String> = []

    private let vocabularyService: VocabularyServiceProtocol
    private let speech: SpeechSpeaking
    private let pauseBeforeChinese: TimeInterval
    private let pauseAfterWord: TimeInterval
    private var words: [VocabularyItem] = []
    // Invalidates pending playback steps after pause/stop/restart
    private var playbackGeneration = 0

    enum PlaybackState {
        case idle
        case speakingEnglish
        case pausing
        case speakingChinese
        case completed

        var description: String {
            switch self {
            case .idle: return "Ready"
            case .speakingEnglish: return "English"
            case .pausing: return "Think…"
            case .speakingChinese: return "Chinese"
            case .completed: return "Completed"
            }
        }
    }

    init(
        vocabularyService: VocabularyServiceProtocol = VocabularyService.shared,
        speech: SpeechSpeaking = TextToSpeechService.shared,
        pauseBeforeChinese: TimeInterval = 2.0,
        pauseAfterWord: TimeInterval = 1.5
    ) {
        self.vocabularyService = vocabularyService
        self.speech = speech
        self.pauseBeforeChinese = pauseBeforeChinese
        self.pauseAfterWord = pauseAfterWord
    }

    var canResume: Bool {
        !words.isEmpty && currentIndex < words.count && currentWord != nil
    }

    func start() {
        if !canResume {
            words = vocabularyService.vocabularyForChapters(chapters)
            guard !words.isEmpty else { return }
            currentIndex = 0
        }

        totalWords = words.count
        isPlaying = true
        playCurrentWord()
    }

    func pause() {
        playbackGeneration += 1
        isPlaying = false
        playbackState = .idle
        speech.stopSpeaking()
    }

    func stop() {
        pause()
        currentIndex = 0
        progress = 0
        currentWord = nil
        words = []
    }

    private func playCurrentWord() {
        guard currentIndex < words.count else {
            completePlayback()
            return
        }

        let word = words[currentIndex]
        currentWord = word
        progress = Double(currentIndex) / Double(totalWords)

        playbackGeneration += 1
        let generation = playbackGeneration
        let chinese = UserProgressService.shared.settings.useTraditional ? word.traditional : word.simplified

        playbackState = .speakingEnglish
        speech.speak(english: word.shortTranslation) { [weak self] in
            self?.step(generation: generation, after: 0) { this in
                this.playbackState = .pausing
                this.step(generation: generation, after: this.pauseBeforeChinese) { this in
                    this.playbackState = .speakingChinese
                    this.speech.speak(chinese: chinese) { [weak this] in
                        this?.step(generation: generation, after: this?.pauseAfterWord ?? 0) { this in
                            this.currentIndex += 1
                            this.playCurrentWord()
                        }
                    }
                }
            }
        }
    }

    private func step(generation: Int, after delay: TimeInterval, action: @escaping (ImprintViewModel) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isPlaying, self.playbackGeneration == generation else { return }
            action(self)
        }
    }

    private func completePlayback() {
        isPlaying = false
        playbackState = .completed
        progress = 1.0
        words = []
        currentIndex = 0
    }
}

struct ImprintChapterSelectionView: View {
    @Binding var selectedChapters: Set<String>
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LevelTabBar(
                    tabs: LevelTabBar.Tab.hskLevels(),
                    selectedLevel: $selectedLevel,
                    selectedColor: .orange
                )

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(vocabularyService.chaptersForLevel(selectedLevel)) { chapter in
                            ImprintChapterCard(
                                chapter: chapter,
                                isSelected: selectedChapters.contains(chapter.id),
                                action: { toggleChapter(chapter.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }

                HStack {
                    Text("\(selectedChapters.count.counted("chapter")) selected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))

                    Spacer()

                    Button("Done") {
                        onComplete()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.orange)
                    )
                    .disabled(selectedChapters.isEmpty)
                    .opacity(selectedChapters.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color("SecondaryBackground"))
            }
            .navigationTitle("Select Chapters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }

    private func toggleChapter(_ chapterId: String) {
        if selectedChapters.contains(chapterId) {
            selectedChapters.remove(chapterId)
        } else {
            selectedChapters.insert(chapterId)
        }
    }
}

private struct ImprintChapterCard: View {
    let chapter: Chapter
    let isSelected: Bool
    let action: () -> Void

    private var cardHeadline: String {
        switch chapter.kind {
        case .curriculum: return "Chapter \(chapter.chapterNumber)"
        case .frequencySet: return "Set \(chapter.chapterNumber)"
        case .custom: return chapter.title
        }
    }

    private var cardSubtitle: String {
        chapter.kind == .custom ? chapter.wordCount.counted("word") : chapter.title
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(cardHeadline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))

                Text(cardSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : Color("SecondaryText"))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .orange : Color("SecondaryBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : Color("SecondaryText").opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityIdentifier("imprint.\(chapter.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
