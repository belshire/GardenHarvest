import Foundation

enum WeightFormatter {
    static func ounces(_ oz: Double) -> String {
        let rounded = (oz * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    static func poundsAndOunces(_ oz: Double) -> String {
        let rounded = (oz * 10).rounded() / 10
        guard rounded >= 16 else { return "\(ounces(rounded)) oz" }
        let pounds = Int(rounded / 16)
        let remainder = ((rounded - Double(pounds) * 16) * 10).rounded() / 10
        if remainder > 0 {
            return "\(pounds) lb \(ounces(remainder)) oz"
        }
        return "\(pounds) lb"
    }
}
