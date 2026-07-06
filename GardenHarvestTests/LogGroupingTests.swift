import Testing
import Foundation
@testable import GardenHarvest

struct LogGroupingTests {
    private func entry(_ crop: String, _ ounces: Double, year: Int, month: Int, day: Int) -> HarvestEntry {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let date = Calendar.current.date(from: components)!
        return HarvestEntry(cropName: crop, ounces: ounces, date: date)
    }

    @Test func yearsAreDistinctAndNewestFirst() {
        let entries = [
            entry("Peas", 4, year: 2024, month: 6, day: 1),
            entry("Peas", 4, year: 2026, month: 6, day: 1),
            entry("Asparagus", 8, year: 2026, month: 4, day: 2),
            entry("Peas", 4, year: 2025, month: 6, day: 1)
        ]
        #expect(LogGrouping.years(in: entries) == [2026, 2025, 2024])
    }

    @Test func entriesInYearFiltersByCalendarYear() {
        let entries = [
            entry("Peas", 4, year: 2025, month: 12, day: 31),
            entry("Peas", 6, year: 2026, month: 1, day: 1)
        ]
        let filtered = LogGrouping.entries(in: 2026, from: entries)
        #expect(filtered.count == 1)
        #expect(filtered.first?.ounces == 6)
    }

    @Test func monthGroupsSortMonthsAndDaysDescendingWithTotals() {
        let entries = [
            entry("Asparagus", 18, year: 2026, month: 3, day: 10),
            entry("Strawberries", 4, year: 2026, month: 6, day: 9),
            entry("Raspberries", 9.5, year: 2026, month: 6, day: 9),
            entry("Peas", 6.5, year: 2026, month: 6, day: 18)
        ]
        let groups = LogGrouping.monthGroups(of: entries)
        #expect(groups.map(\.month) == [6, 3])
        #expect(groups[0].total == 20)
        #expect(groups[1].total == 18)

        let juneDays = groups[0].days
        #expect(juneDays.count == 2)
        #expect(Calendar.current.component(.day, from: juneDays[0].date) == 18)
        #expect(Calendar.current.component(.day, from: juneDays[1].date) == 9)
        #expect(juneDays[1].entries.count == 2)
    }

    @Test func monthGroupsOfNothingIsEmpty() {
        #expect(LogGrouping.monthGroups(of: []).isEmpty)
    }

    @Test func totalsByCropSumsOunces() {
        let entries = [
            entry("Peas", 4, year: 2026, month: 6, day: 1),
            entry("Peas", 3.5, year: 2026, month: 6, day: 3),
            entry("Asparagus", 8, year: 2026, month: 4, day: 2)
        ]
        let totals = LogGrouping.totalsByCrop(entries)
        #expect(totals["Peas"] == 7.5)
        #expect(totals["Asparagus"] == 8)
    }

    @Test func peakMonthPicksHighestTotal() {
        let entries = [
            entry("Asparagus", 18, year: 2026, month: 3, day: 10),
            entry("Strawberries", 10, year: 2026, month: 6, day: 9),
            entry("Raspberries", 9.5, year: 2026, month: 6, day: 11)
        ]
        #expect(LogGrouping.peakMonth(of: entries) == 6)
        #expect(LogGrouping.peakMonth(of: []) == nil)
    }
}
