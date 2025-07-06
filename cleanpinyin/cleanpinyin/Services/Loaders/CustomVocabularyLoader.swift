import Foundation

class CustomVocabularyLoader {
    private let fileLoader = VocabularyFileLoader()
    
    func loadCustomVocabulary() -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]], allItems: [VocabularyItem]) {

        print("Starting to load custom vocabulary files...")
        
        if let customDataPath = Bundle.main.path(forResource: "CustomData", ofType: nil) {
            print("CustomData folder found at: \(customDataPath)")
            let result = loadFilesFromDirectory(at: customDataPath)
            return (result.chapters, result.vocabularyByChapter, result.allItems)
        } else {
            print("CustomData folder not found as folder reference, trying individual files...")
            let result = loadIndividualFiles()
            return (result.chapters, result.vocabularyByChapter, result.allItems)
        }
    }
    
    private func loadFilesFromDirectory(at path: String) -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]], allItems: [VocabularyItem]) {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        var allItems: [VocabularyItem] = []
        
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            let jsonFiles = contents.filter { $0.hasSuffix(".json") }.sorted()
            
            print("Found \(jsonFiles.count) JSON files in CustomData: \(jsonFiles)")
            
            for (index, filename) in jsonFiles.enumerated() {
                let filePath = (path as NSString).appendingPathComponent(filename)
                let fileURL = URL(fileURLWithPath: filePath)
                
                if let chapter = processCustomFile(at: fileURL, chapterNumber: index + 1) {
                    chapters.append(chapter.chapter)
                    vocabularyByChapter[chapter.chapter.id] = chapter.items
                    allItems.append(contentsOf: chapter.items)
                }
            }
        } catch {
            print("Error reading CustomData directory: \(error)")
        }
        
        return (chapters, vocabularyByChapter, allItems)
    }
    
    private func loadIndividualFiles() -> (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]], allItems: [VocabularyItem]) {
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        var allItems: [VocabularyItem] = []
        
        let fileNames = [
            "basic-1-1",
            "basic-1-2",
            "basic-2-1",
            "basic-2-2"
        ]
        
        var loadedCount = 0
        
        for fileName in fileNames {
            if let url = Bundle.main.url(forResource: "CustomData/\(fileName)", withExtension: "json") {
                print("Found file: CustomData/\(fileName).json")
                if let chapter = processCustomFile(at: url, chapterNumber: loadedCount + 1) {
                    chapters.append(chapter.chapter)
                    vocabularyByChapter[chapter.chapter.id] = chapter.items
                    allItems.append(contentsOf: chapter.items)
                    loadedCount += 1
                }
            } else if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
                print("Found file: \(fileName).json")
                if let chapter = processCustomFile(at: url, chapterNumber: loadedCount + 1) {
                    chapters.append(chapter.chapter)
                    vocabularyByChapter[chapter.chapter.id] = chapter.items
                    allItems.append(contentsOf: chapter.items)
                    loadedCount += 1
                }
            }
        }
        
        discoverAdditionalCustomFiles()
        
        if loadedCount == 0 {
            print("No custom files found. Please add JSON files to Xcode project.")
            print("To add: Drag the JSON files into Xcode's project navigator")
        } else {
            print("Successfully loaded \(loadedCount) custom vocabulary files")
        }
        
        return (chapters, vocabularyByChapter, allItems)
    }
    
    private func processCustomFile(at url: URL, chapterNumber: Int) -> (chapter: Chapter, items: [VocabularyItem])? {
        switch fileLoader.loadCustomFile(at: url) {
        case .success(let items):
            let filename = url.deletingPathExtension().lastPathComponent
            let chapterId = ChapterIdentifier(customFileName: filename).value
            
            let chapterTitle = formatChapterTitle(from: filename)
            
            let customChapter = Chapter(
                id: chapterId,
                hskLevel: 7,
                chapterNumber: chapterNumber,
                title: chapterTitle,
                description: "Practice with \(chapterTitle.lowercased()) vocabulary",
                wordCount: items.count,
                isUnlocked: true,
                icon: getCustomChapterIcon(for: chapterNumber)
            )
            
            print("Loaded custom chapter: \(chapterTitle) with \(items.count) words")
            return (customChapter, items)
            
        case .failure(let error):
            print("Error loading custom vocabulary from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func discoverAdditionalCustomFiles() {
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let customJsonFiles = contents.filter {
                    $0.hasSuffix(".json") &&
                    ($0.contains("custom") || $0.contains("basic") || $0.contains("Custom"))
                }
                print("Found potential custom JSON files in bundle: \(customJsonFiles)")
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
    }
    
    private func formatChapterTitle(from filename: String) -> String {
        var title = filename
        
        if title.lowercased().hasPrefix("basic-") {
            title = title.replacingOccurrences(of: "basic-", with: "Basic ", options: .caseInsensitive)
            return title
        }
        
        if title.lowercased().hasPrefix("custom") {
            title = String(title.dropFirst(6))
        }
        
        title = title.replacingOccurrences(of: "_", with: " ")
        title = title.replacingOccurrences(of: "-", with: " ")
        
        if let firstChar = title.first, firstChar.isNumber {
            let components = title.split(separator: " ")
            if components.count == 1 && components[0].contains(where: { !$0.isNumber && $0 != "-" }) {
                if let nonNumberIndex = title.firstIndex(where: { !$0.isNumber }) {
                    title = String(title[nonNumberIndex...])
                }
            }
        }
        
        title = title.trimmingCharacters(in: .whitespaces)
        
        return title.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    private func getCustomChapterIcon(for chapterNumber: Int) -> String {
        let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "sparkles", "moon.fill", "sun.max.fill", "cloud.fill"]
        return icons[(chapterNumber - 1) % icons.count]
    }
}
