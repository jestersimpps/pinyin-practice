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
        if value.hasPrefix("chapter") {
            let numberPart = value.dropFirst(7)
            return Int(numberPart)
        } else if value.contains("_chapter") {
            let parts = value.split(separator: "_")
            if parts.count >= 2, let chapterPart = parts.last {
                let numberPart = chapterPart.dropFirst(7)
                return Int(numberPart)
            }
        }
        return nil
    }
    
    var hskLevel: Int? {
        if value.hasPrefix("hsk") && value.contains("_chapter") {
            let parts = value.split(separator: "_")
            if let hskPart = parts.first {
                let levelPart = hskPart.dropFirst(3)
                return Int(levelPart)
            }
        }
        return nil
    }
    
    var isCustom: Bool {
        return value.hasPrefix("custom_")
    }
    
    var customFileName: String? {
        if isCustom {
            return String(value.dropFirst(7))
        }
        return nil
    }
}