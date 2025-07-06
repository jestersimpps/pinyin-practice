import Foundation

struct FileNameFormatter {
    // Format vocabulary file name for a given HSK level
    static func vocabularyFileName(for level: Int) -> String {
        return "\(level).min.json"
    }
    
    // Format custom vocabulary file name
    static func customVocabularyFileName(category: String, subcategory: String) -> String {
        return "\(category.lowercased())-\(subcategory).json"
    }
    
    // Parse HSK level from file name
    static func parseHSKLevel(from fileName: String) -> Int? {
        // Handle "1.min.json" format
        if fileName.hasSuffix(".min.json") {
            let levelString = fileName.replacingOccurrences(of: ".min.json", with: "")
            return Int(levelString)
        }
        
        // Handle "hsk1.json" format
        if fileName.hasPrefix("hsk") && fileName.hasSuffix(".json") {
            let levelString = fileName
                .replacingOccurrences(of: "hsk", with: "")
                .replacingOccurrences(of: ".json", with: "")
            return Int(levelString)
        }
        
        return nil
    }
    
    // Parse custom category from file name
    static func parseCustomCategory(from fileName: String) -> (category: String, subcategory: String)? {
        // Handle "category-subcategory.json" format
        guard fileName.hasSuffix(".json") else { return nil }
        
        let nameWithoutExtension = fileName.replacingOccurrences(of: ".json", with: "")
        let components = nameWithoutExtension.split(separator: "-")
        
        guard components.count >= 2 else { return nil }
        
        let category = String(components[0])
        let subcategory = components[1...].joined(separator: "-")
        
        return (category, subcategory)
    }
    
    // Format chapter ID
    static func formatChapterId(level: Int? = nil, chapter: Int) -> String {
        if let level = level {
            return "hsk\(level)_chapter\(chapter)"
        } else {
            return "chapter_\(chapter)"
        }
    }
    
    // Parse chapter information from ID
    static func parseChapterId(_ chapterId: String) -> (level: Int?, chapter: Int)? {
        // Handle "chapter_15" format
        if chapterId.hasPrefix("chapter_") {
            let chapterString = chapterId.replacingOccurrences(of: "chapter_", with: "")
            if let chapter = Int(chapterString) {
                return (nil, chapter)
            }
        }
        
        // Handle "chapter15" format
        if chapterId.hasPrefix("chapter") && !chapterId.contains("_") {
            let chapterString = chapterId.replacingOccurrences(of: "chapter", with: "")
            if let chapter = Int(chapterString) {
                return (nil, chapter)
            }
        }
        
        // Handle "hsk1_chapter5" format
        if chapterId.contains("hsk") && chapterId.contains("_chapter") {
            let components = chapterId.components(separatedBy: "_chapter")
            if components.count == 2 {
                let levelString = components[0].replacingOccurrences(of: "hsk", with: "")
                if let level = Int(levelString),
                   let chapter = Int(components[1]) {
                    return (level, chapter)
                }
            }
        }
        
        return nil
    }
    
    // Normalize chapter ID to consistent format
    static func normalizeChapterId(_ chapterId: String) -> String {
        if let (level, chapter) = parseChapterId(chapterId) {
            return formatChapterId(level: level, chapter: chapter)
        }
        return chapterId
    }
    
    // Get file path for vocabulary data
    static func vocabularyFilePath(for level: Int, in bundle: Bundle = .main) -> URL? {
        let fileName = vocabularyFileName(for: level)
        return bundle.url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), 
                          withExtension: "json", 
                          subdirectory: AppConstants.FileNames.dataFolder)
    }
    
    // Get file path for custom vocabulary data
    static func customVocabularyFilePath(
        category: String, 
        subcategory: String, 
        in bundle: Bundle = .main
    ) -> URL? {
        let fileName = customVocabularyFileName(category: category, subcategory: subcategory)
        return bundle.url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), 
                          withExtension: "json", 
                          subdirectory: AppConstants.FileNames.customDataFolder)
    }
    
    // Validate file name format
    static func isValidVocabularyFileName(_ fileName: String) -> Bool {
        // Check HSK format
        if let level = parseHSKLevel(from: fileName) {
            return level >= 1 && level <= 6
        }
        
        // Check custom format
        if parseCustomCategory(from: fileName) != nil {
            return true
        }
        
        return false
    }
}