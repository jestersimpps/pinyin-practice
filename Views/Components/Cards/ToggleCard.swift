import SwiftUI

struct ToggleCard: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.bodyFont)
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(Typography.smallCaptionFont)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.vibrantOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}