import UIKit

/// The icon a crop should display after applying override precedence:
/// custom photo > picked asset > auto-match by name > initials disc.
enum ResolvedCropIcon: Equatable {
    case custom(Data)
    case asset(String)
    case initials
}

/// A user's selection in the icon picker; `Crop.iconChoice` maps it onto the
/// model's override fields.
enum IconChoice: Equatable {
    case auto
    case asset(String)
    case custom(Data)
}

enum CropIconResolver {
    /// `assetExists` is injectable so tests don't depend on the app bundle's
    /// asset catalog.
    static func resolve(
        name: String,
        iconAssetName: String?,
        customIconData: Data?,
        assetExists: (String) -> Bool = { UIImage(named: $0) != nil }
    ) -> ResolvedCropIcon {
        if let data = customIconData { return .custom(data) }
        if let asset = iconAssetName, assetExists(asset) { return .asset(asset) }
        if let auto = CropIconAssigner.assetName(for: name) { return .asset(auto) }
        return .initials
    }

    static func resolve(for crop: Crop) -> ResolvedCropIcon {
        resolve(name: crop.name, iconAssetName: crop.iconAssetName, customIconData: crop.customIconData)
    }

    static func resolve(name: String, in crops: [Crop]) -> ResolvedCropIcon {
        let crop = crops.first { $0.name == name }
        return resolve(name: name, iconAssetName: crop?.iconAssetName, customIconData: crop?.customIconData)
    }
}

extension Crop {
    var iconChoice: IconChoice {
        get {
            if let data = customIconData { return .custom(data) }
            if let asset = iconAssetName { return .asset(asset) }
            return .auto
        }
        set {
            switch newValue {
            case .auto:
                iconAssetName = nil
                customIconData = nil
            case .asset(let name):
                iconAssetName = name
                customIconData = nil
            case .custom(let data):
                customIconData = data
                iconAssetName = nil
            }
        }
    }
}
