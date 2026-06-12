import Foundation

struct ChapterIdentifier: Hashable, Codable {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    init(chapterNumber: Int) {
        self.value = "chapter\(chapterNumber)"
    }

    init(hskLevel: Int, chapterNumber: Int) {
        self.value = "hsk\(hskLevel)_chapter\(chapterNumber)"
    }

    init(customFileName: String) {
        self.value = "custom_\(customFileName)"
    }

    var chapterNumber: Int? {
        if value.hasPrefix("chapter_") {
            return Int(value.dropFirst("chapter_".count))
        }
        if value.hasPrefix("chapter") {
            return Int(value.dropFirst("chapter".count))
        }
        if value.contains("_chapter"), let chapterPart = value.split(separator: "_").last {
            return Int(chapterPart.dropFirst("chapter".count))
        }
        return nil
    }

    var hskLevel: Int? {
        if value.hasPrefix("hsk"), value.contains("_chapter"), let hskPart = value.split(separator: "_").first {
            return Int(hskPart.dropFirst("hsk".count))
        }
        if isCurriculumChapter, let chapterNumber {
            return ChapterCurriculum.hskLevel(forChapter: chapterNumber)
        }
        return nil
    }

    var globalChapterNumber: Int? {
        guard let chapterNumber else { return nil }
        if isCurriculumChapter {
            return chapterNumber
        }
        if value.hasPrefix("hsk"), let hskLevel {
            return ChapterCurriculum.globalChapterNumber(level: hskLevel, localChapter: chapterNumber)
        }
        return nil
    }

    var isCurriculumChapter: Bool {
        value.hasPrefix("chapter")
    }

    var isCustom: Bool {
        value.hasPrefix("custom_")
    }

    var customFileName: String? {
        guard isCustom else { return nil }
        return String(value.dropFirst("custom_".count))
    }
}
