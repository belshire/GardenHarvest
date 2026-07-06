import Testing
import Foundation
@testable import GardenHarvest

/// Serialized because the tests mutate the shared `DateProvider.override`.
@Suite(.serialized)
struct DateProviderTests {
    @Test func nowIsRealClockByDefault() {
        DateProvider.reset()
        let before = Date()
        let now = DateProvider.now
        let after = Date()
        #expect(now >= before && now <= after)
    }

    @Test func overrideWinsAndResetClears() {
        let frozen = DateProvider.parse("2027-01-01")!
        DateProvider.override = frozen
        #expect(DateProvider.now == frozen)
        #expect(DateProvider.currentYear == 2027)

        DateProvider.reset()
        #expect(DateProvider.override == nil)
        #expect(abs(DateProvider.now.timeIntervalSinceNow) < 5)
    }

    @Test func currentYearFollowsOverrideAcrossRollover() {
        DateProvider.override = DateProvider.parse("2026-12-31")
        #expect(DateProvider.currentYear == 2026)
        DateProvider.override = DateProvider.parse("2027-01-01")
        #expect(DateProvider.currentYear == 2027)
        DateProvider.reset()
    }

    @Test func parseReadsYearMonthDayInCurrentCalendar() {
        let date = DateProvider.parse("2027-01-01")
        #expect(date != nil)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        #expect(components.year == 2027)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }

    @Test func parseRejectsGarbage() {
        #expect(DateProvider.parse("") == nil)
        #expect(DateProvider.parse("tomorrow") == nil)
        #expect(DateProvider.parse("01/01/2027") == nil)
    }

    @Test func launchArgumentInstallsOverride() {
        DateProvider.reset()
        DateProvider.applyLaunchArguments(["GardenHarvest", "-overrideToday", "2027-01-01"])
        #expect(DateProvider.currentYear == 2027)
        DateProvider.reset()
    }

    @Test func launchArgumentIsIgnoredWhenAbsentOrMalformed() {
        DateProvider.reset()
        DateProvider.applyLaunchArguments(["GardenHarvest"])
        #expect(DateProvider.override == nil)

        // Flag with no value.
        DateProvider.applyLaunchArguments(["GardenHarvest", "-overrideToday"])
        #expect(DateProvider.override == nil)

        // Flag with an unparseable value.
        DateProvider.applyLaunchArguments(["GardenHarvest", "-overrideToday", "next-year"])
        #expect(DateProvider.override == nil)
    }

    @Test func simulatedRolloverChangesWhichSeasonIsCurrent() {
        // The views compute `season` as DateProvider.currentYear and filter
        // through LogGrouping.entries — walk the same path across a rollover.
        func entry(_ crop: String, year: Int, month: Int, day: Int) -> HarvestEntry {
            let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
            return HarvestEntry(cropName: crop, ounces: 4, date: date)
        }
        let entries = [
            entry("Carrots", year: 2026, month: 12, day: 31),
            entry("Kale", year: 2026, month: 12, day: 30),
            entry("Kale", year: 2027, month: 1, day: 1),
            entry("Parsnips", year: 2027, month: 1, day: 2)
        ]

        DateProvider.override = DateProvider.parse("2026-12-31")
        let beforeRollover = LogGrouping.entries(in: DateProvider.currentYear, from: entries)
        #expect(beforeRollover.map(\.cropName).sorted() == ["Carrots", "Kale"])

        DateProvider.override = DateProvider.parse("2027-01-01")
        let afterRollover = LogGrouping.entries(in: DateProvider.currentYear, from: entries)
        #expect(afterRollover.map(\.cropName).sorted() == ["Kale", "Parsnips"])
        DateProvider.reset()
    }
}

/// Entries logged on either side of New Year's must partition into separate
/// seasons by the same helpers the Home/Report/Log views use.
struct YearRolloverPartitionTests {
    private func entry(_ crop: String, _ ounces: Double, year: Int, month: Int, day: Int) -> HarvestEntry {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let date = Calendar.current.date(from: components)!
        return HarvestEntry(cropName: crop, ounces: ounces, date: date)
    }

    private var boundaryEntries: [HarvestEntry] {
        [
            entry("Kale", 12, year: 2026, month: 12, day: 30),
            entry("Carrots", 20, year: 2026, month: 12, day: 31),
            entry("Kale", 6, year: 2027, month: 1, day: 1),
            entry("Parsnips", 9, year: 2027, month: 1, day: 2)
        ]
    }

    @Test func yearsSeparateDecemberAndJanuary() {
        #expect(LogGrouping.years(in: boundaryEntries) == [2027, 2026])
    }

    @Test func seasonFilterSplitsEntriesAtTheBoundary() {
        let old = LogGrouping.entries(in: 2026, from: boundaryEntries)
        let new = LogGrouping.entries(in: 2027, from: boundaryEntries)
        #expect(old.count == 2)
        #expect(new.count == 2)
        #expect(old.allSatisfy { Calendar.current.component(.year, from: $0.date) == 2026 })
        #expect(new.allSatisfy { Calendar.current.component(.year, from: $0.date) == 2027 })
    }

    @Test func seasonTotalsDoNotBleedAcrossTheBoundary() {
        // Kale appears in both years; each season's total must only count
        // its own entries (Home's totalsByCrop uses the same helpers).
        let oldTotals = LogGrouping.totalsByCrop(LogGrouping.entries(in: 2026, from: boundaryEntries))
        let newTotals = LogGrouping.totalsByCrop(LogGrouping.entries(in: 2027, from: boundaryEntries))
        #expect(oldTotals["Kale"] == 12)
        #expect(newTotals["Kale"] == 6)
        #expect(oldTotals["Parsnips"] == nil)
        #expect(newTotals["Carrots"] == nil)
    }
}
