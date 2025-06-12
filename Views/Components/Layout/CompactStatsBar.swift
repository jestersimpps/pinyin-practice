import SwiftUI

struct CompactStatsBar: View {
    let progress: String
    let accuracy: String
    let streak: Int
    
    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                icon: "checkmark.circle.fill",
                value: progress,
                color: .midnightGreen
            )
            
            Divider()
                .frame(height: 20)
                .background(Color.secondaryText.opacity(0.3))
            
            StatItem(
                icon: "target",
                value: accuracy,
                color: accuracy == "0%" ? .secondaryText : .successGreen
            )
            
            Divider()
                .frame(height: 20)
                .background(Color.secondaryText.opacity(0.3))
            
            StatItem(
                icon: "flame.fill",
                value: streak == 0 ? "0" : "\(streak)",
                color: streak == 0 ? .secondaryText : .vibrantOrange,
                showFlame: streak > 0
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondaryBackground.opacity(0.5))
        )
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    var showFlame: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(Typography.bodyFont)
                .fontWeight(.medium)
                .foregroundColor(.primaryText)
            
            if showFlame {
                Text("🔥")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
    }
}