import SwiftUI

struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color("MidnightGreen") : Color("SecondaryBackground").opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color("MidnightGreen") : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}