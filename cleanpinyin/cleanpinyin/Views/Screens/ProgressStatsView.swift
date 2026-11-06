import SwiftUI
import Charts

struct ProgressStatsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 0
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        overviewSection
                        streakSection
                        accuracyChartSection
                        dailyWordsChartSection
                        dailyPracticeTimeChartSection
                        levelProgressSection
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
                    value: "\(progressService.wordsLearnedCount)",
                    subtitle: "of \(vocabularyService.hskWordCount) \(vocabularyService.syllabus.name) words",
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
                    value: formatPracticeTime(progressService.getTotalPracticeMinutes()),
                    subtitle: progressService.progress.totalAttempts.counted("attempt"),
                    icon: "clock.fill",
                    color: Color("VibrantOrange")
                )

                StatCard(
                    title: "Due Now",
                    value: "\(progressService.dueCount)",
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
                        Text("\(dayStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(dayStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText"))

                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(dayStreak > 0 ? Color("VibrantOrange") : Color("SecondaryText"))
                    }

                    Text(dayStreak == 1 ? "1-day streak" : "\(dayStreak)-day streak")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(progressService.progress.bestDayStreak)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("PrimaryText"))

                    Text(progressService.progress.bestDayStreak == 1 ? "Best: 1 day" : "Best: \(progressService.progress.bestDayStreak) days")
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
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            SectionHeader(title: "Accuracy Trend", icon: "chart.line.uptrend.xyaxis")

            let accuracyData = progressService.getAccuracyTrend(days: selectedTimeRange.days)

            if accuracyData.isEmpty {
                ChartEmptyState(
                    icon: "chart.line.uptrend.xyaxis",
                    message: "Complete some practice sessions to see your progress"
                )
            } else {
                chartCard {
                    Chart {
                        ForEach(accuracyData, id: \.date) { dataPoint in
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

                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Accuracy", dataPoint.accuracy)
                            )
                            .foregroundStyle(Color("VibrantOrange"))
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .dailyAxis(domain: chartDateDomain)
                }
            }
        }
    }

    private var dailyWordsChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Words Practised per Day", icon: "calendar")

            let wordsData = progressService.getDailyWordsLearned(days: selectedTimeRange.days)

            if wordsData.isEmpty {
                ChartEmptyState(
                    icon: "book.closed",
                    message: "Complete some practice sessions to see your daily progress"
                )
            } else {
                chartCard {
                    Chart {
                        ForEach(wordsData, id: \.date) { dataPoint in
                            BarMark(
                                x: .value("Date", dataPoint.date, unit: .day),
                                y: .value("Words", dataPoint.words)
                            )
                            .foregroundStyle(Color("MidnightGreen"))
                            .cornerRadius(4)
                        }
                    }
                    .dailyAxis(domain: chartDateDomain)
                }
            }
        }
    }

    private var dailyPracticeTimeChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Minutes per Day", icon: "clock")

            let timeData = progressService.getDailyPracticeTime(days: selectedTimeRange.days)

            if timeData.isEmpty {
                ChartEmptyState(
                    icon: "clock",
                    message: "Complete some practice sessions to see your daily time"
                )
            } else {
                chartCard {
                    Chart {
                        ForEach(timeData, id: \.date) { dataPoint in
                            BarMark(
                                x: .value("Date", dataPoint.date, unit: .day),
                                y: .value("Minutes", dataPoint.minutes)
                            )
                            .foregroundStyle(Color("VibrantOrange"))
                            .cornerRadius(4)
                        }
                    }
                    .dailyAxis(domain: chartDateDomain)
                }
            }
        }
    }

    private var levelProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Level Progress", icon: "chart.bar.fill")

            VStack(spacing: 12) {
                ForEach(1...6, id: \.self) { level in
                    LevelProgressRow(
                        level: level,
                        learned: progressService.getWordsLearnedForLevel(level),
                        total: vocabularyService.vocabularyForLevel(level).count
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

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Achievements", icon: "trophy.fill")

            VStack(spacing: 12) {
                AchievementRow(
                    title: "First Steps",
                    description: "Learn your first 10 words",
                    icon: "star.fill",
                    isUnlocked: progressService.wordsLearnedCount >= 10,
                    progress: min(1.0, Double(progressService.wordsLearnedCount) / 10.0)
                )

                AchievementRow(
                    title: "Consistency Key",
                    description: "Reach a 7-day streak",
                    icon: "flame.fill",
                    isUnlocked: progressService.progress.bestDayStreak >= 7,
                    progress: min(1.0, Double(progressService.progress.bestDayStreak) / 7.0)
                )

                AchievementRow(
                    title: "Accuracy Master",
                    description: "Keep 90% accuracy over 50+ answers",
                    icon: "target",
                    isUnlocked: progressService.progress.totalAttempts >= 50 && progressService.progress.accuracy >= 90,
                    progress: progressService.progress.accuracy / 100.0
                )

                AchievementRow(
                    title: "HSK Champion",
                    description: "Learn every HSK 1 word",
                    icon: "graduationcap.fill",
                    isUnlocked: progressService.getWordsLearnedForLevel(1) == vocabularyService.vocabularyForLevel(1).count,
                    progress: Double(progressService.getWordsLearnedForLevel(1)) / Double(max(1, vocabularyService.vocabularyForLevel(1).count))
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SecondaryBackground"))
            )
        }
    }

    private var chartDateDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let firstSession = progressService.sessions.map(\.date).min() ?? today
        let start: Date
        if selectedTimeRange.days > 0 {
            start = calendar.date(byAdding: .day, value: 1 - selectedTimeRange.days, to: today) ?? today
        } else {
            start = min(calendar.startOfDay(for: firstSession), calendar.date(byAdding: .day, value: -6, to: today) ?? today)
        }
        return start...end
    }

    private var dayStreak: Int {
        progressService.currentDayStreak
    }

    private func chartCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(height: 200)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SecondaryBackground"))
            )
    }

    private func formatPracticeTime(_ totalMinutes: Int) -> String {
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}

private struct ChartEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(Color("SecondaryText").opacity(0.5))

            Text("No practice data yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("SecondaryText"))

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("SecondaryText").opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground"))
        )
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
    let level: Int
    let learned: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(learned) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("HSK \(level)")
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

private extension View {
    func dailyAxis(domain: ClosedRange<Date>) -> some View {
        chartXScale(domain: domain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
    }
}
