import Foundation

class VocabularyService: ObservableObject {
    static let shared = VocabularyService()
    
    @Published var allVocabulary: [VocabularyItem] = []
    @Published var vocabularyByLevel: [Int: [VocabularyItem]] = [:]
    @Published var vocabularyByChapter: [String: [VocabularyItem]] = [:]
    @Published var chapters: [Chapter] = []
    @Published var customVocabulary: [VocabularyItem] = []
    @Published var isLoading = false
    
    private init() {
        loadVocabulary()
    }
    
    func loadVocabulary() {
        isLoading = true
        
        var allItems: [VocabularyItem] = []
        chapters.removeAll()
        vocabularyByChapter.removeAll()
        
        for level in 1...6 {
            if let items = loadVocabularyFromJSON(level: level) {
                // Sort by frequency for chapter assignment
                let sortedItems = items.sorted { $0.frequency < $1.frequency }
                vocabularyByLevel[level] = sortedItems
                allItems.append(contentsOf: sortedItems)
                
                // Organize into chapters
                organizeIntoChapters(items: sortedItems, level: level)
            }
        }
        
        // Load custom vocabulary from current.json
        loadCustomVocabulary()
        
        allVocabulary = allItems
        isLoading = false
    }
    
    private func organizeIntoChapters(items: [VocabularyItem], level: Int) {
        // Check if items have cp (chapter progression) values
        let itemsWithChapters = items.filter { $0.cp != nil }
        
        if !itemsWithChapters.isEmpty {
            // Use curriculum-based chapter organization
            organizeVocabularyByCurriculum(items: items, level: level)
        } else {
            // Fall back to frequency-based organization
            organizeVocabularyByFrequency(items: items, level: level)
        }
    }
    
    private func organizeVocabularyByCurriculum(items: [VocabularyItem], level: Int) {
        // Group items by their cp (chapter progression) value
        let groupedByChapter = Dictionary(grouping: items) { item in
            item.cp ?? 0
        }
        
        // Create chapters based on curriculum
        for (chapterNum, chapterItems) in groupedByChapter where chapterNum > 0 {
            // Skip review chapters
            if ChapterCurriculum.reviewChapters.contains(chapterNum) {
                continue
            }
            
            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: chapterNum)
            
            // Only process if this chapter belongs to the current HSK level
            if chapterInfo.hskLevel == level {
                let chapterId = "chapter\(chapterNum)"
                vocabularyByChapter[chapterId] = chapterItems
                
                
                let chapter = Chapter(
                    id: chapterId,
                    hskLevel: level,
                    chapterNumber: chapterNum,
                    title: chapterInfo.title,
                    description: chapterInfo.description,
                    wordCount: chapterItems.count,
                    isUnlocked: chapterNum == 1 || isChapterUnlocked(chapterNum),
                    icon: chapterInfo.icon
                )
                
                chapters.append(chapter)
            }
        }
        
        // Sort chapters by number
        chapters.sort { $0.chapterNumber < $1.chapterNumber }
    }
    
    private func organizeVocabularyByFrequency(items: [VocabularyItem], level: Int) {
        // Original frequency-based organization
        let sortedItems = items.sorted { $0.frequency < $1.frequency }
        
        let chaptersCount = ChapterCurriculum.chaptersForLevel(level)
        let wordsPerChapter = items.count / chaptersCount
        let remainder = items.count % chaptersCount
        
        var currentIndex = 0
        
        for chapterNum in 1...chaptersCount {
            // Calculate global chapter number for curriculum lookup
            let globalChapterNum: Int
            switch level {
            case 1: globalChapterNum = chapterNum  // 1-14
            case 2: globalChapterNum = 14 + chapterNum  // 15-27
            case 3: globalChapterNum = 28 + chapterNum  // 29-41
            case 4: globalChapterNum = 42 + chapterNum  // 43-55
            case 5: globalChapterNum = 56 + chapterNum  // 57-67
            case 6: globalChapterNum = 68 + chapterNum  // 69-79
            default: globalChapterNum = chapterNum
            }
            
            // Distribute remainder words across first chapters
            let chapterSize = wordsPerChapter + (chapterNum <= remainder ? 1 : 0)
            let endIndex = min(currentIndex + chapterSize, items.count)
            
            let chapterWords = Array(sortedItems[currentIndex..<endIndex])
            let chapterId = "hsk\(level)_chapter\(chapterNum)"
            
            vocabularyByChapter[chapterId] = chapterWords
            
            // Get chapter info from ChapterCurriculum which has all chapter titles
            let chapterInfo = ChapterCurriculum.getChapterInfo(chapter: globalChapterNum)
            
            // Create chapter metadata
            let chapter = Chapter(
                id: chapterId,
                hskLevel: level,
                chapterNumber: chapterNum,
                title: chapterInfo.title,
                description: chapterInfo.description,
                wordCount: chapterWords.count,
                isUnlocked: chapterNum == 1, // First chapter always unlocked
                icon: chapterInfo.icon
            )
            
            chapters.append(chapter)
            currentIndex = endIndex
        }
    }
    
    private func isChapterUnlocked(_ chapterNum: Int) -> Bool {
        // Check if previous chapter is 80% complete
        // This will be implemented with UserProgressService
        return true // For now, all chapters are unlocked
    }
    
    private func loadVocabularyFromJSON(level: Int) -> [VocabularyItem]? {
        guard let url = Bundle.main.url(forResource: "\(level).min", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)
            return items
        } catch {
            return nil
        }
    }
    
    func getVocabularyForLevels(_ levels: Set<Int>) -> [VocabularyItem] {
        return levels.flatMap { level in
            vocabularyByLevel[level] ?? []
        }
    }
    
    func getReviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem] {
        return allVocabulary.filter { incorrectWordIds.contains($0.id) }
    }
    
    func getAllVocabulary() -> [VocabularyItem] {
        return allVocabulary
    }
    
    func getVocabularyForLevel(_ level: Int) -> [VocabularyItem] {
        return vocabularyByLevel[level] ?? []
    }
    
    func getVocabularyForChapter(_ chapterId: String) -> [VocabularyItem] {
        return vocabularyByChapter[chapterId] ?? []
    }
    
    func getVocabularyForChapters(_ chapterIds: Set<String>) -> [VocabularyItem] {
        return chapterIds.flatMap { chapterId in
            vocabularyByChapter[chapterId] ?? []
        }
    }
    
    func getChaptersForLevel(_ level: Int) -> [Chapter] {
        return chapters.filter { chapter in
            chapter.hskLevel == level && !ChapterCurriculum.reviewChapters.contains(chapter.chapterNumber)
        }
    }
    
    func getChapter(byId chapterId: String) -> Chapter? {
        return chapters.first { $0.id == chapterId }
    }
    
    private func loadCustomVocabulary() {
        print("Starting to load custom vocabulary files...")
        
        // First attempt: Try to find the CustomData folder in the bundle
        if let customDataPath = Bundle.main.path(forResource: "CustomData", ofType: nil) {
            print("CustomData folder found at: \(customDataPath)")
            loadFilesFromDirectory(at: customDataPath)
        } else {
            print("CustomData folder not found as folder reference, trying individual files...")
            
            // Second attempt: Try to load files individually with subdirectory path
            loadIndividualFiles()
        }
    }
    
    private func loadFilesFromDirectory(at path: String) {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            let jsonFiles = contents.filter { $0.hasSuffix(".json") }.sorted()
            
            print("Found \(jsonFiles.count) JSON files in CustomData: \(jsonFiles)")
            
            for (index, filename) in jsonFiles.enumerated() {
                let filePath = (path as NSString).appendingPathComponent(filename)
                let fileURL = URL(fileURLWithPath: filePath)
                loadCustomFile(at: fileURL, chapterNumber: index + 1)
            }
        } catch {
            print("Error reading CustomData directory: \(error)")
        }
    }
    
    private func loadIndividualFiles() {
        // List all possible files we want to check
        let fileNames = [
            "basic-1-1",
            "basic-1-2", 
            "basic-2-1",
            "basic-2-2"
        ]
        
        var loadedCount = 0
        
        // Try loading each file
        for fileName in fileNames {
            // Try with CustomData/ prefix
            if let url = Bundle.main.url(forResource: "CustomData/\(fileName)", withExtension: "json") {
                print("Found file: CustomData/\(fileName).json")
                loadCustomFile(at: url, chapterNumber: loadedCount + 1)
                loadedCount += 1
            }
            // Try without prefix (if files were added directly)
            else if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
                print("Found file: \(fileName).json")
                loadCustomFile(at: url, chapterNumber: loadedCount + 1)
                loadedCount += 1
            }
        }
        
        // Also try to discover any other custom files by checking bundle contents
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
        
        if loadedCount == 0 {
            print("No custom files found. Please add JSON files to Xcode project.")
            print("To add: Drag the JSON files into Xcode's project navigator")
        } else {
            print("Successfully loaded \(loadedCount) custom vocabulary files")
        }
    }
    
    private func loadCustomFile(at url: URL, chapterNumber: Int) {
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)
            
            if !items.isEmpty {
                let filename = url.deletingPathExtension().lastPathComponent
                let chapterId = "custom_\(filename)"
                
                // Format the filename as a readable chapter title
                let chapterTitle = formatChapterTitle(from: filename)
                
                let customChapter = Chapter(
                    id: chapterId,
                    hskLevel: 7, // Using 7 as custom level
                    chapterNumber: chapterNumber,
                    title: chapterTitle,
                    description: "Practice with \(chapterTitle.lowercased()) vocabulary",
                    wordCount: items.count,
                    isUnlocked: true,
                    icon: getCustomChapterIcon(for: chapterNumber)
                )
                
                chapters.append(customChapter)
                vocabularyByChapter[chapterId] = items
                customVocabulary.append(contentsOf: items)
                
                print("Loaded custom chapter: \(chapterTitle) with \(items.count) words")
            }
        } catch {
            print("Error loading custom vocabulary from \(url.lastPathComponent): \(error)")
        }
    }
    
    private func formatChapterTitle(from filename: String) -> String {
        var title = filename
        
        // Special handling for "basic-X-Y" pattern
        if title.lowercased().hasPrefix("basic-") {
            // Convert "basic-1-1" to "Basic 1-1"
            title = title.replacingOccurrences(of: "basic-", with: "Basic ", options: .caseInsensitive)
            return title
        }
        
        // Remove "custom" prefix if present
        if title.lowercased().hasPrefix("custom") {
            title = String(title.dropFirst(6))
        }
        
        // Replace underscores and hyphens with spaces
        title = title.replacingOccurrences(of: "_", with: " ")
        title = title.replacingOccurrences(of: "-", with: " ")
        
        // Remove leading numbers if present (but not for patterns like "1-1")
        if let firstChar = title.first, firstChar.isNumber {
            // Check if it's a pattern like "1-1" or "2-3"
            let components = title.split(separator: " ")
            if components.count == 1 && components[0].contains(where: { !$0.isNumber && $0 != "-" }) {
                // It's something like "1shopping", remove the number
                if let nonNumberIndex = title.firstIndex(where: { !$0.isNumber }) {
                    title = String(title[nonNumberIndex...])
                }
            }
        }
        
        // Trim whitespace and capitalize
        title = title.trimmingCharacters(in: .whitespaces)
        
        // Capitalize first letter of each word
        return title.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    private func getCustomChapterIcon(for chapterNumber: Int) -> String {
        let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "sparkles", "moon.fill", "sun.max.fill", "cloud.fill"]
        return icons[(chapterNumber - 1) % icons.count]
    }
    
    func getCustomVocabulary() -> [VocabularyItem] {
        return customVocabulary
    }
}