import SwiftUI

struct FeedbackMessage: View {
    let feedbackState: FeedbackState
    let correctAnswer: String?
    let requireTones: Bool
    
    enum FeedbackState {
        case none, correct, incorrect, partial
    }
    
    var body: some View {
        if feedbackState != .none {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(textColor)
                
                Text(message)
                    .font(Typography.bodyFont)
                    .foregroundColor(textColor)
                
                if feedbackState == .incorrect,
                   let correctAnswer = correctAnswer {
                    Text("Correct: \(correctAnswer)")
                        .font(Typography.bodyFont)
                        .foregroundColor(.primaryText)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    private var icon: String {
        switch feedbackState {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        case .partial: return "exclamationmark.circle.fill"
        case .none: return ""
        }
    }
    
    private var message: String {
        switch feedbackState {
        case .correct: 
            return requireTones ? "Correct! Great job!" : "Correct!"
        case .incorrect: 
            return "Not quite."
        case .partial: 
            return "Close! Check the tones."
        case .none: 
            return ""
        }
    }
    
    private var textColor: Color {
        switch feedbackState {
        case .correct: return .successGreen
        case .incorrect: return .errorRed
        case .partial: return .warningYellow
        case .none: return .clear
        }
    }
    
    private var backgroundColor: Color {
        switch feedbackState {
        case .correct: return Color.successGreen.opacity(0.1)
        case .incorrect: return Color.errorRed.opacity(0.1)
        case .partial: return Color.warningYellow.opacity(0.1)
        case .none: return .clear
        }
    }
}