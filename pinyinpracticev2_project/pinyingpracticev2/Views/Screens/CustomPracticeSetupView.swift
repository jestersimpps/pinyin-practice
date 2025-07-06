import SwiftUI

struct CustomPracticeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.diContainer) var diContainer
    @ObservedObject private var progressService: UserProgressService
    @ObservedObject private var vocabularyService: VocabularyService
    
    init() {
        let container = DIContainer.shared
        _progressService = ObservedObject(wrappedValue: container.makeProgressService())
        _vocabularyService = ObservedObject(wrappedValue: container.vocabularyService)
    }
    @State private var selectedLevel: Int = 7  // Start with Custom tab
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
                
                ToolbarItem(placement: .principal) {
                    if selectedWordCount > 0 {
                        HStack(spacing: 6) {
                            Text("\(selectedWordCount)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("words")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                    }
                }
            }
            .fullScreenCover(isPresented: $showingPractice) {
                PracticeView()
            }
            .onDisappear {
                // Clear selected chapters when leaving custom practice to avoid interference with chapter practice
                progressService.updateSettings { settings in
                    settings.selectedChapters = []
                }
            }
        }
    }
    
    private var levelTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Custom tab first
                Button(action: { 
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedLevel = 7 
                }) {
                    Text("Custom")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedLevel == 7 ? .white : Color("PrimaryText"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedLevel == 7 ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color("SecondaryBackground"))
                        )
                }
                
                // HSK levels
                ForEach(1...6, id: \.self) { level in
                    Button(action: { 
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedLevel = level 
                    }) {
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
        if selectedLevel == 7 {
            return vocabularyService.chapters.filter { $0.hskLevel == 7 }
        }
        return vocabularyService.getChaptersForLevel(selectedLevel)
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
        progressService.updateSettings { settings in
            settings.selectedChapters = selectedChapters
            settings.isReviewMode = false
            settings.lastPracticeMode = .custom
        }
        
        // Calculate selected HSK levels from all selected chapters
        var selectedLevels: Set<Int> = []
        for chapterId in selectedChapters {
            if chapterId.hasPrefix("custom_") {
                // Custom chapters use level 7
                selectedLevels.insert(7)
            } else if let chapterNum = Int(chapterId.replacingOccurrences(of: "chapter", with: "")) {
                let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNum)
                selectedLevels.insert(chapterInfo.hskLevel)
            }
        }
        progressService.updateSettings { settings in
            settings.selectedHSKLevels = selectedLevels
        }
        
        
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

