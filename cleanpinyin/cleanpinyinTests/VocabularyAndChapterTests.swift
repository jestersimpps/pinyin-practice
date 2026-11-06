import Foundation
import UIKit
import Testing
@testable import cleanpinyin

@Suite("Vocabulary data (SPEC §1)")
struct VocabularyDataTests {
    private let vocabulary = VocabularyService.shared

    @Test("DATA-5 every HSK level loads with its expected size")
    func levelSizes() {
        let sizes = PracticeSettings.hskLevels.map { vocabulary.vocabularyForLevel($0).count }
        #expect(sizes == [150, 147, 298, 598, 1300, 2500])
        #expect(vocabulary.hskWordCount == 4993)
    }

    @Test("DATA-1 every reading has one numbered syllable per character", arguments: Array(1...6))
    func readingsAreWellFormed(level: Int) {
        let syllable = /[A-Za-z]+[1-5]/
        for word in vocabulary.vocabularyForLevel(level) {
            let syllables = word.toneNumbers.split(separator: " ")
            #expect(syllables.allSatisfy { $0.wholeMatch(of: syllable) != nil }, "\(word.simplified): \(word.toneNumbers)")
            if !word.simplified.hasSuffix("儿") {
                #expect(syllables.count == word.simplified.count, "\(word.simplified): \(word.toneNumbers)")
            }
        }
    }

    @Test("DATA-2 ü is stored as v")
    func umlautSpelling() {
        let reading = { (word: String) in vocabulary.allVocabulary.first { $0.simplified == word }?.pinyin }
        #expect(reading("女儿") == "nǚ ér")
        #expect(reading("旅游") == "lǚ yóu")
        #expect(reading("路") == "lù")
    }

    @Test("DATA-3 common words never lead with a surname or a capitalised reading")
    func noSurnameReadings() {
        for word in vocabulary.allVocabulary where word.simplified.count == 1 {
            #expect(!word.toneNumbers.first!.isUppercase, "\(word.simplified): \(word.toneNumbers)")
            #expect(!word.shortTranslation.lowercased().hasPrefix("surname"), "\(word.simplified): \(word.shortTranslation)")
        }
    }

    @Test("DATA-4 a word appears at most once per level", arguments: Array(1...6))
    func uniquePerLevel(level: Int) {
        let ids = vocabulary.vocabularyForLevel(level).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Every word has an English meaning")
    func meaningsPresent() {
        #expect(vocabulary.allVocabulary.allSatisfy { !$0.shortTranslation.isEmpty })
    }
}

@Suite("Chapters (SPEC §5)")
struct ChapterTests {
    private let vocabulary = VocabularyService.shared

    @Test("CH-1 every HSK 1–2 word belongs to a chapter", arguments: [1, 2])
    func curriculumCoversEveryWord(level: Int) {
        let chapterWords = Set(vocabulary.chaptersForLevel(level).flatMap { vocabulary.vocabularyByChapter[$0.id] ?? [] }.map(\.id))
        let levelWords = Set(vocabulary.vocabularyForLevel(level).map(\.id))
        #expect(chapterWords == levelWords)
    }

    @Test("CH-1 chapters are non-empty and ordered")
    func chaptersNonEmptyAndOrdered() {
        for level in PracticeSettings.hskLevels {
            let chapters = vocabulary.chaptersForLevel(level)
            #expect(!chapters.isEmpty)
            #expect(chapters.allSatisfy { $0.wordCount > 0 && $0.wordCount == vocabulary.vocabularyByChapter[$0.id]?.count })
            #expect(chapters.map(\.chapterNumber) == chapters.map(\.chapterNumber).sorted())
        }
    }

    @Test("CH-2 HSK 3–6 are split into frequency sets of at most 40 words", arguments: [3, 4, 5, 6])
    func frequencySets(level: Int) {
        let chapters = vocabulary.chaptersForLevel(level)
        #expect(chapters.allSatisfy { $0.kind == .frequencySet && $0.wordCount <= ChapterOrganizer.wordsPerSet })
        #expect(chapters.first?.displayTitle.hasPrefix("Set 1: ") == true)
        #expect(chapters.reduce(0) { $0 + $1.wordCount } == vocabulary.vocabularyForLevel(level).count)
    }

    @Test("CH-2 every HSK 3–6 set has its own title and icon, named after a word it contains", arguments: [3, 4, 5, 6])
    func setThemes(level: Int) {
        let chapters = vocabulary.chaptersForLevel(level)
        for chapter in chapters {
            let words = vocabulary.vocabularyByChapter[chapter.id] ?? []
            let featured = String(chapter.title.prefix { !$0.isWhitespace })
            #expect(words.contains { $0.simplified == featured }, "\(chapter.id) title \(chapter.title)")
            #expect(chapter.icon != ChapterOrganizer.fallbackSetIcon, "\(chapter.id) has no themed icon")
        }
        #expect(Set(chapters.map(\.icon)).count == chapters.count, "icons repeat within HSK \(level)")
        #expect(Set(chapters.map(\.title)).count == chapters.count)
    }

    @Test("Every chapter icon is a real SF Symbol on this iOS version")
    func iconsExist() {
        let missing = Set(vocabulary.chapters.map(\.icon)).filter { UIImage(systemName: $0) == nil }
        #expect(missing.isEmpty, "missing symbols: \(missing.sorted())")
    }

    @Test("CH-3 the first chapter of each level is unlocked, the second is locked")
    func initialLocks() {
        let progress = UserProgress()
        for level in PracticeSettings.hskLevels {
            let chapters = vocabulary.chaptersForLevel(level)
            #expect(progress.isChapterUnlocked(chapters[0], levelChapters: chapters))
            #expect(!progress.isChapterUnlocked(chapters[1], levelChapters: chapters))
        }
    }

    @Test("CH-3 a chapter unlocks when the previous one reaches 80%")
    func unlocksAtEightyPercent() {
        let chapters = vocabulary.chaptersForLevel(2)
        let first = chapters[0], second = chapters[1]
        let words = vocabulary.vocabularyByChapter[first.id] ?? []
        let needed = Int((Double(words.count) * 0.8).rounded(.up))
        var progress = UserProgress()

        for word in words.prefix(needed - 1) {
            _ = progress.updateChapterProgress(chapterId: first.id, wordId: word.id, totalWords: words.count)
        }
        #expect(!progress.isChapterUnlocked(second, levelChapters: chapters))

        _ = progress.updateChapterProgress(chapterId: first.id, wordId: words[needed - 1].id, totalWords: words.count)
        #expect(progress.isChapterUnlocked(second, levelChapters: chapters))
    }

    @Test("CH-5 the next chapter continues within the level, then into the next level")
    func nextChapter() {
        let hsk1 = vocabulary.chaptersForLevel(1)
        #expect(vocabulary.nextChapter(after: hsk1[0]) == hsk1[1])
        #expect(vocabulary.nextChapter(after: hsk1.last!) == vocabulary.chaptersForLevel(2).first)
        #expect(vocabulary.nextChapter(after: vocabulary.chaptersForLevel(6).last!) == nil)
    }

    @Test("MODE-4 review words keep their order and are listed once each")
    func reviewWordsByIds() {
        let ids = vocabulary.vocabularyForLevel(1).prefix(3).map(\.id)
        let words = vocabulary.words(withIds: [ids[2], ids[0], ids[2], "unknown", ids[1]])
        #expect(words.map(\.id) == [ids[2], ids[0], ids[1]])
        #expect(Set(vocabulary.allVocabulary.map(\.id)).count == vocabulary.allVocabulary.count)
    }
}
