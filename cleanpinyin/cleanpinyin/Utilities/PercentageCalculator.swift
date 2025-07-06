import Foundation

struct PercentageCalculator {
    static func percentage(numerator: Int, denominator: Int) -> Double {
        guard denominator > 0 else { return 0 }
        return Double(numerator) / Double(denominator) * 100
    }
    
    static func percentage(numerator: Double, denominator: Double) -> Double {
        guard denominator > 0 else { return 0 }
        return numerator / denominator * 100
    }
    
    static func formattedPercentage(numerator: Int, denominator: Int, decimalPlaces: Int = 0) -> String {
        let percentage = percentage(numerator: numerator, denominator: denominator)
        return String(format: "%.\(decimalPlaces)f%%", percentage)
    }
    
    static func formattedPercentage(numerator: Double, denominator: Double, decimalPlaces: Int = 0) -> String {
        let percentage = percentage(numerator: numerator, denominator: denominator)
        return String(format: "%.\(decimalPlaces)f%%", percentage)
    }
    
    static func progress(completed: Int, total: Int) -> Double {
        return percentage(numerator: completed, denominator: total) / 100
    }
}