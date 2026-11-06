import SwiftUI

struct MobileInputZone: View {
    enum MicState: Equatable {
        case idle
        case preparing
        case listening
    }

    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let feedbackState: FeedbackState
    let showHintButton: Bool
    var micState: MicState? = nil
    var onMicTap: () -> Void = {}
    let onCheck: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onHintToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            inputField

            if feedbackState == .none {
                if let micState {
                    micButton(micState)
                }
                if showHintButton {
                    hintButton
                }
                if text.isEmpty {
                    actionButton(title: "Skip", icon: "forward.fill", style: .secondary, action: onSkip)
                        .accessibilityHint("Shows the answer and counts as a miss")
                } else {
                    actionButton(title: "Check", icon: "checkmark", style: .primary, action: onCheck)
                }
            } else {
                actionButton(title: "Next", icon: "arrow.right", style: feedbackState == .correct ? .success : .primary, action: onNext)
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
            TextField(micState == .listening ? "Listening… say the word" : "Type the pinyin", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color("PrimaryText"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused(isFocused)
                .submitLabel(feedbackState == .none ? .done : .next)
                .onSubmit(feedbackState == .none ? onCheck : onNext)
                .accessibilityLabel("Pinyin answer")

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("SecondaryText").opacity(0.6))
                }
                .accessibilityLabel("Clear answer")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("PrimaryBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
        )
    }

    private func micButton(_ state: MicState) -> some View {
        Button(action: onMicTap) {
            ZStack {
                Circle()
                    .fill(state == .listening ? Color.red : Color("SecondaryBackground"))
                if state == .preparing {
                    ProgressView()
                } else {
                    Image(systemName: state == .listening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(state == .listening ? .white : Color("MidnightGreen"))
                }
            }
            .frame(width: 44, height: 44)
            .scaleEffect(state == .listening ? 1.08 : 1)
            .animation(state == .listening ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: state)
        }
        .disabled(state == .preparing)
        .accessibilityLabel(state == .listening ? "Stop listening" : "Say the answer")
    }

    private var hintButton: some View {
        Button(action: onHintToggle) {
            Image(systemName: "lightbulb")
                .font(.system(size: 20))
                .foregroundColor(Color("SecondaryText"))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color("SecondaryBackground")))
        }
        .accessibilityLabel("Show hints")
    }

    private enum ButtonStyleKind {
        case primary, secondary, success
    }

    private func actionButton(title: String, icon: String, style: ButtonStyleKind, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(style == .secondary ? Color("SecondaryText") : .white)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(background(for: style))
            )
        }
    }

    private func background(for style: ButtonStyleKind) -> Color {
        switch style {
        case .primary: return Color("MidnightGreen")
        case .secondary: return Color("SecondaryBackground")
        case .success: return Color("SuccessGreen")
        }
    }

    private var borderColor: Color {
        switch feedbackState {
        case .correct: return Color("SuccessGreen")
        case .incorrect: return .red
        case .partial: return .orange
        case .none: return Color("SecondaryBackground")
        }
    }
}
