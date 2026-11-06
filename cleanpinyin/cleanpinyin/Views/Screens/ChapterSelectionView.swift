import SwiftUI

struct ChapterSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    private let vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = 1
    @State private var practiceLaunch: PracticeLaunch?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    LevelTabBar(tabs: LevelTabBar.Tab.hskLevels(), selectedLevel: $selectedLevel)

                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(vocabularyService.chaptersForLevel(selectedLevel)) { chapter in
                                ChapterCard(
                                    chapter: chapter,
                                    isSelected: progressService.settings.selectedChapters.contains(chapter.id),
                                    progress: progressService.getChapterProgress(chapterId: chapter.id),
                                    isUnlocked: progressService.isChapterUnlocked(chapter),
                                    action: { toggleChapter(chapter) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }

                    SelectionBottomBar(
                        wordCount: selectedWordCount,
                        chapterCount: progressService.settings.selectedChapters.count,
                        isStartDisabled: progressService.settings.selectedChapters.isEmpty,
                        onStart: startChapterPractice
                    )
                }
            }
            .navigationTitle("Chapter Practice")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .fullScreenCover(item: $practiceLaunch) { launch in
                PracticeView(mode: launch.mode)
            }
            .onAppear {
                progressService.cleanupSelectedChapters()
                selectedLevel = initialLevel
            }
        }
    }

    private var selectedWordCount: Int {
        vocabularyService.vocabularyForChapters(progressService.settings.selectedChapters).count
    }

    private func toggleChapter(_ chapter: Chapter) {
        guard progressService.isChapterUnlocked(chapter) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if progressService.settings.selectedChapters.contains(chapter.id) {
                progressService.settings.selectedChapters.remove(chapter.id)
            } else {
                progressService.settings.selectedChapters.insert(chapter.id)
            }
        }
    }

    private func startChapterPractice() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        practiceLaunch = PracticeLaunch(mode: .chapters(progressService.settings.selectedChapters))
    }

    private var initialLevel: Int {
        progressService.settings.selectedChapters
            .compactMap { vocabularyService.chapter(withId: $0)?.hskLevel }
            .min() ?? 1
    }
}

struct SelectionBottomBar: View {
    let wordCount: Int
    let chapterCount: Int
    let isStartDisabled: Bool
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(wordCount) words selected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("PrimaryText"))

                    Text(chapterCount == 1 ? "1 chapter" : "\(chapterCount) chapters")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                }

                Spacer()

                PrimaryButton(
                    title: "Start",
                    icon: "play.fill",
                    action: onStart,
                    isDisabled: isStartDisabled
                )
                .frame(width: 120)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color("SecondaryBackground").opacity(0.5))
    }
}
