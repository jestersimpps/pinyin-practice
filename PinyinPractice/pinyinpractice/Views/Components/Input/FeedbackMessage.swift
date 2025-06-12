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
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textColor)
                
                if feedbackState == .incorrect,
                   let correctAnswer = correctAnswer {
                    Text("Correct: \(correctAnswer)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("PrimaryText"))
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
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .incorrect: return .red
        case .partial: return .yellow
        case .none: return .clear
        }
    }
    
    private var backgroundColor: Color {
        switch feedbackState {
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1)
        case .incorrect: return Color.red.opacity(0.1)
        case .partial: return Color.yellow.opacity(0.1)
        case .none: return .clear
        }
    }
}