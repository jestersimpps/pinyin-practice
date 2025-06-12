import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.vibrantOrange)
            
            Text(title)
                .captionStyle()
                .textCase(.uppercase)
        }
    }
}