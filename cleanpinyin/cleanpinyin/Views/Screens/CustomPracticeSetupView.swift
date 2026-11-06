import SwiftUI

struct CustomPracticeSetupView: View {
    @Environment(\.dismiss) var dismiss
    private let vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = VocabularyService.shared.hasCustomChapters ? Chapter.customLevel : 1
    @State private var practiceLaunch: PracticeLaunch?
    @State private var selectedChapters: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    LevelTabBar(
                        tabs: vocabularyService.hasCustomChapters ? LevelTabBar.Tab.withCustom() : LevelTabBar.Tab.hskLevels(),
                        selectedLevel: $selectedLevel
                    )

                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(vocabularyService.chaptersForLevel(selectedLevel)) { chapter in
                                ChapterCard(
                                    chapter: chapter,
                                    isSelected: selectedChapters.contains(chapter.id),
                                    action: { toggleChapter(chapter) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }

                    SelectionBottomBar(
                        wordCount: selectedWordCount,
                        chapterCount: selectedChapters.count,
                        isStartDisabled: selectedChapters.isEmpty,
                        onStart: startCustomPractice
                    )
                }
            }
            .navigationTitle("Custom Practice")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .fullScreenCover(item: $practiceLaunch) { launch in
                PracticeView(mode: launch.mode)
            }
        }
    }

    private var selectedWordCount: Int {
        vocabularyService.vocabularyForChapters(selectedChapters).count
    }

    private func toggleChapter(_ chapter: Chapter) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedChapters.contains(chapter.id) {
                selectedChapters.remove(chapter.id)
            } else {
                selectedChapters.insert(chapter.id)
            }
        }
    }

    private func startCustomPractice() {
        practiceLaunch = PracticeLaunch(mode: .custom(selectedChapters))
    }
}
