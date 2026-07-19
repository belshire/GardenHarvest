import Testing
import Foundation
@testable import GardenHarvest

struct ReportStatsTests {
    private func entry(_ crop: String, _ ounces: Double, month: Int, day: Int) -> HarvestEntry {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        let date = Calendar.current.date(from: components)!
        return HarvestEntry(cropName: crop, ounces: ounces, date: date)
    }

    // MARK: rankedCrops

    @Test func rankedCropsSortByTotalDescending() {
        let entries = [
            entry("Peas", 4, month: 6, day: 18),
            entry("Asparagus", 18, month: 3, day: 10),
            entry("Asparagus", 31, month: 4, day: 7),
            entry("Strawberries", 10, month: 5, day: 25)
        ]
        let ranked = ReportStats.rankedCrops(entries)
        #expect(ranked.map(\.name) == ["Asparagus", "Strawberries", "Peas"])
        #expect(ranked.first?.total == 49)
    }

    @Test func rankedCropsBreakTiesByName() {
        let entries = [
            entry("Radishes", 5, month: 5, day: 12),
            entry("Artichoke", 5, month: 5, day: 12)
        ]
        #expect(ReportStats.rankedCrops(entries).map(\.name) == ["Artichoke", "Radishes"])
    }

    // MARK: superlativeTitle

    @Test func superlativeUsesKnownTitle() {
        #expect(ReportStats.superlativeTitle(for: "Raspberries", year: 2026)
            == "Bramble royalty")
    }

    @Test func superlativeFallsBackToYearedDefault() {
        #expect(ReportStats.superlativeTitle(for: "Kale", year: 2026) == "Most-picked crop of 2026")
    }

    // MARK: halfMonthBuckets

    @Test func bucketsSpanFirstToLastMonthInHalves() {
        let entries = [
            entry("Asparagus", 18, month: 3, day: 10),
            entry("Strawberries", 4, month: 5, day: 20)
        ]
        let buckets = ReportStats.halfMonthBuckets(of: entries)
        #expect(buckets.count == 6) // Mar, Apr, May × 2 halves
        #expect(buckets.map(\.label) == ["Mar", "", "Apr", "", "May", ""])
        #expect(buckets[0].total == 18) // early March
        #expect(buckets[5].total == 4)  // late May
    }

    @Test func day15CountsAsEarlyHalf() {
        let entries = [
            entry("Peas", 3, month: 6, day: 15),
            entry("Peas", 7, month: 6, day: 16)
        ]
        let buckets = ReportStats.halfMonthBuckets(of: entries)
        #expect(buckets[0].total == 3)
        #expect(buckets[1].total == 7)
    }

    @Test func bucketsEmptyForNoEntries() {
        #expect(ReportStats.halfMonthBuckets(of: []).isEmpty)
    }

    // MARK: peakLabel

    @Test func peakLabelNamesBiggestHalfMonth() {
        let entries = [
            entry("Asparagus", 18, month: 3, day: 10),
            entry("Raspberries", 40, month: 6, day: 21),
            entry("Strawberries", 4, month: 6, day: 9)
        ]
        #expect(ReportStats.peakLabel(of: entries) == "Late June")
    }

    @Test func peakLabelNilWhenEmpty() {
        #expect(ReportStats.peakLabel(of: []) == nil)
    }

    // MARK: cropTimeline

    @Test func cropTimelinePlacesPointsAcrossSeasonSpan() {
        let entries = [
            entry("Asparagus", 10, month: 3, day: 1),
            entry("Asparagus", 20, month: 4, day: 1),
            entry("Peas", 5, month: 5, day: 1) // extends the season span
        ]
        let timeline = ReportStats.cropTimeline(for: "Asparagus", seasonEntries: entries)!
        #expect(timeline.points.count == 2)
        #expect(timeline.points[0].x == 0)
        #expect(timeline.points[1].x > 0.4 && timeline.points[1].x < 0.6)
        #expect(timeline.points[0].heightFraction == 0.5)
        #expect(timeline.points[1].heightFraction == 1)
    }

    @Test func cropTimelineStatLineSummarizesPickings() {
        let entries = [
            entry("Asparagus", 18, month: 3, day: 10),
            entry("Asparagus", 36, month: 4, day: 13)
        ]
        let timeline = ReportStats.cropTimeline(for: "Asparagus", seasonEntries: entries)!
        #expect(timeline.statLine == "2 pickings · Mar 10 – Apr 13 · biggest 36 oz")
    }

    @Test func cropTimelineSinglePickingUsesSingularStatLine() {
        let entries = [entry("Peas", 6.5, month: 6, day: 18)]
        let timeline = ReportStats.cropTimeline(for: "Peas", seasonEntries: entries)!
        #expect(timeline.statLine == "1 picking · Jun 18 · biggest 6.5 oz")
    }

    @Test func cropTimelineTicksCoverCropMonths() {
        let entries = [
            entry("Asparagus", 18, month: 3, day: 10),
            entry("Asparagus", 36, month: 5, day: 13)
        ]
        let timeline = ReportStats.cropTimeline(for: "Asparagus", seasonEntries: entries)!
        #expect(timeline.ticks.map(\.label) == ["Mar", "Apr", "May"])
    }

    @Test func cropTimelineNilForUnknownCrop() {
        let entries = [entry("Peas", 6.5, month: 6, day: 18)]
        #expect(ReportStats.cropTimeline(for: "Kale", seasonEntries: entries) == nil)
    }
}

/// Which years the Report's stepper can browse to — every year with data plus
/// the current one, so the default season is always reachable.
struct AvailableReportYearsTests {
    private func entry(_ crop: String, year: Int, month: Int, day: Int) -> HarvestEntry {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
        return HarvestEntry(cropName: crop, ounces: 4, date: date)
    }

    @Test func yearsWithDataSplitAcrossDecJanBoundary() {
        let entries = [
            entry("Kale", year: 2026, month: 12, day: 30),
            entry("Carrots", year: 2026, month: 12, day: 31),
            entry("Kale", year: 2027, month: 1, day: 1),
            entry("Parsnips", year: 2027, month: 1, day: 2)
        ]
        #expect(ReportStats.availableReportYears(in: entries, currentYear: 2027) == [2027, 2026])
    }

    @Test func currentYearWithoutEntriesIsStillBrowsable() {
        // Fresh January: nothing logged in 2027 yet, but the report defaults
        // to 2027 and the stepper must be able to reach 2026 and 2025.
        let entries = [
            entry("Raspberries", year: 2025, month: 7, day: 4),
            entry("Kale", year: 2026, month: 12, day: 30)
        ]
        #expect(ReportStats.availableReportYears(in: entries, currentYear: 2027) == [2027, 2026, 2025])
    }

    @Test func currentYearWithEntriesIsNotDuplicated() {
        let entries = [
            entry("Kale", year: 2026, month: 6, day: 1),
            entry("Peas", year: 2026, month: 6, day: 2)
        ]
        #expect(ReportStats.availableReportYears(in: entries, currentYear: 2026) == [2026])
    }

    @Test func noEntriesYieldsJustTheCurrentYear() {
        #expect(ReportStats.availableReportYears(in: [], currentYear: 2026) == [2026])
    }

    @Test func defaultYearIsAlwaysFirstAndSelectable() {
        // The view seeds its selection from DateProvider.currentYear and the
        // list is newest-first, so the default season is always the first
        // stepper position even when it has no data yet.
        let entries = [entry("Kale", year: 2026, month: 12, day: 30)]
        let years = ReportStats.availableReportYears(in: entries, currentYear: 2027)
        #expect(years.first == 2027)
        #expect(years.contains(2027))
    }
}
