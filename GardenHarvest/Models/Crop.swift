import Foundation
import SwiftData

@Model
final class Crop {
    @Attribute(.unique) var name: String
    var colorHex: String
    var sortIndex: Int
    var variants: [String]

    init(
        name: String,
        colorHex: String,
        sortIndex: Int,
        variants: [String] = []
    ) {
        self.name = name
        self.colorHex = colorHex
        self.sortIndex = sortIndex
        self.variants = variants
    }
}

extension Crop: Identifiable {
    var id: String { name }
}
