import Foundation

struct PinyinValidator {
    func validateAnswer(input: String, word: VocabularyItem, requireTones: Bool) -> AnswerValidationResult {
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
            let targetWithoutTonesAndSpaces = PinyinConverter.removeTones(targetPinyin)
                .replacingOccurrences(of: " ", with: "")
            
            if inputWithoutSpaces == targetWithoutTonesAndSpaces {
                return true
            }
        }
        
        let inputSyllables = trimmedInput.split(separator: " ").count
        let targetSyllables = max(
            targetPinyin.split(separator: " ").count,
            targetNumeric.split(separator: " ").count
        )
        
        if inputSyllables == targetSyllables {
            if let lastChar = trimmedInput.last {
                if requireTones {
                    return AppConstants.Validation.validPinyinEndingsWithTones.contains(String(lastChar))
                } else {
                    return AppConstants.Validation.validPinyinEndings.contains(String(lastChar))
                }
            }
        }
        
        return false
    }
    
}

enum AnswerValidationResult {
    case correct
    case incorrect
    case partial
    
    var feedbackState: FeedbackState {
        switch self {
        case .correct: return .correct
        case .incorrect: return .incorrect
        case .partial: return .partial
        }
    }
}