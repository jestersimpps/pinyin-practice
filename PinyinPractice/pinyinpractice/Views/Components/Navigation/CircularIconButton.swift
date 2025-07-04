import SwiftUI

struct CircularIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44
    var fontSize: Font = .title2
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(fontSize)
                .foregroundColor(Color("PrimaryText"))
                .frame(width: size, height: size)
                .background(Color("SecondaryBackground").opacity(0.5))
                .clipShape(Circle())
        }
    }
}