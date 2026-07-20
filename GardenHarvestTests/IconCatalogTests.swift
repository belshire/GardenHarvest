import Testing
@testable import GardenHarvest

struct IconCatalogTests {
    @Test func catalogMatchesEverySlugTheAssignerCanProduce() {
        // Every icon the auto-matcher knows is offered in the picker, and the
        // picker offers nothing the catalog doesn't ship (cornucopia excluded
        // by design — it is the "All crops" symbol).
        #expect(Set(IconCatalog.allSlugs) == Set(CropIconAssigner.iconMap.values))
    }

    @Test func slugsAreUniqueAndSorted() {
        #expect(IconCatalog.allSlugs == IconCatalog.allSlugs.sorted())
        #expect(Set(IconCatalog.allSlugs).count == IconCatalog.allSlugs.count)
    }

    @Test func displayNameAndAssetNameFormatting() {
        #expect(IconCatalog.displayName(for: "red-bell-pepper") == "Red Bell Pepper")
        #expect(IconCatalog.assetName(for: "kale") == "VegIcons/kale")
    }
}
