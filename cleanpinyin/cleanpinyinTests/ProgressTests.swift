import Foundation
import Testing
@testable import cleanpinyin

@Suite("Progress & streaks (SPEC §7)")
struct ProgressTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ offset: Int, hour: Int = 12) -> Date {
        let base = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: hour))!
        return calendar.date(byAdding: .day, value: offset, to: base)!
    }

    @Test("PROG-1 a word is learned once it is answered correctly")
    func learnedWords() {
        var progress = UserProgress()
        progress.recordAnswer(wordId: "你", isCorrect: false, at: day(0), calendar: calendar)
        #expect(progress.learnedWords.isEmpty)
        #expect(progress.seenWords == ["你"])

        progress.recordAnswer(wordId: "你", isCorrect: true, at: day(0), calendar: calendar)
        #expect(progress.learnedWords == ["你"])
        #expect(progress.incorrectWords.isEmpty)
    }

    @Test("PROG-2 accuracy is correct answers over attempts")
    func accuracy() {
        var progress = UserProgress()
        for isCorrect in [true, true, false, true] {
            progress.recordAnswer(wordId: "x", isCorrect: isCorrect, at: day(0), calendar: calendar)
        }
        #expect(progress.accuracy == 75)
        #expect(progress.formattedAccuracy == "75%")
    }

    @Test("PROG-3 consecutive practice days build a streak")
    func dayStreakGrows() {
        var progress = UserProgress()
        for offset in 0..<3 {
            progress.recordAnswer(wordId: "a", isCorrect: true, at: day(offset), calendar: calendar)
            progress.recordAnswer(wordId: "b", isCorrect: false, at: day(offset, hour: 20), calendar: calendar)
        }
        #expect(progress.dayStreak == 3)
        #expect(progress.currentDayStreak(asOf: day(2), calendar: calendar) == 3)
        #expect(progress.currentDayStreak(asOf: day(3), calendar: calendar) == 3)
    }

    @Test("PROG-3 missing a full day resets the streak but keeps the best")
    func dayStreakResets() {
        var progress = UserProgress()
        progress.recordAnswer(wordId: "a", isCorrect: true, at: day(0), calendar: calendar)
        progress.recordAnswer(wordId: "a", isCorrect: true, at: day(1), calendar: calendar)
        #expect(progress.currentDayStreak(asOf: day(3), calendar: calendar) == 0)

        progress.recordAnswer(wordId: "a", isCorrect: true, at: day(3), calendar: calendar)
        #expect(progress.dayStreak == 1)
        #expect(progress.bestDayStreak == 2)
    }

    @Test("PROG-3 wrong answers do not break the day streak")
    func wrongAnswersKeepDayStreak() {
        var progress = UserProgress()
        progress.recordAnswer(wordId: "a", isCorrect: true, at: day(0), calendar: calendar)
        progress.recordAnswer(wordId: "a", isCorrect: false, at: day(1), calendar: calendar)
        #expect(progress.dayStreak == 2)
    }

    @Test("PROG-4 combo counts correct answers in a row and resets on a miss")
    func combo() {
        var progress = UserProgress()
        for isCorrect in [true, true, true, false, true] {
            progress.recordAnswer(wordId: "x", isCorrect: isCorrect, at: day(0), calendar: calendar)
        }
        #expect(progress.combo == 1)
        #expect(progress.bestCombo == 3)
    }

    @Test("PROG-6 reset clears all progress")
    func reset() {
        var progress = UserProgress()
        progress.recordAnswer(wordId: "x", isCorrect: true, at: day(0), calendar: calendar)
        progress.reset()
        #expect(progress == UserProgress())
    }

    @Test("SET-5 progress saved by an older version still loads")
    func decodesLegacyProgress() throws {
        let legacy = """
        {"wordsSeenCount":3,"correctAnswers":5,"totalAttempts":8,"currentStreak":2,"bestStreak":6,
         "incorrectWords":["好"],"seenWords":["你","好","我"],"lastSeenWordId":"我","chapterProgress":{}}
        """
        let progress = try JSONDecoder().decode(UserProgress.self, from: Data(legacy.utf8))
        #expect(progress.correctAnswers == 5)
        #expect(progress.bestCombo == 6)
        #expect(progress.learnedWords == ["你", "我"])
        #expect(progress.incorrectWords == ["好"])
    }

    @Test("Progress survives an encode/decode round trip")
    func roundTrip() throws {
        var progress = UserProgress()
        progress.recordAnswer(wordId: "你", isCorrect: true, at: day(0), calendar: calendar)
        let decoded = try JSONDecoder().decode(UserProgress.self, from: JSONEncoder().encode(progress))
        #expect(decoded == progress)
    }
}

@Suite("Settings (SPEC §8)")
struct SettingsTests {
    @Test("SET-5 settings from an older version keep their values")
    func decodesLegacySettings() throws {
        let legacy = """
        {"selectedHSKLevels":[7],"practiceMode":"Random","showToneNumbers":true,"showHints":false,
         "requireTones":true,"isReviewMode":true,"lastPracticeMode":"custom"}
        """
        let settings = try JSONDecoder().decode(PracticeSettings.self, from: Data(legacy.utf8))
        #expect(settings.selectedHSKLevels == [1])
        #expect(settings.practiceMode == .random)
        #expect(settings.requireTones)
        #expect(!settings.showPronunciationHints)
        #expect(!settings.showCharacterHints)
        #expect(settings.speakOnCorrectAnswer)
    }

    @Test("SET-2 Quick Practice levels are always valid and never empty")
    func levelsSanitized() {
        var settings = PracticeSettings()
        settings.selectedHSKLevels = []
        #expect(settings.selectedHSKLevels == [1])
        settings.selectedHSKLevels = [2, 9]
        #expect(settings.selectedHSKLevels == [2])
    }
}
