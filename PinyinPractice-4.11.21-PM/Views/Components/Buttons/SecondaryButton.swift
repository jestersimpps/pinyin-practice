import SwiftUI

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isActive: Bool
    
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isActive: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isActive = isActive
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                
                Text(title)
                    .font(Typography.secondaryButtonFont)
            }
            .foregroundColor(isActive ? .white : .midnightGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.midnightGreen : Color.lightSilver.opacity(0.3))
            )
        }
    }
}