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
                color: Color("SuccessGreen")
            )
            .scaleEffect(animateStats ? 1 : 0.8)
            .opacity(animateStats ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateStats)
            
            StatBox(
                title: "Current Streak",
                value: "\(progressService.progress.currentStreak)",
                icon: "flame.fill",
                color: progressService.progress.currentStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText")
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
                subtitle: "Continue where you left off",
                icon: "play.circle.fill",
                color: Color("MidnightGreen"),
                action: startQuickPractice,
                badge: availableWordCount > 0 ? "\(availableWordCount) words" : nil,
                isDisabled: availableWordCount == 0
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
    
    private func startQuickPractice() {
        // Don't override the saved practice mode
        showingPractice = true
    }
    
    private func startReviewMode() {
        progressService.settings.practiceMode = .reviewMistakes
        showingPractice = true
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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
    }
}

private struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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