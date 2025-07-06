import Foundation

protocol InputValidating {
    func validateAnswer(_ input: String, for word: VocabularyItem, requireTones: Bool) -> FeedbackState
    func isInputLikelyComplete(_ input: String, for word: VocabularyItem, requireTones: Bool) -> Bool
}

final class InputValidator: InputValidating {
    func validateAnswer(_ input: String, for word: VocabularyItem, requireTones: Bool) -> FeedbackState {
        let isCorrect = word.isPinyinCorrect(input, requireTones: requireTones)
        
        if isCorrect {
            return .correct
        }
        
        let isPartial = requireTones && word.isPinyinPartiallyCorrect(input)
        return isPartial ? .partial : .incorrect
    }
    
    func isInputLikelyComplete(_ input: String, for word: VocabularyItem, requireTones: Bool) -> Bool {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let targetPinyin = word.pinyin.lowercased()
        let targetNumeric = word.toneNumbers.lowercased()
        
        if trimmedInput == targetPinyin || trimmedInput == targetNumeric {
            return true
        }
        
        if !requireTones {
            let inputWithoutSpaces = trimmedInput.replacingOccurrences(of: " ", with: "")
            let targetWithoutTonesAndSpaces = removeTones(from: targetPinyin)
                .replacingOccurrences(of: " ", with: "")
            
            if inputWithoutSpaces == targetWithoutTonesAndSpaces {
                return true
            }
        }
        
        return checkSyllableCompletion(trimmedInput, targetPinyin: targetPinyin, targetNumeric: targetNumeric, requireTones: requireTones)
    }
    
    private func removeTones(from pinyin: String) -> String {
        return pinyin
            .replacingOccurrences(of: "ā", with: "a").replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "ǎ", with: "a").replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ē", with: "e").replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "ě", with: "e").replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ī", with: "i").replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ǐ", with: "i").replacingOccurrences(of: "ì", with: "i")
            .replacingOccurrences(of: "ō", with: "o").replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ǒ", with: "o").replacingOccurrences(of: "ò", with: "o")
            .replacingOccurrences(of: "ū", with: "u").replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ǔ", with: "u").replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "ǖ", with: "ü").replacingOccurrences(of: "ǘ", with: "ü")
            .replacingOccurrences(of: "ǚ", with: "ü").replacingOccurrences(of: "ǜ", with: "ü")
    }
    
    private func checkSyllableCompletion(_ input: String, targetPinyin: String, targetNumeric: String, requireTones: Bool) -> Bool {
        let inputSyllables = input.split(separator: " ").count
        let targetSyllables = max(
            targetPinyin.split(separator: " ").count,
            targetNumeric.split(separator: " ").count
        )
        
        if inputSyllables == targetSyllables {
            if let lastChar = input.last {
                if requireTones {
                    let validEndings = ["1", "2", "3", "4", "a", "e", "i", "o", "u", "n", "g", "r"]
                    return validEndings.contains(String(lastChar))
                } else {
                    let validEndings = ["a", "e", "i", "o", "u", "n", "g", "r"]
                    return validEndings.contains(String(lastChar))
                }
            }
        }
        
        return false
    }
}