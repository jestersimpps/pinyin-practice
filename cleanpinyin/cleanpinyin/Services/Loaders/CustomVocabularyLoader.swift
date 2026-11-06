import Foundation

class CustomVocabularyLoader {
    typealias CustomVocabulary = (chapters: [Chapter], vocabularyByChapter: [String: [VocabularyItem]], allItems: [VocabularyItem])

    private static let customChapterIcons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "sparkles", "moon.fill", "sun.max.fill", "cloud.fill"]

    private let fileLoader = VocabularyFileLoader()

    func loadCustomVocabulary() -> CustomVocabulary {
        let fileURLs = customFileURLs()
        var chapters: [Chapter] = []
        var vocabularyByChapter: [String: [VocabularyItem]] = [:]
        var allItems: [VocabularyItem] = []

        for url in fileURLs {
            guard let result = processCustomFile(at: url, chapterNumber: chapters.count + 1) else { continue }
            chapters.append(result.chapter)
            vocabularyByChapter[result.chapter.id] = result.items
            allItems.append(contentsOf: result.items)
        }

        return (chapters, vocabularyByChapter, allItems)
    }

    private func customFileURLs() -> [URL] {
        if let customDataPath = Bundle.main.path(forResource: "CustomData", ofType: nil),
           let contents = try? FileManager.default.contentsOfDirectory(atPath: customDataPath) {
            return contents
                .filter { $0.hasSuffix(".json") }
                .sorted()
                .map { URL(fileURLWithPath: (customDataPath as NSString).appendingPathComponent($0)) }
        }

        // Fallback when CustomData is bundled as individual files instead of a folder reference
        return Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)?
            .filter { $0.lastPathComponent.lowercased().hasPrefix("basic-") || $0.lastPathComponent.lowercased().hasPrefix("custom") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
    }

    private func processCustomFile(at url: URL, chapterNumber: Int) -> (chapter: Chapter, items: [VocabularyItem])? {
        switch fileLoader.loadCustomFile(at: url) {
        case .success(let items):
            let filename = url.deletingPathExtension().lastPathComponent
            let chapterTitle = formatChapterTitle(from: filename)

            let chapter = Chapter(
                id: "custom_\(filename)",
                kind: .custom,
                hskLevel: Chapter.customLevel,
                chapterNumber: chapterNumber,
                title: chapterTitle,
                description: "Practice with \(chapterTitle.lowercased()) vocabulary",
                wordCount: items.count,
                icon: Self.customChapterIcons[(chapterNumber - 1) % Self.customChapterIcons.count]
            )
            return (chapter, items)

        case .failure(let error):
            print("Error loading custom vocabulary from \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private func formatChapterTitle(from filename: String) -> String {
        var title = filename

        if title.lowercased().hasPrefix("custom") {
            title = String(title.dropFirst("custom".count))
        }

        title = title
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)

        return title.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
