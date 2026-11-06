import Foundation
import Testing
@testable import cleanpinyin

@Suite("Smart review scheduling (SPEC §12)")
struct SchedulerTests {
    private let scheduler = FSRSScheduler()
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let day = 86_400.0

    private func days(_ card: ReviewCard, from date: Date) -> Double {
        (card.due.timeIntervalSince(date) / day).rounded()
    }

    @Test("REV-1 a first answer sets FSRS-5 initial stability and difficulty")
    func firstReview() {
        let good = scheduler.review(nil, rating: .good, at: start)
        #expect(abs(good.stability - 3.173) < 0.0001)
        #expect(abs(good.difficulty - (7.1949 - exp(0.5345 * 2) + 1)) < 0.0001)
        #expect(days(good, from: start) == 3)
        #expect(good.reps == 1 && good.lapses == 0)
    }

    @Test("REV-1 easier first answers wait longer")
    func firstIntervalsOrdered() {
        let intervals = [ReviewRating.hard, .good, .easy].map { days(scheduler.review(nil, rating: $0, at: start), from: start) }
        #expect(intervals == intervals.sorted())
        #expect(Set(intervals).count == 3)
    }

    @Test("REV-2 a forgotten word is due again straight away")
    func againIsDueNow() {
        let card = scheduler.review(nil, rating: .again, at: start)
        #expect(card.due == start)
        #expect(card.lapses == 1)
    }

    @Test("REV-1 at 90% retention the interval equals the stability")
    func intervalMatchesStability() {
        #expect(scheduler.intervalDays(for: 10) == 10)
        #expect(scheduler.intervalDays(for: 0.2) == 1)
        #expect(scheduler.intervalDays(for: 5000) == 365)
        #expect(abs(scheduler.retrievability(elapsedDays: 10, stability: 10) - 0.9) < 0.0001)
    }

    @Test("REV-1 remembering on time grows stability; forgetting shrinks it")
    func stabilityUpdates() {
        let first = scheduler.review(nil, rating: .good, at: start)
        let reviewDate = first.due

        let remembered = scheduler.review(first, rating: .good, at: reviewDate)
        #expect(remembered.stability > first.stability)
        #expect(remembered.due > reviewDate.addingTimeInterval(first.stability * day))

        let forgotten = scheduler.review(first, rating: .again, at: reviewDate)
        #expect(forgotten.stability < first.stability)
        #expect(forgotten.due == reviewDate)
        #expect(forgotten.lapses == 1)
    }

    @Test("REV-1 difficulty stays between 1 and 10")
    func difficultyBounds() {
        var hard = scheduler.review(nil, rating: .again, at: start)
        var easy = scheduler.review(nil, rating: .easy, at: start)
        for step in 1...30 {
            let date = start.addingTimeInterval(Double(step) * day * 2)
            hard = scheduler.review(hard, rating: .again, at: date)
            easy = scheduler.review(easy, rating: .easy, at: date)
        }
        #expect((1...10).contains(hard.difficulty) && hard.difficulty > 9)
        #expect((1...10).contains(easy.difficulty) && easy.difficulty < 2)
    }

    @Test("REV-4 the queue lists due words, most overdue first, then older misses")
    func dueQueue() {
        var progress = UserProgress()
        progress.incorrectWords = ["旧"]
        progress.recordAnswer(wordId: "早", isCorrect: true, rating: .good, at: start)
        progress.recordAnswer(wordId: "晚", isCorrect: true, rating: .good, at: start.addingTimeInterval(day))
        progress.recordAnswer(wordId: "错", isCorrect: false, rating: .again, at: start.addingTimeInterval(2 * day))
        progress.recordAnswer(wordId: "远", isCorrect: true, rating: .easy, at: start)

        let now = start.addingTimeInterval(5 * day)
        #expect(progress.dueWordIds(at: now) == ["旧", "错", "早", "晚"])
        #expect(progress.nextReviewDate(after: now) == progress.reviewCards["远"]?.due)
    }

    @Test("REV-5 review cards survive saving and loading")
    func cardsPersist() throws {
        var progress = UserProgress()
        progress.recordAnswer(wordId: "好", isCorrect: true, rating: .good, at: start)
        let decoded = try JSONDecoder().decode(UserProgress.self, from: JSONEncoder().encode(progress))
        #expect(decoded.reviewCards == progress.reviewCards)
    }
}
