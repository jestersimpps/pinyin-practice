import SwiftUI

struct SetupView: View {
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var practiceLaunch: PracticeLaunch?
    @State private var showingSettings = false
    @State private var showingCustomPractice = false
    @State private var showingProgress = false
    @State private var showingChapterSelection = false
    @State private var showingImprint = false
    @State private var animateStats = false

    var body: some View {
        NavigationStack {
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
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $practiceLaunch) { launch in
                PracticeView(mode: launch.mode)
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
            .fullScreenCover(isPresented: $showingImprint) {
                ImprintView()
            }
        }
        .onAppear {
            animateStats = true
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greetingText)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryText"))

            HStack {
                Text("Ready to practise your pinyin?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
                Spacer()
                wordListMenu
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    private var wordListMenu: some View {
        Menu {
            Picker("Word list", selection: Binding(
                get: { progressService.settings.syllabus },
                set: { progressService.selectSyllabus($0) }
            )) {
                ForEach(HSKSyllabus.allCases) { syllabus in
                    Text("\(syllabus.name) · \(syllabus.summary)").tag(syllabus)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(progressService.settings.syllabus.name)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color("MidnightGreen"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color("MidnightGreen").opacity(0.12)))
        }
        .accessibilityIdentifier("home.wordList")
        .accessibilityLabel("Word list: \(progressService.settings.syllabus.name)")
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            StatBox(
                identifier: "home.wordsLearned",
                title: "Words Learned",
                value: "\(progressService.wordsLearnedCount)",
                icon: "checkmark.seal.fill",
                color: Color("SuccessGreen"),
                action: { showingProgress = true }
            )
            .scaleEffect(animateStats ? 1 : 0.8)
            .opacity(animateStats ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateStats)

            StatBox(
                identifier: "home.dayStreak",
                title: "Day Streak",
                value: formatStreak(progressService.currentDayStreak),
                icon: "flame.fill",
                color: progressService.currentDayStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText"),
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
                action: { practiceLaunch = PracticeLaunch(mode: quickPracticeMode) },
                badge: wordCount(for: quickPracticeMode).counted("word")
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
                subtitle: "Mix any chapters and sets",
                icon: "slider.horizontal.3",
                color: Color("VibrantOrange"),
                action: { showingCustomPractice = true }
            )

            ActionCard(
                title: "Smart Review",
                subtitle: reviewSubtitle,
                icon: "arrow.triangle.2.circlepath",
                color: Color.red,
                action: { practiceLaunch = PracticeLaunch(mode: .review) },
                badge: dueCount > 0 ? "\(dueCount) due" : nil,
                isDisabled: dueCount == 0
            )

            ActionCard(
                title: "Imprint Mode",
                subtitle: "Listen and absorb, hands-free",
                icon: "speaker.wave.3",
                color: Color.blue,
                action: { showingImprint = true }
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

    private var dueCount: Int {
        progressService.dueCount
    }

    private var reviewSubtitle: String {
        if dueCount > 0 { return "Words due now, timed so you don't forget" }
        guard let next = progressService.progress.nextReviewDate() else {
            return "Words you practise come back here"
        }
        return "All caught up · next \(next.formatted(.relative(presentation: .named)))"
    }

    // Quick Practice resumes the last chapter or review session, otherwise practises the chosen levels
    private var quickPracticeMode: LearningMode {
        let settings = progressService.settings
        switch settings.lastPracticeMode {
        case .review where dueCount > 0:
            return .review
        case .chapters where !settings.selectedChapters.isEmpty:
            return .chapters(settings.selectedChapters)
        default:
            return .levels(settings.selectedHSKLevels)
        }
    }

    private var quickPracticeSubtitle: String {
        switch quickPracticeMode {
        case .review:
            return "Continue reviewing mistakes"
        case .chapters(let ids):
            return "Continue with \(ids.count) chapter\(ids.count == 1 ? "" : "s")"
        case .levels(let levels):
            return "Continue \(levelNames(levels)) where you left off"
        case .custom:
            return "Continue where you left off"
        }
    }

    private func levelNames(_ levels: Set<Int>) -> String {
        levels.sorted().map { "HSK \($0)" }.joined(separator: ", ")
    }

    private func wordCount(for mode: LearningMode) -> Int {
        switch mode {
        case .levels(let levels): return vocabularyService.vocabularyForLevels(levels).count
        case .chapters(let ids), .custom(let ids): return vocabularyService.vocabularyForChapters(ids).count
        case .review: return dueCount
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<18: return "Good afternoon!"
        default: return "Good evening!"
        }
    }

    private func formatStreak(_ streak: Int) -> String {
        streak == 1 ? "1 day" : "\(streak) days"
    }
}

private struct StatBox: View {
    let identifier: String
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
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identifier)
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