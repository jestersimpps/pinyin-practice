import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "MidnightGreen" asset catalog color resource.
    static let midnightGreen = DeveloperToolsSupport.ColorResource(name: "MidnightGreen", bundle: resourceBundle)

    /// The "PrimaryBackground" asset catalog color resource.
    static let primaryBackground = DeveloperToolsSupport.ColorResource(name: "PrimaryBackground", bundle: resourceBundle)

    /// The "PrimaryText" asset catalog color resource.
    static let primaryText = DeveloperToolsSupport.ColorResource(name: "PrimaryText", bundle: resourceBundle)

    /// The "SecondaryBackground" asset catalog color resource.
    static let secondaryBackground = DeveloperToolsSupport.ColorResource(name: "SecondaryBackground", bundle: resourceBundle)

    /// The "SecondaryText" asset catalog color resource.
    static let secondaryText = DeveloperToolsSupport.ColorResource(name: "SecondaryText", bundle: resourceBundle)

    /// The "SuccessGreen" asset catalog color resource.
    static let successGreen = DeveloperToolsSupport.ColorResource(name: "SuccessGreen", bundle: resourceBundle)

    /// The "VibrantOrange" asset catalog color resource.
    static let vibrantOrange = DeveloperToolsSupport.ColorResource(name: "VibrantOrange", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "MidnightGreen" asset catalog color.
    static var midnightGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .midnightGreen)
#else
        .init()
#endif
    }

    /// The "PrimaryBackground" asset catalog color.
    static var primaryBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primaryBackground)
#else
        .init()
#endif
    }

    /// The "PrimaryText" asset catalog color.
    static var primaryText: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primaryText)
#else
        .init()
#endif
    }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .secondaryBackground)
#else
        .init()
#endif
    }

    /// The "SecondaryText" asset catalog color.
    static var secondaryText: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .secondaryText)
#else
        .init()
#endif
    }

    /// The "SuccessGreen" asset catalog color.
    static var successGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .successGreen)
#else
        .init()
#endif
    }

    /// The "VibrantOrange" asset catalog color.
    static var vibrantOrange: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .vibrantOrange)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "MidnightGreen" asset catalog color.
    static var midnightGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .midnightGreen)
#else
        .init()
#endif
    }

    /// The "PrimaryBackground" asset catalog color.
    static var primaryBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primaryBackground)
#else
        .init()
#endif
    }

    /// The "PrimaryText" asset catalog color.
    static var primaryText: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primaryText)
#else
        .init()
#endif
    }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .secondaryBackground)
#else
        .init()
#endif
    }

    /// The "SecondaryText" asset catalog color.
    static var secondaryText: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .secondaryText)
#else
        .init()
#endif
    }

    /// The "SuccessGreen" asset catalog color.
    static var successGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .successGreen)
#else
        .init()
#endif
    }

    /// The "VibrantOrange" asset catalog color.
    static var vibrantOrange: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .vibrantOrange)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "MidnightGreen" asset catalog color.
    static var midnightGreen: SwiftUI.Color { .init(.midnightGreen) }

    /// The "PrimaryBackground" asset catalog color.
    static var primaryBackground: SwiftUI.Color { .init(.primaryBackground) }

    /// The "PrimaryText" asset catalog color.
    static var primaryText: SwiftUI.Color { .init(.primaryText) }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: SwiftUI.Color { .init(.secondaryBackground) }

    /// The "SecondaryText" asset catalog color.
    static var secondaryText: SwiftUI.Color { .init(.secondaryText) }

    /// The "SuccessGreen" asset catalog color.
    static var successGreen: SwiftUI.Color { .init(.successGreen) }

    /// The "VibrantOrange" asset catalog color.
    static var vibrantOrange: SwiftUI.Color { .init(.vibrantOrange) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "MidnightGreen" asset catalog color.
    static var midnightGreen: SwiftUI.Color { .init(.midnightGreen) }

    /// The "PrimaryBackground" asset catalog color.
    static var primaryBackground: SwiftUI.Color { .init(.primaryBackground) }

    /// The "PrimaryText" asset catalog color.
    static var primaryText: SwiftUI.Color { .init(.primaryText) }

    /// The "SecondaryBackground" asset catalog color.
    static var secondaryBackground: SwiftUI.Color { .init(.secondaryBackground) }

    /// The "SecondaryText" asset catalog color.
    static var secondaryText: SwiftUI.Color { .init(.secondaryText) }

    /// The "SuccessGreen" asset catalog color.
    static var successGreen: SwiftUI.Color { .init(.successGreen) }

    /// The "VibrantOrange" asset catalog color.
    static var vibrantOrange: SwiftUI.Color { .init(.vibrantOrange) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

