import SwiftUI

struct SetupViewRedesigned: View {
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var showingPractice = false
    @State private var showingSettings = false
    @State private var showingCustomPractice = false
    @State private var animateStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
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
                PracticeViewRedesigned()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsViewRefactored()
            }
            .sheet(isPresented: $showingCustomPractice) {
                CustomPracticeSetupView()
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
                .foregroundColor(.primaryText)
            
            Text("Ready to practice your pinyin?")
                .font(Typography.bodyFont)
                .foregroundColor(.secondaryText)
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
                color: .successGreen
            )
            .scaleEffect(animateStats ? 1 : 0.8)
            .opacity(animateStats ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateStats)
            
            StatBox(
                title: "Current Streak",
                value: "\(progressService.currentStreak)",
                icon: "flame.fill",
                color: progressService.currentStreak > 0 ? .vibrantOrange : .secondaryText
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
                color: .midnightGreen,
                action: startQuickPractice,
                badge: availableWordCount > 0 ? "\(availableWordCount) words" : nil,
                isDisabled: availableWordCount == 0
            )
            
            ActionCard(
                title: "Custom Practice",
                subtitle: "Choose levels and categories",
                icon: "slider.horizontal.3",
                color: .vibrantOrange,
                action: { showingCustomPractice = true }
            )
            
            ActionCard(
                title: "Review Mistakes",
                subtitle: "Practice words you got wrong",
                icon: "arrow.triangle.2.circlepath",
                color: .errorRed,
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
                action: { }
            )
            
            SecondaryActionButton(
                title: "Settings",
                icon: "gearshape.fill",
                action: { showingSettings = true }
            )
        }
    }
    
    private var availableWordCount: Int {
        vocabularyService.getFilteredVocabulary(
            levels: progressService.settings.selectedHSKLevels,
            categories: progressService.settings.selectedCategories
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
        progressService.settings.practiceMode = .allWords
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
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(Typography.captionFont)
                .foregroundColor(.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBackground.opacity(0.5))
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
                    .foregroundColor(.primaryText)
                
                Text(title)
                    .font(Typography.captionFont)
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondaryBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.lightSilver.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}