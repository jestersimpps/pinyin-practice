import SwiftUI
import Charts

struct ProgressStatsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDetailedStats = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        overviewSection
                        streakSection
                        accuracyChartSection
                        levelProgressSection
                        categoryBreakdownSection
                        achievementsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("VibrantOrange"))
                }
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Words Learned",
                    value: "\(progressService.progress.wordsSeenCount)",
                    subtitle: "of \(vocabularyService.getAllVocabulary().count) total",
                    icon: "book.fill",
                    color: Color("MidnightGreen")
                )
                
                StatCard(
                    title: "Accuracy",
                    value: progressService.progress.formattedAccuracy,
                    subtitle: "\(progressService.progress.correctAnswers) correct",
                    icon: "target",
                    color: Color("SuccessGreen")
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Practice",
                    value: "\(progressService.progress.totalAttempts)",
                    subtitle: "attempts made",
                    icon: "pencil.circle.fill",
                    color: Color("VibrantOrange")
                )
                
                StatCard(
                    title: "Review Needed",
                    value: "\(progressService.progress.incorrectWords.count)",
                    subtitle: "words to review",
                    icon: "exclamationmark.circle.fill",
                    color: Color.red
                )
            }
        }
    }
    
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Streak", icon: "flame.fill")
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(progressService.progress.currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(progressService.progress.currentStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText"))
                        
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(progressService.progress.currentStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText"))
                    }
                    
                    Text("Current Streak")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(progressService.progress.bestStreak)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("Best Streak")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SecondaryBackground"))
            )
        }
    }
    
    private var accuracyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Accuracy Trend", icon: "chart.line.uptrend.xyaxis")
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(mockAccuracyData(), id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Accuracy", dataPoint.accuracy)
                        )
                        .foregroundStyle(Color("VibrantOrange"))
                        
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Accuracy", dataPoint.accuracy)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("VibrantOrange").opacity(0.3), Color("VibrantOrange").opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("SecondaryBackground"))
                )
            } else {
                Text("Chart requires iOS 16.0 or later")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("SecondaryBackground"))
                    )
            }
        }
    }
    
    private var levelProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Level Progress", icon: "chart.bar.fill")
            
            VStack(spacing: 12) {
                ForEach(HSKLevel.allCases, id: \.self) { level in
                    LevelProgressRow(
                        level: level,
                        learned: progressService.getWordsLearnedForLevel(level),
                        total: vocabularyService.getVocabularyForLevel(level).count
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SecondaryBackground"))
            )
        }
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Category Mastery", icon: "square.grid.2x2.fill")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(VocabularyCategory.allCases, id: \.self) { category in
                    CategoryProgressCard(
                        category: category,
                        learned: progressService.getWordsLearnedForCategory(category),
                        total: vocabularyService.getVocabularyForCategory(category).count
                    )
                }
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Achievements", icon: "trophy.fill")
            
            VStack(spacing: 12) {
                AchievementRow(
                    title: "First Steps",
                    description: "Complete your first 10 words",
                    icon: "star.fill",
                    isUnlocked: progressService.progress.wordsSeenCount >= 10,
                    progress: min(1.0, Double(progressService.progress.wordsSeenCount) / 10.0)
                )
                
                AchievementRow(
                    title: "Consistency Key",
                    description: "Reach a 7-day streak",
                    icon: "flame.fill",
                    isUnlocked: progressService.progress.bestStreak >= 7,
                    progress: min(1.0, Double(progressService.progress.bestStreak) / 7.0)
                )
                
                AchievementRow(
                    title: "Accuracy Master",
                    description: "Maintain 90% accuracy",
                    icon: "target",
                    isUnlocked: progressService.progress.accuracy >= 90,
                    progress: progressService.progress.accuracy / 100.0
                )
                
                AchievementRow(
                    title: "HSK Champion",
                    description: "Complete all HSK1 words",
                    icon: "graduationcap.fill",
                    isUnlocked: progressService.getWordsLearnedForLevel(.hsk1) == vocabularyService.getVocabularyForLevel(.hsk1).count,
                    progress: Double(progressService.getWordsLearnedForLevel(.hsk1)) / Double(max(1, vocabularyService.getVocabularyForLevel(.hsk1).count))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SecondaryBackground"))
            )
        }
    }
    
    private func mockAccuracyData() -> [(date: Date, accuracy: Double)] {
        var data: [(date: Date, accuracy: Double)] = []
        let calendar = Calendar.current
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let accuracy = Double.random(in: 70...95)
                data.append((date: date, accuracy: accuracy))
            }
        }
        
        return data.reversed()
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryText"))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct LevelProgressRow: View {
    let level: HSKLevel
    let learned: Int
    let total: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(learned) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(level.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text("\(learned)/\(total)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
                
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(progress == 1.0 ? Color("SuccessGreen") : Color("VibrantOrange"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress == 1.0 ? Color("SuccessGreen") : Color("VibrantOrange"))
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

private struct CategoryProgressCard: View {
    let category: VocabularyCategory
    let learned: Int
    let total: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(learned) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress == 1.0 ? Color("SuccessGreen") : Color("VibrantOrange"),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryText"))
            }
            
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
                
                Text("\(learned)/\(total)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground"))
        )
    }
}

private struct AchievementRow: View {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color("VibrantOrange").opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? Color("VibrantOrange") : Color.gray.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isUnlocked ? Color("PrimaryText") : Color("SecondaryText"))
                
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isUnlocked ? Color("SuccessGreen") : Color("VibrantOrange"))
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("SuccessGreen"))
            }
        }
    }
}