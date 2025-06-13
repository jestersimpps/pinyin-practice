import SwiftUI

struct MobileInputZone: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let feedbackState: FeedbackState
    let onSubmit: () -> Void
    let onSkip: () -> Void
    let onHintToggle: () -> Void
    let showHintButton: Bool
    let showSkipButton: Bool
    
    enum FeedbackState {
        case none, correct, incorrect, partial
        
        var showNextButton: Bool {
            self != .none
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Input field
            inputField
            
            // Action buttons
            if feedbackState.showNextButton {
                nextButton
            } else {
                HStack(spacing: 8) {
                    if showHintButton {
                        hintButton
                    }
                    if showSkipButton {
                        skipButton
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground").opacity(0.5))
                .shadow(color: .black.opacity(0.05), radius: 2, y: -1)
        )
    }
    
    private var inputField: some View {
        HStack {
            TextField("Enter pinyin...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color("PrimaryText"))
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused(isFocused)
                .submitLabel(.go)
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("SecondaryText").opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
        )
    }
    
    private var hintButton: some View {
        Button(action: onHintToggle) {
            Image(systemName: "lightbulb")
                .font(.system(size: 20))
                .foregroundColor(Color("SecondaryText"))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color("SecondaryBackground"))
                )
        }
    }
    
    private var skipButton: some View {
        Button(action: onSkip) {
            Label("Skip", systemImage: "forward.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("SecondaryText"))
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("SecondaryBackground"))
                )
        }
    }
    
    private var nextButton: some View {
        Button(action: onSubmit) {
            HStack(spacing: 4) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(nextButtonColor)
            )
        }
    }
    
    private var backgroundColor: Color {
        Color("PrimaryBackground")
    }
    
    private var borderColor: Color {
        switch feedbackState {
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .incorrect: return .red
        case .partial: return .orange
        case .none: return Color("SecondaryBackground")
        }
    }
    
    private var nextButtonColor: Color {
        switch feedbackState {
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .incorrect, .partial: return Color(red: 0.1, green: 0.3, blue: 0.4)
        case .none: return Color(red: 0.1, green: 0.3, blue: 0.4)
        }
    }
}