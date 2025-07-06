import SwiftUI

struct PracticeHeader: View {
    let title: String
    let subtitle: String?
    let progress: Double
    let wordsCompleted: Int
    let totalWords: Int
    let accuracy: String
    let streak: Int
    let onBack: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            navigationRow
            ProgressBar(progress: progress)
            statsRow
        }
    }
    
    private var navigationRow: some View {
        HStack {
            IconButton(
                systemName: "chevron.left",
                action: onBack
            )
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color("PrimaryText"))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            
            Spacer()
            
            IconButton(
                systemName: "gearshape.fill",
                action: onSettings
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var statsRow: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "flag.fill",
                value: "\(wordsCompleted)/\(totalWords)",
                color: .blue
            )
            
            StatItem(
                icon: "target",
                value: accuracy,
                color: accuracy == "0%" ? Color("SecondaryText") : Color(red: 0.2, green: 0.8, blue: 0.4)
            )
            
            StatItem(
                icon: "flame.fill",
                value: "\(streak)",
                color: streak == 0 ? Color("SecondaryText") : .orange
            )
        }
        .foregroundColor(Color("PrimaryText"))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color("SecondaryBackground").opacity(0.3))
    }
}

private struct IconButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color("PrimaryText"))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color("SecondaryBackground").opacity(0.5))
                )
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}