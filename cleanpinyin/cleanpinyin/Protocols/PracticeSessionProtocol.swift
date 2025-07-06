import Foundation

protocol PracticeSessionProtocol: AnyObject {
    var currentWord: VocabularyItem? { get }
    var userInput: String { get set }
    var showHint: Bool { get set }
    var feedbackState: FeedbackState { get }
    var wordsCompleted: Int { get }
    var sessionStartTime: Date? { get }
    var wasSkipped: Bool { get }
    var isPracticeComplete: Bool { get }
    var isLastWord: Bool { get }
    var totalWords: Int { get }
    var progressPercentage: Double { get }
    var currentStreak: Int { get }
    var accuracy: String { get }
    
    func checkAnswer()
    func skipWord()
    func nextWord()
    func reloadWordsIfNeeded()
    func startCustomPractice(levels: Set<Int>)
    func startChapterPractice(chapters: Set<String>)
    func startReviewPractice(incorrectWords: Set<String>)
}