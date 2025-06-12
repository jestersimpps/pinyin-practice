import SwiftUI

struct PinyinInputField: View {
    @Binding var text: String
    let placeholder: String
    let feedbackState: FeedbackState
    @FocusState var isFocused: Bool
    let onSubmit: () -> Void
    let onClear: () -> Void
    
    enum FeedbackState {
        case none, correct, incorrect, partial
    }
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color("PrimaryText"))
                .multilineTextAlignment(.center)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        scale = 1.05
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = 1.0
                        }
                    }
                }
                .onSubmit(onSubmit)
            
            if !text.isEmpty && feedbackState == .none {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("SecondaryText"))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 2)
                )
        )
        .scaleEffect(scale)
    }
    
    private var borderColor: Color {
        switch feedbackState {
        case .correct: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .incorrect: return .red
        case .partial: return .yellow
        case .none: return text.isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.1, green: 0.3, blue: 0.4)
        }
    }
}