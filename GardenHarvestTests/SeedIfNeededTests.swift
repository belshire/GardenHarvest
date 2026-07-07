import Testing
import SwiftData
import Foundation
@testable import GardenHarvest

struct SeedIfNeededTests {
    @Test func seedsTenKnownCropsAndCurrentSeasonEntries() throws {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        SeedDataService.seedIfNeeded(context: context, currentYear: 2026)

        let crops = try context.fetch(FetchDescriptor<Crop>())
        let entries = try context.fetch(FetchDescriptor<HarvestEntry>())
        #expect(crops.count == 10)
        #expect(entries.count == 110)
        #expect(entries.allSatisfy { Calendar.current.component(.year, from: $0.date) == 2026 })

        let raspberries = crops.first { $0.name == "Raspberries" }
        #expect(raspberries?.variants == ["small", "large"])
    }

    @Test func doesNotDuplicateOnSecondCall() throws {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        SeedDataService.seedIfNeeded(context: context, currentYear: 2026)
        SeedDataService.seedIfNeeded(context: context, currentYear: 2026)

        let crops = try context.fetch(FetchDescriptor<Crop>())
        #expect(crops.count == 10)
    }
}
