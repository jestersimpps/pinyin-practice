import SwiftUI

struct ChapterSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedLevel: Int = 1
    @State private var showingPractice = false
    
    private var settings: Binding<PracticeSettings> {
        $progressService.settings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    levelTabBar
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(chaptersForSelectedLevel) { chapter in
                                ChapterCard(
                                    chapter: chapter,
                                    isSelected: settings.wrappedValue.selectedChapters.contains(chapter.id),
                                    progress: progressService.getChapterProgress(chapterId: chapter.id),
                                    isUnlocked: progressService.isChapterUnlocked(
                                        level: chapter.hskLevel,
                                        chapter: chapter.chapterNumber
                                    ),
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
            .navigationTitle("Chapter Practice")
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
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedWordCount) words selected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("\(settings.wrappedValue.selectedChapters.count) chapters")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                PrimaryButton(
                    title: "Start",
                    icon: "play.fill",
                    action: startChapterPractice,
                    isDisabled: settings.wrappedValue.selectedChapters.isEmpty
                )
                .frame(width: 120)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color("SecondaryBackground").opacity(0.5))
    }
    
    private var chaptersForSelectedLevel: [Chapter] {
        vocabularyService.getChaptersForLevel(selectedLevel)
    }
    
    private var selectedWordCount: Int {
        vocabularyService.getVocabularyForChapters(settings.wrappedValue.selectedChapters).count
    }
    
    private func toggleChapter(_ chapter: Chapter) {
        guard progressService.isChapterUnlocked(level: chapter.hskLevel, chapter: chapter.chapterNumber) else {
            return
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if settings.wrappedValue.selectedChapters.contains(chapter.id) {
                settings.wrappedValue.selectedChapters.remove(chapter.id)
            } else {
                settings.wrappedValue.selectedChapters.insert(chapter.id)
            }
        }
    }
    
    private func startChapterPractice() {
        settings.wrappedValue.practiceMode = .chapter
        showingPractice = true
    }
}

private struct ChapterCard: View {
    let chapter: Chapter
    let isSelected: Bool
    let progress: ChapterProgress?
    let isUnlocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapter.displayTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textColor)
                        
                        Text("\(chapter.wordCount) words")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(Color("SecondaryText"))
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(Color("SecondaryText"))
                    }
                }
                
                if let progress = progress, progress.wordsCompleted.count > 0 {
                    VStack(spacing: 4) {
                        ProgressView(value: progress.completionPercentage, total: 100)
                            .tint(progressColor)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        HStack {
                            Text("\(Int(progress.completionPercentage))% complete")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(secondaryTextColor)
                            
                            Spacer()
                            
                            if progress.isCompleted {
                                Label("Completed", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color("SuccessGreen"))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
    }
    
    private var textColor: Color {
        if !isUnlocked {
            return Color("SecondaryText")
        } else if isSelected {
            return .white
        } else {
            return Color("PrimaryText")
        }
    }
    
    private var secondaryTextColor: Color {
        if !isUnlocked {
            return Color("SecondaryText").opacity(0.6)
        } else if isSelected {
            return .white.opacity(0.8)
        } else {
            return Color("SecondaryText")
        }
    }
    
    private var backgroundColor: Color {
        if !isUnlocked {
            return Color("SecondaryBackground").opacity(0.3)
        } else if isSelected {
            return Color(red: 0.1, green: 0.3, blue: 0.4)
        } else {
            return Color("SecondaryBackground").opacity(0.5)
        }
    }
    
    private var borderColor: Color {
        if !isUnlocked {
            return Color.gray.opacity(0.2)
        } else if isSelected {
            return Color.clear
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var progressColor: Color {
        if progress?.isCompleted == true {
            return Color("SuccessGreen")
        } else if progress?.completionPercentage ?? 0 >= 80 {
            return Color("VibrantOrange")
        } else {
            return Color(red: 0.1, green: 0.3, blue: 0.4)
        }
    }
}