import SwiftUI

struct CustomPracticeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = Chapter.customLevel
    @State private var showingPractice = false
    @State private var selectedChapters: Set<String> = []

    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    LevelTabBar(tabs: LevelTabBar.Tab.withCustom(), selectedLevel: $selectedLevel)

                    ScrollView {
                        VStack(spacing: 20) {
                            if selectedWordCount > 0 {
                                wordCountCard
                            }

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
            .fullScreenCover(isPresented: $showingPractice) {
                PracticeView()
            }
            .onDisappear {
                // Clear selected chapters when leaving custom practice to avoid interference with chapter practice
                progressService.settings.selectedChapters = []
            }
        }
    }

    private var wordCountCard: some View {
        VStack(spacing: 8) {
            Text("\(selectedWordCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.orange)

            Text("words selected")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
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
        progressService.settings.selectedChapters = selectedChapters
        progressService.settings.isReviewMode = false
        progressService.settings.lastPracticeMode = .custom

        let selectedLevels = Set(selectedChapters.compactMap { chapterId -> Int? in
            let identifier = ChapterIdentifier(chapterId)
            return identifier.isCustom ? Chapter.customLevel : identifier.hskLevel
        })
        progressService.settings.selectedHSKLevels = selectedLevels

        showingPractice = true
    }
}
