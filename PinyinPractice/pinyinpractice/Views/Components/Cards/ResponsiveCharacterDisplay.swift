import SwiftUI

struct ResponsiveCharacterDisplay: View {
    let character: String
    let translation: String?
    let showTranslation: Bool
    let feedbackState: FeedbackState
    let hint: String?
    let showHint: Bool
    let isCompact: Bool
    
    enum FeedbackState {
        case none, correct, incorrect, partial
    }
    
    @State private var showFeedbackAnimation = false
    
    var body: some View {
        VStack(spacing: isCompact ? 12 : 20) {
            ZStack {
                Text(character)
                    .font(.system(
                        size: isCompact ? 80 : 120,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(Color("PrimaryText"))
                    .scaleEffect(showFeedbackAnimation ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showFeedbackAnimation)
                
                if feedbackState == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isCompact ? 50 : 60))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(minHeight: isCompact ? 80 : 120)
            
            if showTranslation, let translation = translation, !isCompact {
                Text(translation)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .transition(.opacity)
                    .padding(.horizontal, 20)
            }
            
            if showHint, let hint = hint {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text(hint)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, isCompact ? 16 : 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                .fill(Color("SecondaryBackground").opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                        .stroke(borderColor.opacity(0.5), lineWidth: 2)
                )
        )
        .onChange(of: feedbackState) { newState in
            if newState == .correct {
                showFeedbackAnimation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFeedbackAnimation = false
                }
            }
        }
    }
    
    private var borderColor: Color {
        switch feedbackState {
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .incorrect: return .red
        case .partial: return .yellow
        case .none: return Color.gray.opacity(0.3)
        }
    }
}