import Testing
@testable import GardenHarvest

struct MasterCropListTests {
    @Test func containsExpectedCoreCrops() {
        #expect(MasterCropList.names.contains("Asparagus"))
        #expect(MasterCropList.names.contains("Sweet Potatoes"))
        #expect(MasterCropList.names.count == 77)
    }

    @Test func containsIconOnlyCrops() {
        #expect(MasterCropList.names.contains("Shiitake Mushrooms"))
        #expect(MasterCropList.names.contains("Purple Daikon"))
        #expect(MasterCropList.names.contains("Turmeric"))
    }

    @Test func everyIconOnlyCropResolvesToAnIcon() {
        let iconOnly = ["Arugula", "Avocado", "Banana", "Brussels Sprouts", "Daikon",
                        "Purple Daikon", "White Radish", "Edamame", "Ginger", "Kiwi",
                        "Lime", "Mango", "Orange", "Orange Bell Pepper", "Oyster Mushrooms",
                        "Porcini Mushrooms", "Shiitake Mushrooms", "Passion Fruit",
                        "Pomegranate", "Red Onion", "Turmeric"]
        for name in iconOnly {
            #expect(CropIconAssigner.assetName(for: name) != nil, "\(name) should have an icon")
        }
    }
}
