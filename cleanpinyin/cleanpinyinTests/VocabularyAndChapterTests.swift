import Foundation
import UIKit
import Testing
@testable import cleanpinyin

enum WordLists {
    static let hsk3 = VocabularyService(syllabus: .hsk3)
    static let hsk2 = VocabularyService(syllabus: .hsk2)

    static func service(_ syllabus: HSKSyllabus) -> VocabularyService {
        syllabus == .hsk3 ? hsk3 : hsk2
    }
}

@Suite("Vocabulary data (SPEC §1)")
struct VocabularyDataTests {
    private let allWords = WordLists.hsk3.allVocabulary

    @Test("DATA-5 every HSK level loads with its expected size", arguments: [
        (HSKSyllabus.hsk3, [294, 197, 487, 972, 1547, 1684], 5181),
        (HSKSyllabus.hsk2, [150, 147, 298, 598, 1300, 2500], 4993),
    ])
    func levelSizes(syllabus: HSKSyllabus, sizes: [Int], total: Int) {
        let vocabulary = WordLists.service(syllabus)
        #expect(PracticeSettings.hskLevels.map { vocabulary.vocabularyForLevel($0).count } == sizes)
        #expect(vocabulary.hskWordCount == total)
    }

    @Test("DATA-6 both lists share one word bank")
    func sharedBank() {
        #expect(allWords.count == 7018)
        let both = allWords.filter { $0.level(in: .hsk3) != nil && $0.level(in: .hsk2) != nil }
        #expect(both.count == 3156)
        #expect(allWords.allSatisfy { $0.level(in: .hsk3) != nil || $0.level(in: .hsk2) != nil })
    }

    @Test("DATA-1 every reading has one numbered syllable per character")
    func readingsAreWellFormed() {
        let syllable = /[A-Za-z]+[1-5]/
        for word in allWords {
            let syllables = word.toneNumbers.split(separator: " ")
            #expect(syllables.allSatisfy { $0.wholeMatch(of: syllable) != nil }, "\(word.simplified): \(word.toneNumbers)")
            if !word.simplified.hasSuffix("儿") {
                #expect(syllables.count == word.simplified.count, "\(word.simplified): \(word.toneNumbers)")
            }
        }
    }

    @Test("DATA-7 readings follow the official HSK 3.0 syllabus", arguments: [
        ("看", "kan4"), ("听", "ting1"), ("个", "ge4"), ("要", "yao4"), ("骑", "qi2"),
        ("便宜", "pian2 yi5"), ("东西", "dong1 xi5"), ("雨", "yu3"), ("为", "wei4"), ("都", "dou1"),
    ])
    func officialReadings(word: String, reading: String) {
        #expect(allWords.first { $0.simplified == word }?.toneNumbers == reading)
    }

    @Test("DATA-8 traditional characters are the standard form, not a rare variant", arguments: [
        ("拿", "拿"), ("碗", "碗"), ("夜", "夜"), ("从", "從"), ("墙", "牆"), ("老板", "老闆"),
    ])
    func traditionalForms(word: String, traditional: String) {
        #expect(allWords.first { $0.simplified == word }?.traditional == traditional)
    }

    @Test("DATA-2 ü is stored as v")
    func umlautSpelling() {
        let reading = { (word: String) in allWords.first { $0.simplified == word }?.pinyin }
        #expect(reading("女儿") == "nǚ ér")
        #expect(reading("旅游") == "lǚ yóu")
        #expect(reading("路") == "lù")
    }

    @Test("DATA-3 common words never lead with a surname, a variant note or a capitalised reading")
    func noSurnameReadings() {
        for word in allWords {
            #expect(!word.shortTranslation.lowercased().hasPrefix("variant of"), "\(word.simplified): \(word.shortTranslation)")
            guard word.simplified.count == 1 else { continue }
            #expect(!word.toneNumbers.first!.isUppercase, "\(word.simplified): \(word.toneNumbers)")
            #expect(!word.shortTranslation.lowercased().hasPrefix("surname"), "\(word.simplified): \(word.shortTranslation)")
        }
    }

    @Test("DATA-4 a word appears at most once per level", arguments: HSKSyllabus.allCases, Array(1...6))
    func uniquePerLevel(syllabus: HSKSyllabus, level: Int) {
        let ids = WordLists.service(syllabus).vocabularyForLevel(level).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Every word has an English meaning")
    func meaningsPresent() {
        #expect(allWords.allSatisfy { !$0.shortTranslation.isEmpty })
    }
}

@Suite("Chapters (SPEC §5)")
struct ChapterTests {
    private let hsk2 = WordLists.hsk2

    @Test("CH-1 every HSK 2.0 level 1–2 word belongs to a topic chapter", arguments: [1, 2])
    func curriculumCoversEveryWord(level: Int) {
        let chapters = hsk2.chaptersForLevel(level)
        let chapterWords = Set(chapters.flatMap { hsk2.vocabularyByChapter[$0.id] ?? [] }.map(\.id))
        #expect(chapters.allSatisfy { $0.kind == .curriculum })
        #expect(chapterWords == Set(hsk2.vocabularyForLevel(level).map(\.id)))
    }

    @Test("CH-1 chapters are non-empty and ordered", arguments: HSKSyllabus.allCases)
    func chaptersNonEmptyAndOrdered(syllabus: HSKSyllabus) {
        let vocabulary = WordLists.service(syllabus)
        for level in PracticeSettings.hskLevels {
            let chapters = vocabulary.chaptersForLevel(level)
            #expect(!chapters.isEmpty)
            #expect(chapters.allSatisfy { $0.wordCount > 0 && $0.wordCount == vocabulary.vocabularyByChapter[$0.id]?.count })
            #expect(chapters.map(\.chapterNumber) == chapters.map(\.chapterNumber).sorted())
        }
    }

    @Test("CH-2 frequency sets hold at most 40 words and cover the level", arguments: [
        (HSKSyllabus.hsk2, 3), (.hsk2, 4), (.hsk2, 5), (.hsk2, 6),
        (.hsk3, 1), (.hsk3, 2), (.hsk3, 3), (.hsk3, 4), (.hsk3, 5), (.hsk3, 6),
    ])
    func frequencySets(syllabus: HSKSyllabus, level: Int) {
        let vocabulary = WordLists.service(syllabus)
        let chapters = vocabulary.chaptersForLevel(level)
        #expect(chapters.allSatisfy { $0.kind == .frequencySet && $0.wordCount <= ChapterOrganizer.wordsPerSet })
        #expect(chapters.first?.displayTitle.hasPrefix("Set 1: ") == true)
        #expect(chapters.reduce(0) { $0 + $1.wordCount } == vocabulary.vocabularyForLevel(level).count)
    }

    @Test("CH-2 every set has its own title and icon, named after a word it contains", arguments: [
        (HSKSyllabus.hsk2, 3), (.hsk2, 4), (.hsk2, 5), (.hsk2, 6),
        (.hsk3, 1), (.hsk3, 2), (.hsk3, 3), (.hsk3, 4), (.hsk3, 5), (.hsk3, 6),
    ])
    func setThemes(syllabus: HSKSyllabus, level: Int) {
        let vocabulary = WordLists.service(syllabus)
        let chapters = vocabulary.chaptersForLevel(level)
        for chapter in chapters {
            let words = vocabulary.vocabularyByChapter[chapter.id] ?? []
            let featured = String(chapter.title.prefix { !$0.isWhitespace })
            #expect(words.contains { $0.simplified == featured }, "\(chapter.id) title \(chapter.title)")
            #expect(chapter.icon != ChapterOrganizer.fallbackSetIcon, "\(chapter.id) has no themed icon")
        }
        #expect(Set(chapters.map(\.icon)).count == chapters.count, "icons repeat within \(syllabus.name) HSK \(level)")
        #expect(Set(chapters.map(\.title)).count == chapters.count)
    }

    @Test("CH-6 HSK 2.0 keeps its original chapter ids and HSK 3.0 ids never collide with them")
    func chapterIds() {
        #expect(hsk2.chapter(withId: "chapter1") != nil)
        #expect(hsk2.chapter(withId: "hsk3_set1") != nil)
        let hsk3Ids = Set(WordLists.hsk3.chapters.filter { $0.kind != .custom }.map(\.id))
        #expect(hsk3Ids.allSatisfy { $0.hasPrefix(HSKSyllabus.hsk3.chapterIdPrefix) })
        #expect(hsk3Ids.isDisjoint(with: hsk2.chapters.map(\.id)))
    }

    @Test("Every chapter icon is a real SF Symbol on this iOS version", arguments: HSKSyllabus.allCases)
    func iconsExist(syllabus: HSKSyllabus) {
        let missing = Set(WordLists.service(syllabus).chapters.map(\.icon)).filter { UIImage(systemName: $0) == nil }
        #expect(missing.isEmpty, "missing symbols: \(missing.sorted())")
    }

    @Test("CH-3 the first chapter of each level is unlocked, the second is locked", arguments: HSKSyllabus.allCases)
    func initialLocks(syllabus: HSKSyllabus) {
        let progress = UserProgress()
        for level in PracticeSettings.hskLevels {
            let chapters = WordLists.service(syllabus).chaptersForLevel(level)
            #expect(progress.isChapterUnlocked(chapters[0], levelChapters: chapters))
            #expect(!progress.isChapterUnlocked(chapters[1], levelChapters: chapters))
        }
    }

    @Test("CH-3 a chapter unlocks when the previous one reaches 80%")
    func unlocksAtEightyPercent() {
        let chapters = hsk2.chaptersForLevel(2)
        let first = chapters[0], second = chapters[1]
        let words = hsk2.vocabularyByChapter[first.id] ?? []
        let needed = Int((Double(words.count) * 0.8).rounded(.up))
        var progress = UserProgress()

        for word in words.prefix(needed - 1) {
            _ = progress.updateChapterProgress(chapterId: first.id, wordId: word.id, totalWords: words.count)
        }
        #expect(!progress.isChapterUnlocked(second, levelChapters: chapters))

        _ = progress.updateChapterProgress(chapterId: first.id, wordId: words[needed - 1].id, totalWords: words.count)
        #expect(progress.isChapterUnlocked(second, levelChapters: chapters))
    }

    @Test("CH-5 the next chapter continues within the level, then into the next level", arguments: HSKSyllabus.allCases)
    func nextChapter(syllabus: HSKSyllabus) {
        let vocabulary = WordLists.service(syllabus)
        let hsk1 = vocabulary.chaptersForLevel(1)
        #expect(vocabulary.nextChapter(after: hsk1[0]) == hsk1[1])
        #expect(vocabulary.nextChapter(after: hsk1.last!) == vocabulary.chaptersForLevel(2).first)
        #expect(vocabulary.nextChapter(after: vocabulary.chaptersForLevel(6).last!) == nil)
    }

    @Test("MODE-4 review words keep their order and are listed once each")
    func reviewWordsByIds() {
        let ids = hsk2.vocabularyForLevel(1).prefix(3).map(\.id)
        let words = hsk2.words(withIds: [ids[2], ids[0], ids[2], "unknown", ids[1]])
        #expect(words.map(\.id) == [ids[2], ids[0], ids[1]])
        #expect(Set(hsk2.allVocabulary.map(\.id)).count == hsk2.allVocabulary.count)
    }
}

@MainActor
@Suite("Word list toggle (SPEC §1)", .serialized)
struct WordListToggleTests {
    private let vocabulary = VocabularyService(syllabus: .hsk3)
    private let progress: UserProgressService

    init() {
        let suite = "cleanpinyin.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        progress = UserProgressService(defaults: defaults)
    }

    @Test("DATA-9 switching lists changes levels and chapters, not the words you can review")
    func switchingLists() {
        let hsk2Only = WordLists.hsk2.vocabularyForLevel(1).first { $0.level(in: .hsk3) == nil }!

        progress.selectSyllabus(.hsk2, vocabulary: vocabulary)
        #expect(vocabulary.syllabus == .hsk2)
        #expect(progress.settings.syllabus == .hsk2)
        #expect(vocabulary.hskWordCount == 4993)

        progress.selectSyllabus(.hsk3, vocabulary: vocabulary)
        #expect(vocabulary.hskWordCount == 5181)
        #expect(!vocabulary.vocabularyForLevel(1).contains { $0.id == hsk2Only.id })
        #expect(vocabulary.words(withIds: [hsk2Only.id]).map(\.id) == [hsk2Only.id])
    }

    @Test("DATA-9 learned words carry over and chapters from the other list are deselected")
    func progressCarriesOver() {
        let shared = WordLists.hsk2.vocabularyForLevel(1).first { $0.level(in: .hsk3) != nil }!
        progress.selectSyllabus(.hsk2, vocabulary: vocabulary)
        progress.recordAnswer(for: shared, isCorrect: true, rating: .good)
        progress.settings.selectedChapters = ["chapter1"]

        progress.selectSyllabus(.hsk3, vocabulary: vocabulary)
        #expect(progress.progress.learnedWords.contains(shared.id))
        #expect(progress.getWordsLearnedForLevel(shared.level(in: .hsk3)!, vocabulary: vocabulary) == 1)
        #expect(progress.settings.selectedChapters.isEmpty)
    }
}
