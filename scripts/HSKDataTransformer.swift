
import Foundation

struct HSKTranscriptions: Codable {
    let pinyin: String
    let numeric: String
    let wadeGiles: String?
    let bopomofo: String?
    let romatzyh: String?
    
    enum CodingKeys: String, CodingKey {
        case pinyin
        case numeric
        case wadeGiles = "wade-giles"
        case bopomofo
        case romatzyh
    }
}

struct HSKForm: Codable {
    let traditional: String
    let transcriptions: HSKTranscriptions
    let meanings: [String]
    let classifiers: [String]?
}

struct HSKVocabularyItem: Codable {
    let simplified: String
    let radical: String
    let frequency: Int
    let pos: [String]
    let forms: [HSKForm]
}

typealias HSKVocabularyList = [HSKVocabularyItem]

class HSKDataTransformer {
    static func fetchHSKData(level: Int) async throws -> HSKVocabularyList {
        let urlString = "https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/refs/heads/main/wordlists/exclusive/old/\(level).json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(HSKVocabularyList.self, from: data)
    }
    
    static func generateSwiftCode(from items: HSKVocabularyList, level: Int) -> String {
        var code = """
        import Foundation
        
        extension VocabularyService {
            static let hsk\(level)Vocabulary: [VocabularyItem] = [
        """
        
        var sortedItems = items
        sortedItems.sort { $0.frequency < $1.frequency }
        
        for (index, item) in sortedItems.enumerated() {
            let id = "hsk\(level)_\(index + 1)"
            
            let formsCode = generateFormsCode(item.forms)
            
            code += """
            
                VocabularyItem(
                    id: "\(id)",
                    simplified: "\(item.simplified)",
                    radical: "\(item.radical)",
                    frequency: \(item.frequency),
                    pos: \(formatArray(item.pos)),
                    forms: \(formsCode)
                )\(index < sortedItems.count - 1 ? "," : "")
            """
        }
        
        code += """
        
            ]
        }
        """
        
        return code
    }
    
    static func generateTranscriptionsCode(_ transcriptions: HSKTranscriptions?) -> String {
        guard let transcriptions = transcriptions else {
            return "Transcriptions(pinyin: \"\", numeric: \"\", wadeGiles: nil, bopomofo: nil, romatzyh: nil)"
        }
        
        return """
        Transcriptions(
                            pinyin: "\(transcriptions.pinyin)",
                            numeric: "\(transcriptions.numeric)",
                            wadeGiles: \(formatOptionalString(transcriptions.wadeGiles)),
                            bopomofo: \(formatOptionalString(transcriptions.bopomofo)),
                            romatzyh: \(formatOptionalString(transcriptions.romatzyh))
                        )
        """
    }
    
    static func generateFormsCode(_ forms: [HSKForm]) -> String {
        guard !forms.isEmpty else { return "[]" }
        
        var formsCode = "["
        for (index, form) in forms.enumerated() {
            formsCode += """
            
                    VocabularyForm(
                        traditional: "\(form.traditional)",
                        transcriptions: \(generateTranscriptionsCode(form.transcriptions)),
                        meanings: \(formatArray(form.meanings)),
                        classifiers: \(formatOptionalArray(form.classifiers))
                    )\(index < forms.count - 1 ? "," : "")
            """
        }
        formsCode += "\n                ]"
        
        return formsCode
    }
    
    static func formatArray(_ array: [String]) -> String {
        if array.isEmpty { return "[]" }
        let escapedArray = array.map { "\"\($0.replacingOccurrences(of: "\"", with: "\\\""))\"" }
        return "[\(escapedArray.joined(separator: ", "))]"
    }
    
    static func formatOptionalArray(_ array: [String]?) -> String {
        guard let array = array else { return "nil" }
        return formatArray(array)
    }
    
    static func formatOptionalString(_ string: String?) -> String {
        guard let string = string else { return "nil" }
        return "\"\(string.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}

struct HSKTransformerCLI {
    static func main() async {
        let levels = [1, 2, 3, 4, 5, 6]
        
        for level in levels {
            print("Processing HSK \(level)...")
            
            do {
                let hskData = try await HSKDataTransformer.fetchHSKData(level: level)
                let swiftCode = HSKDataTransformer.generateSwiftCode(from: hskData, level: level)
                
                let outputPath = "pinyinpractice/pinyinpractice/Data/Vocabulary/HSK\(level)Vocabulary.swift"
                try swiftCode.write(toFile: outputPath, atomically: true, encoding: .utf8)
                
                print("✓ Generated \(outputPath) with \(hskData.count) items")
            } catch {
                print("✗ Error processing HSK \(level): \(error)")
            }
        }
        
        print("\nGenerating combined vocabulary file...")
        generateCombinedFile()
    }
    
    static func generateCombinedFile() {
        var combinedCode = """
        import Foundation
        
        extension VocabularyService {
            static var allHSKVocabulary: [HSKLevel: [VocabularyItem]] {
                [
        """
        
        for level in 1...6 {
            combinedCode += """
            
                    .hsk\(level): hsk\(level)Vocabulary\(level < 6 ? "," : "")
            """
        }
        
        combinedCode += """
        
                ]
            }
        }
        """
        
        do {
            try combinedCode.write(toFile: "pinyinpractice/pinyinpractice/Data/Vocabulary/HSKVocabularyIndex.swift", atomically: true, encoding: .utf8)
            print("✓ Generated HSKVocabularyIndex.swift")
        } catch {
            print("✗ Error generating index file: \(error)")
        }
    }
}

Task {
    await HSKTransformerCLI.main()
    exit(0)
}

RunLoop.main.run()