import Testing
@testable import GardenHarvest

struct CropColorAssignerTests {
    @Test func knownCropsUseExplicitColors() {
        #expect(CropColorAssigner.colorHex(for: "Asparagus") == "#5a9a3d")
        #expect(CropColorAssigner.colorHex(for: "Raspberries") == "#c02f66")
        #expect(CropColorAssigner.colorHex(for: "Tomatoes Cherry") == "#ef4f34")
    }

    @Test func unknownCropDerivesDeterministicHashColor() {
        // Hand-computed from the prototype's hash formula (h = h*31 + charCode, unsigned
        // 32-bit, mod 360 for hue) piped through standard HSL(hue, 52%, 55%) -> RGB.
        #expect(CropColorAssigner.colorHex(for: "Kale") == "#c85162")
        #expect(CropColorAssigner.colorHex(for: "Kale") == CropColorAssigner.colorHex(for: "Kale"))
    }
}
