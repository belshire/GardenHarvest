import Testing
import Foundation
@testable import GardenHarvest

struct SeedDataServiceTests {
    @Test func parseBaseProducesAllOneHundredTenEntries() {
        let base = SeedDataService.parseBase()
        #expect(base.count == 110)
        #expect(base.first?.crop == "Asparagus")
        #expect(base.first?.ounces == 18)
        #expect(base.first?.monthDay == "03-10")
        #expect(base.last?.crop == "Strawberries")
        #expect(base.last?.ounces == 3.6)
    }

    @Test func parseBaseKeepsNoteOnEntriesThatHaveOne() {
        let base = SeedDataService.parseBase()
        let woody = base.first { $0.monthDay == "04-13" }
        #expect(woody?.note == "14 oz woody")
        #expect(woody?.ounces == 36)
    }

    @Test func buildSeedPreservesOriginalOuncesAndNotes() {
        let entries = SeedDataService.buildSeed(currentYear: 2026)
        #expect(entries.count == 110)
        let woody = entries.first { $0.crop == "Asparagus" && $0.note == "14 oz woody" }
        #expect(woody?.ounces == 36)
        #expect(woody?.date == SeedDataService.date(year: 2026, monthDay: "04-13"))
    }
}
