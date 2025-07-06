import Foundation

enum VocabularyLoadingError: Error {
    case fileNotFound(fileName: String)
    case decodingError(fileName: String, underlyingError: Error)
    case invalidData(fileName: String)
}

class VocabularyFileLoader {
    func loadVocabularyFromJSON(level: Int) -> Result<[VocabularyItem], VocabularyLoadingError> {
        let fileName = FileNameFormatter.vocabularyFileName(for: level)
        let fileNameWithoutExtension = fileName.replacingOccurrences(of: ".json", with: "")
        
        guard let url = Bundle.main.url(forResource: fileNameWithoutExtension, withExtension: "json") else {
            return .failure(.fileNotFound(fileName: fileName))
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([VocabularyItem].self, from: data)
            return .success(items)
        } catch {
            return .failure(.decodingError(fileName: fileName, underlyingError: error))
        }
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