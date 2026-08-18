import SwiftUI

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    static let accent = Color(hex: "#ff6a4d")
    static let accent2 = Color(hex: "#4caf50")
    static let destructive = Color(hex: "#c0492f")
    static let ink = Color(hex: "#22381c")
    static let sub = Color(hex: "#6a8560")
    static let card = Color.white
    static let hairline = Color(hex: "#22381c").opacity(0.10)
    static let panelTop = Color(hex: "#f0f8e8")
    static let panelBottom = Color(hex: "#e2f2d3")

    static var panelBackground: LinearGradient {
        LinearGradient(colors: [panelTop, panelBottom], startPoint: .top, endPoint: .bottom)
    }

    static let cardRadius: CGFloat = 24
    static let tileRadius: CGFloat = 22

    enum Font {
        static func heading(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
}
