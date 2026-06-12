import SwiftUI

struct AdaptiveCharacterDisplay: View {
    let word: VocabularyItem
    let feedbackState: FeedbackState
    let showHint: Bool
    let isKeyboardVisible: Bool
    let onHintToggle: () -> Void

    @State private var expandedTranslation = false
    @State private var expandedCharacterHint = false
    @State private var expandedPronunciationHint = false
    @StateObject private var textToSpeech = TextToSpeechService.shared

    var body: some View {
        VStack(spacing: isKeyboardVisible ? 8 : 16) {
            characterSection

            if feedbackState == .incorrect {
                InfoBanner(
                    icon: "checkmark.circle",
                    text: "Correct answer: \(word.pinyin)",
                    color: Color("SuccessGreen"),
                    compact: isKeyboardVisible
                )
                .transition(.opacity)
            }

            if settings.showEnglishTranslation || feedbackState == .incorrect {
                InfoBanner(
                    icon: "text.book.closed",
                    text: word.english,
                    color: Color("SuccessGreen"),
                    compact: isKeyboardVisible,
                    isExpanded: $expandedTranslation
                )
                .transition(.opacity)
            }

            if showHint || feedbackState == .incorrect {
                hints
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: feedbackState)
        .animation(.easeInOut(duration: 0.2), value: showHint)
        .onChange(of: word.id) { _, _ in
            expandedTranslation = false
            expandedCharacterHint = false
            expandedPronunciationHint = false
        }
    }

    // MARK: - Character
    private var characterSection: some View {
        ZStack {
            Text(displayCharacter)
                .font(.system(size: isKeyboardVisible ? 60 : 120, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryText"))
                .frame(maxWidth: .infinity)
                .scaleEffect(!isKeyboardVisible && feedbackState == .correct ? 1.1 : 1.0)

            if feedbackState != .none {
                if isKeyboardVisible {
                    HStack {
                        Spacer()
                        Image(systemName: feedbackIconName)
                            .font(.system(size: 24))
                            .foregroundColor(feedbackColor)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.trailing, 16)
                    }
                } else if feedbackState == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("SuccessGreen"))
                        .transition(.scale.combined(with: .opacity))
                }
            }

            VStack {
                HStack {
                    speakerButton
                        .padding(isKeyboardVisible ? 8 : 12)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(height: isKeyboardVisible ? nil : 140)
        .frame(maxWidth: .infinity)
        .padding(.vertical, isKeyboardVisible ? 8 : 0)
        .padding(.horizontal, isKeyboardVisible ? 16 : 0)
        .background(
            RoundedRectangle(cornerRadius: isKeyboardVisible ? 12 : 20)
                .fill(isKeyboardVisible ? Color.clear : Color("SecondaryBackground").opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: isKeyboardVisible ? 12 : 20)
                        .stroke(borderColor, lineWidth: feedbackState != .none || !isKeyboardVisible ? 2 : 0)
                )
        )
    }

    // MARK: - Hints
    private var hints: some View {
        VStack(spacing: isKeyboardVisible ? 6 : 12) {
            if settings.showCharacterHints,
               let hint = getCleanHint(word.characterHint) {
                InfoBanner(
                    icon: "character.book.closed.fill",
                    text: hint,
                    color: .purple,
                    compact: isKeyboardVisible,
                    isExpanded: $expandedCharacterHint
                )
            }

            if settings.showPronunciationHints,
               let hint = getCleanHint(word.pronunciationHint) {
                InfoBanner(
                    icon: "lightbulb.fill",
                    text: hint,
                    color: .orange,
                    compact: isKeyboardVisible,
                    isExpanded: $expandedPronunciationHint
                )
            }
        }
    }

    private var speakerButton: some View {
        Button(action: {
            textToSpeech.speak(chinese: displayCharacter)
        }) {
            Image(systemName: textToSpeech.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                .font(.system(size: 20))
                .foregroundColor(Color("PrimaryText").opacity(0.7))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color("SecondaryBackground"))
                        .shadow(radius: 2, x: 0, y: 1)
                )
        }
        .scaleEffect(textToSpeech.isSpeaking ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: textToSpeech.isSpeaking)
    }

    // MARK: - Computed Properties
    private var displayCharacter: String {
        settings.useTraditional ? word.traditional : word.simplified
    }

    private var settings: PracticeSettings {
        UserProgressService.shared.settings
    }

    private var feedbackIconName: String {
        switch feedbackState {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        case .partial: return "exclamationmark.circle.fill"
        case .none: return ""
        }
    }

    private var feedbackColor: Color {
        switch feedbackState {
        case .correct: return Color("SuccessGreen")
        case .incorrect: return .red
        case .partial: return .orange
        case .none: return .clear
        }
    }

    private var borderColor: Color {
        feedbackState == .none ? .clear : feedbackColor.opacity(0.5)
    }

    private func getCleanHint(_ hint: String) -> String? {
        guard !hint.isEmpty,
              !hint.starts(with: "Character hint for"),
              !hint.starts(with: "Pronunciation hint for") else {
            return nil
        }
        return hint
    }
}

// MARK: - Supporting Views

struct InfoBanner: View {
    let icon: String
    let text: String
    let color: Color
    var compact: Bool = false
    var isExpanded: Binding<Bool>? = nil

    var body: some View {
        if let isExpanded {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                content(expanded: isExpanded.wrappedValue)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content(expanded: false)
        }
    }

    private func content(expanded: Bool) -> some View {
        HStack(alignment: .top, spacing: compact ? 6 : 8) {
            Image(systemName: icon)
                .font(compact ? .caption : .body)

            Text(text)
                .font(.system(size: compact ? 13 : 16, weight: .medium))
                .lineLimit(isExpandable ? (expanded ? nil : lineLimit) : nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: expanded)
        }
        .foregroundColor(color)
        .padding(.horizontal, compact ? 12 : 16)
        .padding(.vertical, compact ? 6 : 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
    }

    private var isExpandable: Bool {
        isExpanded != nil
    }

    private var lineLimit: Int {
        compact ? 2 : 3
    }
}
