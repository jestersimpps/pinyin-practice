import SwiftUI

struct CompactStatsBar: View {
    let progress: String
    let accuracy: String
    let streak: Int
    
    var body: some View {
        HStack(spacing: 0) {
            CompactStatItem(
                icon: "checkmark.circle.fill",
                value: progress,
                color: Color(red: 0.1, green: 0.3, blue: 0.4)
            )
            
            Divider()
                .frame(height: 20)
                .background(Color("SecondaryText").opacity(0.3))
            
            CompactStatItem(
                icon: "target",
                value: accuracy,
                color: accuracy == "0%" ? Color("SecondaryText") : Color(red: 0.2, green: 0.8, blue: 0.4)
            )
            
            Divider()
                .frame(height: 20)
                .background(Color("SecondaryText").opacity(0.3))
            
            CompactStatItem(
                icon: "flame.fill",
                value: streak == 0 ? "0" : "\(streak)",
                color: streak == 0 ? Color("SecondaryText") : .orange,
                showFlame: streak > 0
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("SecondaryBackground").opacity(0.5))
        )
    }
}

private struct CompactStatItem: View {
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("PrimaryText"))
            
            if showFlame {
                Text("🔥")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
    }
}