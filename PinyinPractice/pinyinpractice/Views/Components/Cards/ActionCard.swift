import SwiftUI

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    var badge: String? = nil
    var isDisabled: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(isDisabled ? Color("SecondaryText") : color)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(isDisabled ? Color("SecondaryText").opacity(0.1) : color.opacity(0.15))
                        )
                    
                    Spacer()
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isDisabled ? Color("SecondaryText") : color)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isDisabled ? Color("SecondaryText") : Color("PrimaryText"))
                    
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("SecondaryBackground").opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isDisabled ? Color.gray.opacity(0.2) : color.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(
                color: isDisabled ? .clear : color.opacity(0.1),
                radius: isPressed ? 5 : 10,
                x: 0,
                y: isPressed ? 2 : 5
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}