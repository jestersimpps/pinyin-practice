import SwiftUI

struct Typography {
    // Chinese character display
    static let chineseCharacterFont = Font.system(size: 120, weight: .bold, design: .rounded)
    
    // Pinyin display
    static let pinyinDisplayFont = Font.system(size: 32, weight: .medium, design: .monospaced)
    static let pinyinInputFont = Font.system(size: 24, weight: .regular, design: .monospaced)
    
    // UI Text
    static let largeTitleFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    static let smallCaptionFont = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // Button text
    static let primaryButtonFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let secondaryButtonFont = Font.system(size: 16, weight: .medium, design: .rounded)
}

// Text style modifiers using ViewModifier
struct ChineseCharacterStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.chineseCharacterFont)
            .foregroundColor(Color.primaryText)
    }
}

struct PinyinDisplayStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.pinyinDisplayFont)
            .foregroundColor(Color.secondaryText)
    }
}

struct LargeTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.largeTitleFont)
            .foregroundColor(Color.primaryText)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.headlineFont)
            .foregroundColor(Color.primaryText)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.bodyFont)
            .foregroundColor(Color.primaryText)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.captionFont)
            .foregroundColor(Color.secondaryText)
    }
}

// Extension to apply modifiers
extension View {
    func chineseCharacterStyle() -> some View {
        self.modifier(ChineseCharacterStyle())
    }
    
    func pinyinDisplayStyle() -> some View {
        self.modifier(PinyinDisplayStyle())
    }
    
    func largeTitleStyle() -> some View {
        self.modifier(LargeTitleStyle())
    }
    
    func headlineStyle() -> some View {
        self.modifier(HeadlineStyle())
    }
    
    func bodyStyle() -> some View {
        self.modifier(BodyStyle())
    }
    
    func captionStyle() -> some View {
        self.modifier(CaptionStyle())
    }
}