import Foundation

enum CropColorAssigner {
    static let knownColors: [String: String] = [
        "Asparagus": "#5a9a3d",
        "Strawberries": "#e8434a",
        "Raspberries": "#c02f66",
        "Blueberries": "#3f6ad0",
        "Boysenberries": "#6f3fa8",
        "Artichoke": "#7f9a4e",
        "Radishes": "#e05583",
        "Peas": "#8cbf4f",
        "Mushrooms": "#b08a63",
        "Tomatoes Cherry": "#ef4f34"
    ]

    static func colorHex(for name: String) -> String {
        if let known = knownColors[name] {
            return known
        }
        var hash: UInt32 = 0
        for scalar in name.unicodeScalars {
            hash = hash &* 31 &+ scalar.value
        }
        let hue = Double(hash % 360)
        return hexFromHSL(hue: hue, saturation: 0.52, lightness: 0.55)
    }

    private static func hexFromHSL(hue: Double, saturation: Double, lightness: Double) -> String {
        let c = (1 - abs(2 * lightness - 1)) * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2
        let (r1, g1, b1): (Double, Double, Double)
        switch hue {
        case 0..<60: (r1, g1, b1) = (c, x, 0)
        case 60..<120: (r1, g1, b1) = (x, c, 0)
        case 120..<180: (r1, g1, b1) = (0, c, x)
        case 180..<240: (r1, g1, b1) = (0, x, c)
        case 240..<300: (r1, g1, b1) = (x, 0, c)
        default: (r1, g1, b1) = (c, 0, x)
        }
        let r = Int(((r1 + m) * 255).rounded())
        let g = Int(((g1 + m) * 255).rounded())
        let b = Int(((b1 + m) * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
