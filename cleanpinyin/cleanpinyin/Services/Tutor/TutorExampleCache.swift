import Foundation

// Stores generated example sentences per word so they show instantly next time
final class TutorExampleCache {
    static let shared = TutorExampleCache()

    private let fileURL: URL
    private var entries: [String: [ExampleSentence]]

    init(fileURL: URL = TutorExampleCache.defaultURL) {
        self.fileURL = fileURL
        entries = (try? JSONDecoder().decode([String: [ExampleSentence]].self, from: Data(contentsOf: fileURL))) ?? [:]
    }

    func sentences(for wordId: String) -> [ExampleSentence]? {
        entries[wordId]
    }

    func store(_ sentences: [ExampleSentence], for wordId: String) {
        entries[wordId] = sentences
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    func removeAll() {
        entries.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("tutor-examples.json")
    }
}
