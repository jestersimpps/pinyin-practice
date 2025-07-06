import Foundation

protocol WordLoading {
    func loadWords(for mode: LearningMode, settings: PracticeSettings) -> [VocabularyItem]
}

final class WordLoader: WordLoading {
    private let vocabularyService: VocabularyProviding
    private let progressTracker: ProgressTracking
    
    init(vocabularyService: VocabularyProviding, progressTracker: ProgressTracking) {
        self.vocabularyService = vocabularyService
        self.progressTracker = progressTracker
    }
    
    func loadWords(for mode: LearningMode, settings: PracticeSettings) -> [VocabularyItem] {
        let wordsToStudy = getWordsForMode(mode)
        return orderWords(wordsToStudy, settings: settings)
    }
    
    private func getWordsForMode(_ mode: LearningMode) -> [VocabularyItem] {
        switch mode {
        case .levels(let levels):
            return vocabularyService.getVocabularyForLevels(levels)
            
        case .chapters(let chapters):
            return vocabularyService.getVocabularyForChapters(chapters)
            
        case .review(let incorrectWords):
            return vocabularyService.getReviewVocabulary(incorrectWordIds: incorrectWords)
        }
    }
    
    private func orderWords(_ words: [VocabularyItem], settings: PracticeSettings) -> [VocabularyItem] {
        switch settings.practiceMode {
        case .sequential:
            return words.sorted { $0.frequency < $1.frequency }
            
        case .random:
            var shuffledWords = words
            shuffledWords.shuffle()
            
            let seenWords = progressTracker.seenWords
            return shuffledWords.sorted { word1, word2 in
                let word1Seen = seenWords.contains(word1.id)
                let word2Seen = seenWords.contains(word2.id)
                
                if word1Seen == word2Seen { return false }
                return !word1Seen && word2Seen
            }
        }
    }
}