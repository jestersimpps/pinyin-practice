import SwiftUI

struct StatBubble: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        InfoCard(title: title, value: value, icon: icon, color: color)
    }
}