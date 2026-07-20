import Foundation
import SwiftData

@Model
final class Crop {
    @Attribute(.unique) var name: String
    var colorHex: String
    var sortIndex: Int
    var variants: [String]
    /// Explicit icon pick from the VegIcons catalog, e.g. "VegIcons/red-onion".
    /// nil means auto-match from the name.
    var iconAssetName: String?
    /// Center-cropped square JPEG picked from the photo library. Takes
    /// precedence over `iconAssetName`; the two are kept mutually exclusive
    /// by `Crop.iconChoice`.
    @Attribute(.externalStorage) var customIconData: Data?

    init(
        name: String,
        colorHex: String,
        sortIndex: Int,
        variants: [String] = [],
        iconAssetName: String? = nil,
        customIconData: Data? = nil
    ) {
        self.name = name
        self.colorHex = colorHex
        self.sortIndex = sortIndex
        self.variants = variants
        self.iconAssetName = iconAssetName
        self.customIconData = customIconData
    }
}

extension Crop: Identifiable {
    var id: String { name }
}
