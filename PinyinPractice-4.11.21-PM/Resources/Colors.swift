import SwiftUI

extension Color {
    // Primary Colors
    static let midnightGreen = Color(red: 0, green: 73/255, blue: 83/255)  // #004953
    static let vibrantOrange = Color(red: 255/255, green: 107/255, blue: 53/255)  // #FF6B35
    
    // Background Colors
    static let gunmetal = Color(red: 44/255, green: 51/255, blue: 56/255)  // #2C3338
    static let ivoryGream = Color(red: 248/255, green: 245/255, blue: 236/255)  // #F8F5EC
    static let lightSilver = Color(red: 216/255, green: 216/255, blue: 216/255)  // #D8D8D8
    
    // Semantic Colors
    static let successGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let errorRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    static let warningYellow = Color(red: 255/255, green: 204/255, blue: 0/255)
    
    // Adaptive Colors with light/dark mode support
    static let primaryBackground = Color(light: Color(red: 248/255, green: 245/255, blue: 236/255),
                                        dark: Color(red: 44/255, green: 51/255, blue: 56/255))
    
    static let secondaryBackground = Color(light: Color(red: 216/255, green: 216/255, blue: 216/255),
                                          dark: Color(red: 39/255, green: 46/255, blue: 51/255))
    
    static let primaryText = Color(light: Color(red: 44/255, green: 51/255, blue: 56/255),
                                  dark: Color(red: 248/255, green: 245/255, blue: 236/255))
    
    static let secondaryText = Color(light: Color(red: 102/255, green: 102/255, blue: 102/255),
                                    dark: Color(red: 179/255, green: 179/255, blue: 179/255))
}

// Helper extension for adaptive colors
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// Glass effect modifier
struct GlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassEffect() -> some View {
        self.modifier(GlassEffect())
    }
}

// Neumorphic effect modifier
struct NeumorphicEffect: ViewModifier {
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ivoryGream)
                    .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.2), 
                           radius: isPressed ? 5 : 10, 
                           x: isPressed ? 2 : 5, 
                           y: isPressed ? 2 : 5)
                    .shadow(color: Color.white.opacity(isPressed ? 0.5 : 0.7), 
                           radius: isPressed ? 5 : 10, 
                           x: isPressed ? -2 : -5, 
                           y: isPressed ? -2 : -5)
            )
    }
}

extension View {
    func neumorphicEffect(isPressed: Bool = false) -> some View {
        self.modifier(NeumorphicEffect(isPressed: isPressed))
    }
}