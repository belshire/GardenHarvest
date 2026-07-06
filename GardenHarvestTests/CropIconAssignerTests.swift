import Testing
@testable import GardenHarvest

struct CropIconAssignerTests {
    @Test func exactMatchesUseMappedSlug() {
        #expect(CropIconAssigner.assetName(for: "Strawberries") == "VegIcons/strawberry")
        #expect(CropIconAssigner.assetName(for: "Tomatoes Cherry") == "VegIcons/cherry-tomatoes")
        #expect(CropIconAssigner.assetName(for: "Boysenberries") == "VegIcons/blackberry")
        #expect(CropIconAssigner.assetName(for: "Mushrooms") == "VegIcons/champignon-mushroom")
    }

    @Test func matchIsCaseAndWhitespaceInsensitive() {
        #expect(CropIconAssigner.assetName(for: "  asparagus ") == "VegIcons/asparagus")
        #expect(CropIconAssigner.assetName(for: "KALE") == "VegIcons/kale")
    }

    @Test func substringFallbackFindsLongestKey() {
        // "Heirloom Tomatoes" has no exact entry; "tomatoes" (8 chars) beats "tomato" (6).
        #expect(CropIconAssigner.assetName(for: "Heirloom Tomatoes") == "VegIcons/tomato")
        // Partial typing matches a key that contains the query.
        #expect(CropIconAssigner.assetName(for: "strawb") == "VegIcons/strawberry")
    }

    @Test func multiWordCropsPreferTheirSpecificIcon() {
        #expect(CropIconAssigner.assetName(for: "Shiitake Mushrooms") == "VegIcons/shiitake-mushroom")
        #expect(CropIconAssigner.assetName(for: "Oyster Mushrooms") == "VegIcons/oyster-mushroom")
        #expect(CropIconAssigner.assetName(for: "Purple Daikon") == "VegIcons/purple-daikon")
        #expect(CropIconAssigner.assetName(for: "White Radish") == "VegIcons/white-radish")
        #expect(CropIconAssigner.assetName(for: "Orange Bell Pepper") == "VegIcons/orange-bell-pepper")
    }

    @Test func unknownCropsReturnNilForInitialsFallback() {
        #expect(CropIconAssigner.assetName(for: "Lettuce") == nil)
        #expect(CropIconAssigner.assetName(for: "Rhubarb") == nil)
        #expect(CropIconAssigner.assetName(for: "") == nil)
    }
}
