import SwiftUI

struct AdaptiveCharacterDisplay: View {
    let word: VocabularyItem
    let feedbackState: FeedbackState
    let showHint: Bool
    let isKeyboardVisible: Bool
    let onHintToggle: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedTranslation = false
    @State private var expandedCharacterHint = false
    @State private var expandedPronunciationHint = false
    
    enum FeedbackState {
        case none, correct, incorrect, partial
    }
    
    var body: some View {
        Group {
            if isKeyboardVisible {
                compactLayout
            } else {
                fullLayout
            }
        }
        .onChange(of: word.id) { _, _ in
            // Reset expanded states when word changes
            expandedTranslation = false
            expandedCharacterHint = false
            expandedPronunciationHint = false
        }
    }
    
    // MARK: - Compact Layout (Keyboard Visible)
    private var compactLayout: some View {
        VStack(spacing: 8) {
            // Character with inline feedback
            ZStack {
                Text(displayCharacter)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryText"))
                    .frame(maxWidth: .infinity)
                
                if feedbackState != .none {
                    HStack {
                        Spacer()
                        feedbackIcon
                            .font(.system(size: 24))
                            .foregroundColor(feedbackColor)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.trailing, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: feedbackState != .none ? 2 : 0)
            )
            
            // Feedback message with correct answer for incorrect state
            if feedbackState == .incorrect {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                    
                    Text("Correct answer: \(word.pinyin)")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                )
                .padding(.horizontal, 4)
                .transition(.opacity)
            }
            
            // Show translation based on settings or on error
            if settings.showEnglishTranslation || feedbackState == .incorrect {
                Button(action: { expandedTranslation.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.book.closed")
                            .font(.caption)
                        
                        Text(word.english)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(expandedTranslation ? nil : 2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 4)
                .transition(.opacity)
            }
            
            // Compact hints (horizontal pills)
            if showHint || feedbackState == .incorrect {
                compactHints
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: feedbackState)
        .animation(.easeInOut(duration: 0.2), value: showHint)
    }
    
    // MARK: - Full Layout (Keyboard Hidden)
    private var fullLayout: some View {
        VStack(spacing: 16) {
            // Large character
            ZStack {
                Text(displayCharacter)
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(Color("PrimaryText"))
                    .scaleEffect(feedbackState == .correct ? 1.1 : 1.0)
                
                if feedbackState == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("SecondaryBackground").opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
            
            // Show correct answer when incorrect
            if feedbackState == .incorrect {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.body)
                    
                    Text("Correct answer: \(word.pinyin)")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                )
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Translation
            if settings.showEnglishTranslation || feedbackState == .incorrect {
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedTranslation.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.book.closed")
                            .font(.body)
                        
                        Text(word.english)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(expandedTranslation ? nil : 3)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: expandedTranslation)
                    }
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Full hints
            if showHint || feedbackState == .incorrect {
                fullHints
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Additional info
            if settings.showAdditionalInfo && feedbackState != .none {
                additionalInfo
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: feedbackState)
        .animation(.easeInOut(duration: 0.2), value: showHint)
    }
    
    // MARK: - Compact Hints
    private var compactHints: some View {
        VStack(spacing: 6) {
            if settings.showCharacterHints,
               let hint = getCleanHint(word.characterHint) {
                HintPill(
                    icon: "character.book.closed.fill",
                    text: hint,
                    color: .purple,
                    isExpanded: $expandedCharacterHint
                )
            }
            
            if settings.showPronunciationHints,
               let hint = getCleanHint(word.pronunciationHint) {
                HintPill(
                    icon: "lightbulb.fill",
                    text: hint,
                    color: .orange,
                    isExpanded: $expandedPronunciationHint
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Full Hints
    private var fullHints: some View {
        VStack(spacing: 12) {
            if settings.showCharacterHints,
               let hint = getCleanHint(word.characterHint) {
                HintCard(
                    icon: "character.book.closed.fill",
                    text: hint,
                    color: .purple
                )
            }
            
            if settings.showPronunciationHints,
               let hint = getCleanHint(word.pronunciationHint) {
                HintCard(
                    icon: "lightbulb.fill",
                    text: hint,
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Additional Info
    private var additionalInfo: some View {
        HStack(spacing: 20) {
            if settings.useTraditional && word.simplified != word.traditional {
                InfoItem(label: "Simplified", value: word.simplified)
            } else if !settings.useTraditional && word.traditional != word.simplified {
                InfoItem(label: "Traditional", value: word.traditional)
            }
            
            InfoItem(label: "Radical", value: word.radical)
            
            if !word.partOfSpeech.isEmpty {
                InfoItem(
                    label: "Type",
                    value: word.partOfSpeech.prefix(2).map(mapPartOfSpeech).joined(separator: ", ")
                )
            }
            
            InfoItem(label: "Freq", value: "#\(word.frequency)")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("SecondaryBackground").opacity(0.5))
        )
    }
    
    // MARK: - Helper Views
    private var feedbackIcon: some View {
        Image(systemName: feedbackIconName)
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
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .incorrect: return .red
        case .partial: return .orange
        case .none: return .clear
        }
    }
    
    private var borderColor: Color {
        feedbackState == .none ? .clear : feedbackColor.opacity(0.5)
    }
    
    private var feedbackText: String {
        switch feedbackState {
        case .correct: return "Correct!"
        case .incorrect: return "Try again"
        case .partial: return "Check tones"
        case .none: return ""
        }
    }
    
    // MARK: - Helper Methods
    private func getCleanHint(_ hint: String) -> String? {
        guard !hint.isEmpty,
              !hint.starts(with: "Character hint for"),
              !hint.starts(with: "Pronunciation hint for") else {
            return nil
        }
        return hint
    }
    
    private func mapPartOfSpeech(_ pos: String) -> String {
        // Using simplified mapping for space
        let mapping: [String: String] = [
            "n": "noun",
            "v": "verb",
            "a": "adj",
            "d": "adv",
            "p": "prep"
        ]
        return mapping[pos] ?? pos
    }
}

// MARK: - Supporting Views

struct HintPill: View {
    let icon: String
    let text: String
    let color: Color
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: { 
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(isExpanded ? nil : 1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: isExpanded)
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HintCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color("SecondaryText"))
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("PrimaryText"))
        }
    }
}