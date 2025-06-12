import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isDisabled: Bool = false,
        isLoading: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isDisabled = isDisabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDisabled ? Color.gray : Color(red: 0.1, green: 0.3, blue: 0.4))
                    .shadow(
                        color: isDisabled ? Color.clear : Color(red: 0.1, green: 0.3, blue: 0.4).opacity(0.3),
                        radius: 10, x: 0, y: 5
                    )
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isDisabled ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDisabled)
    }
}