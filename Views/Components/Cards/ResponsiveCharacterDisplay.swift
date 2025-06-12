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
                    .foregroundColor(.primaryText)
                    .scaleEffect(showFeedbackAnimation ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showFeedbackAnimation)
                
                if feedbackState == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isCompact ? 50 : 60))
                        .foregroundColor(.successGreen)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(minHeight: isCompact ? 80 : 120)
            
            if showTranslation, let translation = translation, !isCompact {
                Text(translation)
                    .font(Typography.bodyFont)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .transition(.opacity)
                    .padding(.horizontal, 20)
            }
            
            if showHint, let hint = hint {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.vibrantOrange)
                    
                    Text(hint)
                        .font(Typography.captionFont)
                        .foregroundColor(.vibrantOrange)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.vibrantOrange.opacity(0.1))
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.vertical, isCompact ? 16 : 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                .fill(Color.secondaryBackground.opacity(0.3))
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
        case .correct: return .successGreen
        case .incorrect: return .errorRed
        case .partial: return .warningYellow
        case .none: return Color.lightSilver.opacity(0.3)
        }
    }
}