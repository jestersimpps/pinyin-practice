import SwiftUI

struct CustomPracticeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = 1
    @State private var showingPractice = false
    @State private var selectedChapters: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    levelTabBar
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Word count card
                            if selectedWordCount > 0 {
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
                            
                            // Chapter cards
                            ForEach(chaptersForSelectedLevel) { chapter in
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
                    
                    bottomBar
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
    
    private var levelTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(1...6, id: \.self) { level in
                    Button(action: { selectedLevel = level }) {
                        Text("HSK \(level)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedLevel == level ? .white : Color("PrimaryText"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedLevel == level ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color("SecondaryBackground"))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color("SecondaryBackground").opacity(0.5))
    }
    
    private var chaptersForSelectedLevel: [Chapter] {
        vocabularyService.getChaptersForLevel(selectedLevel)
    }
    
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedWordCount) words selected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("\(selectedChapters.count) chapters")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                PrimaryButton(
                    title: "Start",
                    icon: "play.fill",
                    action: startCustomPractice,
                    isDisabled: selectedChapters.isEmpty
                )
                .frame(width: 120)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color("SecondaryBackground").opacity(0.5))
    }
    
    private var selectedWordCount: Int {
        vocabularyService.getVocabularyForChapters(selectedChapters).count
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
        // Update settings with selected chapters for this practice session
        progressService.settings.selectedChapters = selectedChapters
        progressService.settings.isReviewMode = false
        progressService.settings.lastPracticeMode = .custom
        
        // Calculate selected HSK levels from all selected chapters
        var selectedLevels: Set<Int> = []
        for chapterId in selectedChapters {
            // Extract level from chapter ID (format: "chapter_X")
            if let chapterNum = Int(chapterId.replacingOccurrences(of: "chapter_", with: "")) {
                let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNum)
                selectedLevels.insert(chapterInfo.hskLevel)
            }
        }
        progressService.settings.selectedHSKLevels = selectedLevels
        
        
        showingPractice = true
    }
}

private struct ChapterCard: View {
    let chapter: Chapter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    // Chapter icon
                    Image(systemName: chapter.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(iconBackgroundColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapter.displayTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                        
                        Text(chapter.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : Color("SecondaryText"))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(chapter.wordCount) words")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : Color("SecondaryText"))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : Color("SecondaryText"))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color("SecondaryBackground").opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconColor: Color {
        if isSelected {
            return .white
        } else {
            return Color(red: 0.1, green: 0.3, blue: 0.4)
        }
    }
    
    private var iconBackgroundColor: Color {
        if isSelected {
            return Color.white.opacity(0.2)
        } else {
            return Color(red: 0.1, green: 0.3, blue: 0.4).opacity(0.1)
        }
    }
}

