import Testing
@testable import GardenHarvest

struct MasterCropListTests {
    @Test func containsExpectedCoreCrops() {
        #expect(MasterCropList.names.contains("Asparagus"))
        #expect(MasterCropList.names.contains("Sweet Potatoes"))
        #expect(MasterCropList.names.count == 56)
    }
}
