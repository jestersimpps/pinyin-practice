import SwiftUI

struct ImprintView: View {
    @StateObject private var viewModel = ImprintViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedChapters: Set<String> = []
    @State private var showingChapterSelection = false

    var body: some View {
        NavigationView {
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
                Button("Cancel") {
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
                Text("Cancel")
                    .opacity(0)
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

            VStack(alignment: .leading, spacing: 12) {
                Text("How Imprint Mode Works:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("PrimaryText"))

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow("1", "English meaning is spoken")
                    instructionRow("2", "2-second pause for processing")
                    instructionRow("3", "Chinese character is spoken")
                    instructionRow("4", "Character is displayed visually")
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
                        .frame(height: 120)

                    Text(word.shortTranslation)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    Text(word.pinyin)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("PrimaryText").opacity(0.7))
                }
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

                Button(action: { viewModel.stop() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color("SecondaryText"))
                }
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

    private var chaptersDescription: String {
        switch selectedChapters.count {
        case 0: return "No chapters selected"
        case 1: return "1 chapter selected"
        default: return "\(selectedChapters.count) chapters selected"
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

class ImprintViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentWord: VocabularyItem?
    @Published var currentIndex = 0
    @Published var totalWords = 0
    @Published var progress: Double = 0
    @Published var playbackState: PlaybackState = .idle
    @Published var chapters: Set<String> = []

    private let vocabularyService = VocabularyService.shared
    private let textToSpeech = TextToSpeechService.shared
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
            case .speakingEnglish: return "Speaking English"
            case .pausing: return "Pausing..."
            case .speakingChinese: return "Speaking Chinese"
            case .completed: return "Completed"
            }
        }
    }

    var canResume: Bool {
        !words.isEmpty && currentIndex > 0 && currentIndex < words.count
    }

    func start() {
        if !canResume {
            words = vocabularyService.vocabularyForChapters(chapters)
            guard !words.isEmpty else { return }
            currentIndex = 0
        }

        totalWords = words.count
        isPlaying = true
        playNextWord()
    }

    func pause() {
        playbackGeneration += 1
        isPlaying = false
        playbackState = .idle
        textToSpeech.stopSpeaking()
    }

    func stop() {
        playbackGeneration += 1
        isPlaying = false
        playbackState = .idle
        currentIndex = 0
        progress = 0
        currentWord = nil
        words = []
        textToSpeech.stopSpeaking()
    }

    private func playNextWord() {
        guard currentIndex < words.count else {
            completePlayback()
            return
        }

        currentWord = words[currentIndex]
        progress = Double(currentIndex) / Double(totalWords)

        playCurrentWord()
    }

    private func playCurrentWord() {
        guard let word = currentWord else { return }

        playbackGeneration += 1
        let generation = playbackGeneration

        playbackState = .speakingEnglish
        textToSpeech.speak(english: word.shortTranslation, rate: 0.4)

        let englishDuration = Double(word.shortTranslation.count) * 0.1 + 1.0
        schedule(after: englishDuration, generation: generation) {
            self.playbackState = .pausing

            self.schedule(after: 2.0, generation: generation) {
                self.playbackState = .speakingChinese
                let character = UserProgressService.shared.settings.useTraditional ? word.traditional : word.simplified
                self.textToSpeech.speak(chinese: character, rate: 0.5)

                self.schedule(after: 2.0, generation: generation) {
                    self.currentIndex += 1
                    self.playNextWord()
                }
            }
        }
    }

    private func schedule(after delay: TimeInterval, generation: Int, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isPlaying, self.playbackGeneration == generation else { return }
            action()
        }
    }

    private func completePlayback() {
        playbackState = .completed
        progress = 1.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.stop()
        }
    }
}

struct ImprintChapterSelectionView: View {
    @Binding var selectedChapters: Set<String>
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = 1

    var body: some View {
        NavigationView {
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
                    Text("\(selectedChapters.count) chapters selected")
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("Chapter \(chapter.chapterNumber)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))

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
    }
}
