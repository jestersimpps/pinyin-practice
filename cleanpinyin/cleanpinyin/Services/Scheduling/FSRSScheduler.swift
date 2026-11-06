import Foundation

// FSRS-5 spaced repetition (https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm)
struct FSRSScheduler {
    static let defaultWeights: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192,
        1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621
    ]

    private static let decay = -0.5
    private static let factor = 19.0 / 81.0
    private static let secondsPerDay = 86_400.0

    let weights: [Double]
    let desiredRetention: Double
    let maximumIntervalDays: Double

    init(weights: [Double] = FSRSScheduler.defaultWeights, desiredRetention: Double = 0.9, maximumIntervalDays: Double = 365) {
        self.weights = weights
        self.desiredRetention = desiredRetention
        self.maximumIntervalDays = maximumIntervalDays
    }

    func review(_ card: ReviewCard?, rating: ReviewRating, at now: Date) -> ReviewCard {
        guard let card else { return firstReview(rating: rating, at: now) }

        let elapsedDays = max(0, now.timeIntervalSince(card.lastReview) / Self.secondsPerDay)
        let difficulty = nextDifficulty(card.difficulty, rating: rating)
        let stability: Double

        if elapsedDays < 1 {
            stability = shortTermStability(card.stability, rating: rating)
        } else {
            let recall = retrievability(elapsedDays: elapsedDays, stability: card.stability)
            stability = rating == .again
                ? forgetStability(card.stability, difficulty: card.difficulty, recall: recall)
                : recallStability(card.stability, difficulty: card.difficulty, recall: recall, rating: rating)
        }

        return ReviewCard(
            stability: stability,
            difficulty: difficulty,
            due: dueDate(stability: stability, rating: rating, from: now),
            lastReview: now,
            reps: card.reps + 1,
            lapses: card.lapses + (rating == .again ? 1 : 0)
        )
    }

    func retrievability(elapsedDays: Double, stability: Double) -> Double {
        pow(1 + Self.factor * elapsedDays / stability, Self.decay)
    }

    func intervalDays(for stability: Double) -> Double {
        let raw = stability / Self.factor * (pow(desiredRetention, 1 / Self.decay) - 1)
        return min(max(raw.rounded(), 1), maximumIntervalDays)
    }

    // MARK: - FSRS-5 formulas

    private func firstReview(rating: ReviewRating, at now: Date) -> ReviewCard {
        let stability = initialStability(rating)
        return ReviewCard(
            stability: stability,
            difficulty: initialDifficulty(rating),
            due: dueDate(stability: stability, rating: rating, from: now),
            lastReview: now,
            reps: 1,
            lapses: rating == .again ? 1 : 0
        )
    }

    private func initialStability(_ rating: ReviewRating) -> Double {
        max(weights[rating.rawValue - 1], 0.1)
    }

    private func initialDifficulty(_ rating: ReviewRating) -> Double {
        clampDifficulty(weights[4] - exp(weights[5] * Double(rating.rawValue - 1)) + 1)
    }

    private func nextDifficulty(_ difficulty: Double, rating: ReviewRating) -> Double {
        let delta = -weights[6] * Double(rating.rawValue - 3)
        let damped = difficulty + delta * (10 - difficulty) / 9
        let reverted = weights[7] * initialDifficulty(.easy) + (1 - weights[7]) * damped
        return clampDifficulty(reverted)
    }

    private func recallStability(_ stability: Double, difficulty: Double, recall: Double, rating: ReviewRating) -> Double {
        let hardPenalty = rating == .hard ? weights[15] : 1
        let easyBonus = rating == .easy ? weights[16] : 1
        let growth = exp(weights[8]) * (11 - difficulty) * pow(stability, -weights[9]) * (exp(weights[10] * (1 - recall)) - 1)
        return stability * (1 + growth * hardPenalty * easyBonus)
    }

    private func forgetStability(_ stability: Double, difficulty: Double, recall: Double) -> Double {
        let forgotten = weights[11] * pow(difficulty, -weights[12]) * (pow(stability + 1, weights[13]) - 1) * exp(weights[14] * (1 - recall))
        return max(0.1, min(forgotten, stability / exp(weights[17] * weights[18])))
    }

    private func shortTermStability(_ stability: Double, rating: ReviewRating) -> Double {
        max(0.1, stability * exp(weights[17] * (Double(rating.rawValue) - 3 + weights[18])))
    }

    private func clampDifficulty(_ difficulty: Double) -> Double {
        min(max(difficulty, 1), 10)
    }

    // A forgotten word comes straight back; otherwise wait the FSRS interval for the target retention
    private func dueDate(stability: Double, rating: ReviewRating, from now: Date) -> Date {
        guard rating != .again else { return now }
        return now.addingTimeInterval(intervalDays(for: stability) * Self.secondsPerDay)
    }
}
