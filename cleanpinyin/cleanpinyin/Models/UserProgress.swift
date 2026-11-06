import Foundation

struct UserProgress: Codable, Equatable {
    var correctAnswers: Int = 0
    var totalAttempts: Int = 0
    var combo: Int = 0
    var bestCombo: Int = 0
    var dayStreak: Int = 0
    var bestDayStreak: Int = 0
    var lastPracticeDate: Date?
    var incorrectWords: Set<String> = []
    var seenWords: Set<String> = []
    var learnedWords: Set<String> = []
    var chapterProgress: [String: ChapterProgress] = [:]
    var reviewCards: [String: ReviewCard] = [:]

    private enum CodingKeys: String, CodingKey {
        case correctAnswers, totalAttempts, combo, bestCombo, dayStreak, bestDayStreak
        case lastPracticeDate, incorrectWords, seenWords, learnedWords, chapterProgress, reviewCards
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case bestStreak
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)

        correctAnswers = try container.decodeIfPresent(Int.self, forKey: .correctAnswers) ?? 0
        totalAttempts = try container.decodeIfPresent(Int.self, forKey: .totalAttempts) ?? 0
        combo = try container.decodeIfPresent(Int.self, forKey: .combo) ?? 0
        bestCombo = try container.decodeIfPresent(Int.self, forKey: .bestCombo)
            ?? legacy.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        dayStreak = try container.decodeIfPresent(Int.self, forKey: .dayStreak) ?? 0
        bestDayStreak = try container.decodeIfPresent(Int.self, forKey: .bestDayStreak) ?? dayStreak
        lastPracticeDate = try container.decodeIfPresent(Date.self, forKey: .lastPracticeDate)
        incorrectWords = try container.decodeIfPresent(Set<String>.self, forKey: .incorrectWords) ?? []
        seenWords = try container.decodeIfPresent(Set<String>.self, forKey: .seenWords) ?? []
        learnedWords = try container.decodeIfPresent(Set<String>.self, forKey: .learnedWords)
            ?? seenWords.subtracting(incorrectWords)
        chapterProgress = try container.decodeIfPresent([String: ChapterProgress].self, forKey: .chapterProgress) ?? [:]
        reviewCards = try container.decodeIfPresent([String: ReviewCard].self, forKey: .reviewCards) ?? [:]
    }

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAttempts) * 100
    }

    var formattedAccuracy: String {
        String(format: "%.0f%%", accuracy)
    }

    // rating schedules the word's next review; nil records the answer without rescheduling
    mutating func recordAnswer(
        wordId: String,
        isCorrect: Bool,
        rating: ReviewRating? = nil,
        at date: Date = Date(),
        calendar: Calendar = .current,
        scheduler: FSRSScheduler = FSRSScheduler()
    ) {
        if let rating {
            reviewCards[wordId] = scheduler.review(reviewCards[wordId], rating: rating, at: date)
        }
        totalAttempts += 1
        seenWords.insert(wordId)
        recordPracticeDay(date, calendar: calendar)

        if isCorrect {
            correctAnswers += 1
            combo += 1
            bestCombo = max(bestCombo, combo)
            incorrectWords.remove(wordId)
            learnedWords.insert(wordId)
        } else {
            combo = 0
            incorrectWords.insert(wordId)
        }
    }

    // Words to review now, most overdue first; misses from before scheduling existed come first
    func dueWordIds(at date: Date = Date()) -> [String] {
        let unscheduledMisses = incorrectWords.filter { reviewCards[$0] == nil }.sorted()
        let due = reviewCards
            .filter { $0.value.due <= date }
            .sorted { $0.value.due < $1.value.due }
            .map(\.key)
        return unscheduledMisses + due
    }

    func nextReviewDate(after date: Date = Date()) -> Date? {
        reviewCards.values.map(\.due).filter { $0 > date }.min()
    }

    // The streak survives until a full calendar day passes without practice
    func currentDayStreak(asOf date: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let lastPracticeDate else { return 0 }
        let daysSince = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastPracticeDate),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return daysSince <= 1 ? dayStreak : 0
    }

    private mutating func recordPracticeDay(_ date: Date, calendar: Calendar) {
        defer { lastPracticeDate = date }

        guard let lastPracticeDate else {
            dayStreak = 1
            bestDayStreak = max(bestDayStreak, dayStreak)
            return
        }

        let daysSince = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastPracticeDate),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        switch daysSince {
        case 0:
            dayStreak = max(dayStreak, 1)
        case 1:
            dayStreak += 1
        default:
            dayStreak = 1
        }
        bestDayStreak = max(bestDayStreak, dayStreak)
    }

    mutating func reset() {
        self = UserProgress()
    }

    func getChapterProgress(chapterId: String) -> ChapterProgress? {
        chapterProgress[chapterId]
    }

    mutating func recordChapterAttempt(chapterId: String, totalWords: Int, isCorrect: Bool, practiceTime: TimeInterval) {
        ensureChapterProgress(chapterId: chapterId, totalWords: totalWords)
        chapterProgress[chapterId]?.recordAttempt(isCorrect: isCorrect, practiceTime: practiceTime)
    }

    mutating func updateChapterProgress(chapterId: String, wordId: String, totalWords: Int) -> Bool {
        ensureChapterProgress(chapterId: chapterId, totalWords: totalWords)

        let wasCompleted = chapterProgress[chapterId]?.isCompleted ?? false
        chapterProgress[chapterId]?.markWordCompleted(wordId)
        let isNowCompleted = chapterProgress[chapterId]?.isCompleted ?? false

        return !wasCompleted && isNowCompleted
    }

    private mutating func ensureChapterProgress(chapterId: String, totalWords: Int) {
        guard chapterProgress[chapterId] == nil else { return }
        chapterProgress[chapterId] = ChapterProgress(
            chapterId: chapterId,
            wordsCompleted: [],
            totalWords: totalWords,
            isCompleted: false,
            completionDate: nil
        )
    }

    // levelChapters must be the chapter's level in display order
    func isChapterUnlocked(_ chapter: Chapter, levelChapters: [Chapter]) -> Bool {
        guard chapter.kind != .custom,
              let index = levelChapters.firstIndex(where: { $0.id == chapter.id }),
              index > 0 else { return true }

        let previous = levelChapters[index - 1]
        guard let previousProgress = chapterProgress[previous.id] else { return false }
        return previousProgress.completionPercentage >= AppConstants.Chapters.unlockRequirement * 100
    }
}
