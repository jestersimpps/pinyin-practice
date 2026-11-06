import Foundation

enum VocabularyLoadingError: Error {
    case fileNotFound(fileName: String)
    case decodingError(fileName: String, underlyingError: Error)
    case invalidData(fileName: String)
}

class VocabularyFileLoader {
    func loadWordBank() -> Result<[VocabularyItem], VocabularyLoadingError> {
        let resourceName = "words.min"

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            return .failure(.fileNotFound(fileName: "\(resourceName).json"))
        }

        return loadCustomFile(at: url)
    }

    func loadCustomFile(at url: URL) -> Result<[VocabularyItem], VocabularyLoadingError> {
        let fileName = url.lastPathComponent

        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)

            if items.isEmpty {
                return .failure(.invalidData(fileName: fileName))
            }

            return .success(items)
        } catch {
            return .failure(.decodingError(fileName: fileName, underlyingError: error))
        }
    }
}
