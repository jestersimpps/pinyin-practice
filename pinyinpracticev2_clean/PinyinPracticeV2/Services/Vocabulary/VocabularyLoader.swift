import Foundation

protocol VocabularyLoading {
    func loadVocabularyFromJSON(level: Int) -> [VocabularyItem]?
    func loadCustomVocabulary() -> [VocabularyItem]
}

final class VocabularyLoader: VocabularyLoading {
    private let bundle: Bundle
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    func loadVocabularyFromJSON(level: Int) -> [VocabularyItem]? {
        guard let url = bundle.url(forResource: "\(level).min", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)
            return items
        } catch {
            print("Error loading vocabulary for level \(level): \(error)")
            return nil
        }
    }
    
    func loadCustomVocabulary() -> [VocabularyItem] {
        var customItems: [VocabularyItem] = []
        
        if let customDataPath = bundle.path(forResource: "CustomData", ofType: nil) {
            customItems.append(contentsOf: loadFilesFromDirectory(at: customDataPath))
        } else {
            customItems.append(contentsOf: loadIndividualFiles())
        }
        
        return customItems
    }
    
    private func loadFilesFromDirectory(at path: String) -> [VocabularyItem] {
        var items: [VocabularyItem] = []
        
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            let jsonFiles = contents.filter { $0.hasSuffix(".json") }.sorted()
            
            for filename in jsonFiles {
                let filePath = (path as NSString).appendingPathComponent(filename)
                let fileURL = URL(fileURLWithPath: filePath)
                if let loadedItems = loadCustomFile(at: fileURL) {
                    items.append(contentsOf: loadedItems)
                }
            }
        } catch {
            print("Error reading CustomData directory: \(error)")
        }
        
        return items
    }
    
    private func loadIndividualFiles() -> [VocabularyItem] {
        var items: [VocabularyItem] = []
        let fileNames = ["basic-1-1", "basic-1-2", "basic-2-1", "basic-2-2"]
        
        for fileName in fileNames {
            if let url = bundle.url(forResource: "CustomData/\(fileName)", withExtension: "json") {
                if let loadedItems = loadCustomFile(at: url) {
                    items.append(contentsOf: loadedItems)
                }
            } else if let url = bundle.url(forResource: fileName, withExtension: "json") {
                if let loadedItems = loadCustomFile(at: url) {
                    items.append(contentsOf: loadedItems)
                }
            }
        }
        
        return items
    }
    
    private func loadCustomFile(at url: URL) -> [VocabularyItem]? {
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)
            return items
        } catch {
            print("Error loading custom vocabulary from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
}