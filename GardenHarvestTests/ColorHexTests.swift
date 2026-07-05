import Testing
import SwiftUI
import UIKit
@testable import GardenHarvest

struct ColorHexTests {
    @Test func parsesHexWithHash() {
        let color = Color(hex: "#ff6a4d")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 1.0) < 0.01)
        #expect(abs(g - Double(0x6a) / 255.0) < 0.01)
        #expect(abs(b - Double(0x4d) / 255.0) < 0.01)
    }

    @Test func parsesHexWithoutHash() {
        let color = Color(hex: "4caf50")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - Double(0x4c) / 255.0) < 0.01)
        #expect(abs(g - Double(0xaf) / 255.0) < 0.01)
        #expect(abs(b - Double(0x50) / 255.0) < 0.01)
    }
}
