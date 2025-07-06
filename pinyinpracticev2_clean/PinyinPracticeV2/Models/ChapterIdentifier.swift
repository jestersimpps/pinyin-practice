import Foundation

struct ChapterIdentifier: Hashable, Codable {
    let rawValue: String
    
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    var globalChapterNumber: Int? {
        if rawValue.hasPrefix("chapter") && !rawValue.contains("_") {
            return Int(rawValue.replacingOccurrences(of: "chapter", with: ""))
        } else if rawValue.contains("chapter_") {
            return Int(rawValue.replacingOccurrences(of: "chapter_", with: ""))
        } else if rawValue.contains("hsk") && rawValue.contains("_chapter") {
            let components = rawValue.components(separatedBy: "_chapter")
            if components.count == 2 {
                let levelStr = components[0].replacingOccurrences(of: "hsk", with: "")
                if let level = Int(levelStr),
                   let localChapterNum = Int(components[1]),
                   let offset = Constants.HSK.chapterOffsets[level] {
                    return offset + localChapterNum
                }
            }
        }
        return nil
    }
    
    var hskLevel: Int? {
        guard let globalNumber = globalChapterNumber else { return nil }
        return ChapterCurriculum.getChapterInfo(chapter: globalNumber).hskLevel
    }
    
    var isCustomChapter: Bool {
        return rawValue.hasPrefix("custom_")
    }
    
    static func fromGlobalNumber(_ number: Int) -> ChapterIdentifier {
        return ChapterIdentifier("chapter\(number)")
    }
    
    static func fromLevelAndNumber(level: Int, chapterNumber: Int) -> ChapterIdentifier {
        if let offset = Constants.HSK.chapterOffsets[level] {
            let globalNumber = offset + chapterNumber
            return ChapterIdentifier("chapter\(globalNumber)")
        }
        return ChapterIdentifier("hsk\(level)_chapter\(chapterNumber)")
    }
}