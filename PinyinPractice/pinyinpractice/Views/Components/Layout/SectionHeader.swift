import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("SecondaryText"))
                .textCase(.uppercase)
        }
    }
}