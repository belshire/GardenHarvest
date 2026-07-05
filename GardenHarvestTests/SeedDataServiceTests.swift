import Testing
import Foundation
@testable import GardenHarvest

struct SeedDataServiceTests {
    @Test func seedIsDeterministicAndMatchesReferenceValues() {
        #expect(abs(SeedDataService.seed(2024) - 0.3445856476391782) < 0.0000001)
        #expect(abs(SeedDataService.seed(2025) - 0.9740680162558419) < 0.0000001)
    }

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

    @Test func generateProducesExpectedAsparagusEntryTwoYearsAgo() {
        let base = SeedDataService.parseBase()
        let entries = SeedDataService.generate(base: base, year: 2024, scale: 0.62, drop: 0.32)
        let asparagus = entries.first { $0.crop == "Asparagus" && $0.ounces == 10.5 }
        #expect(asparagus != nil)
        #expect(asparagus?.date == SeedDataService.date(year: 2024, monthDay: "03-09"))
    }

    @Test func generateProducesExpectedAsparagusEntryLastYear() {
        let base = SeedDataService.parseBase()
        let entries = SeedDataService.generate(base: base, year: 2025, scale: 0.84, drop: 0.18)
        let asparagus = entries.first { $0.crop == "Asparagus" && $0.ounces == 19.4 }
        #expect(asparagus != nil)
        #expect(asparagus?.date == SeedDataService.date(year: 2025, monthDay: "03-13"))
    }

    @Test func generateProducesExpectedMushroomsEntryBothYears() {
        let base = SeedDataService.parseBase()
        let entries2024 = SeedDataService.generate(base: base, year: 2024, scale: 0.62, drop: 0.32)
        let mushrooms2024 = entries2024.first { $0.crop == "Mushrooms" }
        #expect(mushrooms2024?.ounces == 5.4)
        #expect(mushrooms2024?.date == SeedDataService.date(year: 2024, monthDay: "03-14"))

        let entries2025 = SeedDataService.generate(base: base, year: 2025, scale: 0.84, drop: 0.18)
        let mushrooms2025 = entries2025.first { $0.crop == "Mushrooms" }
        #expect(mushrooms2025?.ounces == 5.5)
        #expect(mushrooms2025?.date == SeedDataService.date(year: 2025, monthDay: "03-09"))
    }

    @Test func currentYearEntriesPreserveOriginalOuncesAndNotes() {
        let seasonSeed = SeedDataService.buildSeasonSeed(currentYear: 2026)
        #expect(seasonSeed.currentYearEntries.count == 110)
        let woody = seasonSeed.currentYearEntries.first { $0.crop == "Asparagus" && $0.note == "14 oz woody" }
        #expect(woody?.ounces == 36)
        #expect(woody?.date == SeedDataService.date(year: 2026, monthDay: "04-13"))
    }
}
