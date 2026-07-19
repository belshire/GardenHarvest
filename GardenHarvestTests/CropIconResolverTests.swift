import Foundation
import Testing
@testable import GardenHarvest

struct CropIconResolverTests {
    private let png = Data([0x89, 0x50, 0x4E, 0x47]) // content irrelevant to the resolver

    @Test func customDataWinsOverEverything() {
        let icon = CropIconResolver.resolve(
            name: "Kale", iconAssetName: "VegIcons/carrot", customIconData: png,
            assetExists: { _ in true }
        )
        #expect(icon == .custom(png))
    }

    @Test func pickedAssetBeatsAutoMatch() {
        let icon = CropIconResolver.resolve(
            name: "Kale", iconAssetName: "VegIcons/red-onion", customIconData: nil,
            assetExists: { _ in true }
        )
        #expect(icon == .asset("VegIcons/red-onion"))
    }

    @Test func missingPickedAssetFallsThroughToAutoMatch() {
        let icon = CropIconResolver.resolve(
            name: "Kale", iconAssetName: "VegIcons/gone", customIconData: nil,
            assetExists: { _ in false }
        )
        #expect(icon == .asset("VegIcons/kale"))
    }

    @Test func noOverridesUsesAutoMatchThenInitials() {
        #expect(CropIconResolver.resolve(
            name: "Kale", iconAssetName: nil, customIconData: nil, assetExists: { _ in true }
        ) == .asset("VegIcons/kale"))
        #expect(CropIconResolver.resolve(
            name: "Rhubarb", iconAssetName: nil, customIconData: nil, assetExists: { _ in true }
        ) == .initials)
    }

    @Test func lookupByNameFindsTheCropsOverrides() {
        let crop = Crop(name: "Radishes", colorHex: "#aabbcc", sortIndex: 0,
                        iconAssetName: "VegIcons/purple-daikon")
        let icon = CropIconResolver.resolve(name: "Radishes", in: [crop])
        #expect(icon == .asset("VegIcons/purple-daikon"))
        // Unknown names still auto-match.
        #expect(CropIconResolver.resolve(name: "Kale", in: [crop]) == .asset("VegIcons/kale"))
    }

    @Test func iconChoiceSetterKeepsOverridesMutuallyExclusive() {
        let crop = Crop(name: "Kale", colorHex: "#aabbcc", sortIndex: 0)
        #expect(crop.iconChoice == .auto)

        crop.iconChoice = .asset("VegIcons/carrot")
        #expect(crop.iconAssetName == "VegIcons/carrot")
        #expect(crop.customIconData == nil)

        crop.iconChoice = .custom(png)
        #expect(crop.customIconData == png)
        #expect(crop.iconAssetName == nil)

        crop.iconChoice = .auto
        #expect(crop.iconAssetName == nil)
        #expect(crop.customIconData == nil)
    }
}
