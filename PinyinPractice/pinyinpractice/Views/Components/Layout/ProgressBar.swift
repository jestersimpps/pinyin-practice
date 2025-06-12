import SwiftUI

struct ProgressBar: View {
    let progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let animated: Bool
    
    init(
        progress: Double,
        height: CGFloat = 4,
        backgroundColor: Color = Color.gray.opacity(0.3),
        foregroundColor: Color = .orange,
        animated: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)
                
                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * progress, height: height)
                    .animation(
                        animated ? .spring(response: 0.5, dampingFraction: 0.8) : nil,
                        value: progress
                    )
            }
        }
        .frame(height: height)
    }
}