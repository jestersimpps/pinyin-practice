import SwiftUI

struct SetupView: View {
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var showingPractice = false
    @State private var showingSettings = false
    @State private var showingCustomPractice = false
    @State private var showingProgress = false
    @State private var showingChapterSelection = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        statsSection
                        actionCardsSection
                        secondaryActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingPractice) {
                PracticeView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingCustomPractice) {
                CustomPracticeSetupView()
            }
            .sheet(isPresented: $showingProgress) {
                ProgressStatsView()
            }
            .sheet(isPresented: $showingChapterSelection) {
                ChapterSelectionView()
            }
        }
        .onAppear {
            animateStats = true
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(greetingText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryText"))
            
            Text("Ready to practice your pinyin?")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "Words Learned",
                value: "\(progressService.getTotalWordsLearned())",
                icon: "checkmark.seal.fill",
                color: Color("SuccessGreen"),
                action: { showingProgress = true }
            )
            .scaleEffect(animateStats ? 1 : 0.8)
            .opacity(animateStats ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateStats)
            
            StatBox(
                title: "Current Streak",
                value: formatStreak(progressService.progress.currentStreak),
                icon: "flame.fill",
                color: progressService.progress.currentStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText"),
                action: { showingProgress = true }
            )
            .scaleEffect(animateStats ? 1 : 0.8)
            .opacity(animateStats ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: animateStats)
        }
    }
    
    private var actionCardsSection: some View {
        VStack(spacing: 16) {
            ActionCard(
                title: "Quick Practice",
                subtitle: quickPracticeSubtitle,
                icon: "play.circle.fill",
                color: Color("MidnightGreen"),
                action: startQuickPractice,
                badge: quickPracticeBadge,
                isDisabled: availableWordCount == 0 && incorrectWordCount == 0
            )
            
            ActionCard(
                title: "Chapter Practice",
                subtitle: "Study by structured lessons",
                icon: "book.closed.fill",
                color: Color.purple,
                action: { showingChapterSelection = true }
            )
            
            ActionCard(
                title: "Custom Practice",
                subtitle: "Choose levels and categories",
                icon: "slider.horizontal.3",
                color: Color("VibrantOrange"),
                action: { showingCustomPractice = true }
            )
            
            ActionCard(
                title: "Review Mistakes",
                subtitle: "Practice words you got wrong",
                icon: "arrow.triangle.2.circlepath",
                color: Color.red,
                action: startReviewMode,
                badge: incorrectWordCount > 0 ? "\(incorrectWordCount) words" : nil,
                isDisabled: incorrectWordCount == 0
            )
        }
    }
    
    private var secondaryActionsSection: some View {
        HStack(spacing: 16) {
            SecondaryActionButton(
                title: "Progress",
                icon: "chart.line.uptrend.xyaxis",
                action: { showingProgress = true }
            )
            
            SecondaryActionButton(
                title: "Settings",
                icon: "gearshape.fill",
                action: { showingSettings = true }
            )
        }
    }
    
    private var availableWordCount: Int {
        vocabularyService.getVocabularyForLevels(
            progressService.settings.selectedHSKLevels
        ).count
    }
    
    private var incorrectWordCount: Int {
        progressService.getIncorrectWords().count
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default: return "Good evening!"
        }
    }
    
    private var quickPracticeSubtitle: String {
        let lastMode = progressService.settings.lastPracticeMode
        
        switch lastMode {
        case .review:
            if progressService.hasIncorrectWords {
                return "Continue reviewing mistakes"
            } else {
                return "Continue with custom practice"
            }
            
        case .chapters:
            if !progressService.settings.selectedChapters.isEmpty {
                let count = progressService.settings.selectedChapters.count
                return "Continue with \(count) chapter\(count == 1 ? "" : "s")"
            } else {
                return "Continue with custom practice"
            }
            
        case .quick, .custom:
            return "Continue where you left off"
        }
    }
    
    private var quickPracticeBadge: String? {
        if availableWordCount > 0 {
            return "\(availableWordCount) words"
        }
        return nil
    }
    
    private func startQuickPractice() {
        // Use the last practice mode
        let lastMode = progressService.settings.lastPracticeMode
        
        switch lastMode {
        case .review:
            // Check if there are incorrect words to review
            if progressService.hasIncorrectWords {
                progressService.settings.selectedChapters = []
                progressService.settings.isReviewMode = true
            } else {
                // Fall back to custom practice if no incorrect words
                progressService.settings.selectedChapters = []
                progressService.settings.isReviewMode = false
                progressService.settings.lastPracticeMode = .custom
            }
            
        case .chapters:
            // Keep the selected chapters if any, otherwise fall back to custom
            if progressService.settings.selectedChapters.isEmpty {
                progressService.settings.lastPracticeMode = .custom
            }
            progressService.settings.isReviewMode = false
            
        case .quick, .custom:
            // Continue with custom practice mode
            progressService.settings.selectedChapters = []
            progressService.settings.isReviewMode = false
        }
        
        showingPractice = true
    }
    
    private func startReviewMode() {
        // Set review mode flag and clear other selections
        progressService.settings.selectedChapters = []
        progressService.settings.isReviewMode = true
        showingPractice = true
    }
    
    private func formatStreak(_ streak: Int) -> String {
        switch streak {
        case 0:
            return "0 days"
        case 1:
            return "1 day"
        default:
            return "\(streak) days"
        }
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryText"))
            
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("SecondaryText"))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            // Handle tap with animation
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                // Call the action after animation
                action?()
            }
        }
    }
}

private struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color("PrimaryText"))
                
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SecondaryBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}