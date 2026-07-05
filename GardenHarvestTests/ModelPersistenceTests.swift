import Testing
import SwiftData
import Foundation
@testable import GardenHarvest

struct ModelPersistenceTests {
    @Test func harvestEntryAndCropRoundTripThroughSwiftData() throws {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let crop = Crop(name: "Asparagus", colorHex: "#5a9a3d", isQuickLog: true, sortIndex: 0, variants: [])
        context.insert(crop)
        let entry = HarvestEntry(cropName: "Asparagus", ounces: 18, date: .now)
        context.insert(entry)
        try context.save()

        let fetchedCrops = try context.fetch(FetchDescriptor<Crop>())
        let fetchedEntries = try context.fetch(FetchDescriptor<HarvestEntry>())
        #expect(fetchedCrops.count == 1)
        #expect(fetchedEntries.count == 1)
        #expect(fetchedEntries.first?.ounces == 18)
        #expect(fetchedCrops.first?.variants.isEmpty == true)
    }
}
