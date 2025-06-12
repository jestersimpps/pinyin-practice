import SwiftUI

struct NavigationHeader: View {
    let title: String
    let subtitle: String?
    let leftAction: (() -> Void)?
    let leftIcon: String?
    let rightAction: (() -> Void)?
    let rightIcon: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        leftAction: (() -> Void)? = nil,
        leftIcon: String? = "chevron.left",
        rightAction: (() -> Void)? = nil,
        rightIcon: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftAction = leftAction
        self.leftIcon = leftIcon
        self.rightAction = rightAction
        self.rightIcon = rightIcon
    }
    
    var body: some View {
        HStack {
            if let leftAction = leftAction, let leftIcon = leftIcon {
                CircularIconButton(icon: leftIcon, action: leftAction)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("PrimaryText"))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if let rightAction = rightAction, let rightIcon = rightIcon {
                CircularIconButton(icon: rightIcon, action: rightAction)
            } else if leftAction != nil {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}