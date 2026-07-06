import Testing
import Foundation
@testable import GardenHarvest

struct InsightFactsTests {
    private func entry(_ crop: String, _ ounces: Double, month: Int, day: Int,
                       variant: String? = nil) -> HarvestEntry {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        let date = Calendar.current.date(from: components)!
        return HarvestEntry(cropName: crop, ounces: ounces, date: date, variant: variant)
    }

    // MARK: frequencyWeightSplit

    @Test func splitWhenMostPickedIsNotHeaviest() {
        // Strawberries: 3 pickings, 12 oz total. Asparagus: 2 pickings, 40 oz.
        let entries = [
            entry("Strawberries", 4, month: 5, day: 1),
            entry("Strawberries", 4, month: 5, day: 8),
            entry("Strawberries", 4, month: 5, day: 15),
            entry("Asparagus", 20, month: 4, day: 2),
            entry("Asparagus", 20, month: 4, day: 20)
        ]
        #expect(InsightFacts.frequencyWeightSplit(in: entries)
            == .frequencyWeightSplit(mostPicked: "Strawberries", heaviest: "Asparagus"))
    }

    @Test func noSplitWhenSameCropWinsBoth() {
        let entries = [
            entry("Raspberries", 10, month: 6, day: 1),
            entry("Raspberries", 10, month: 6, day: 5),
            entry("Peas", 3, month: 6, day: 3)
        ]
        #expect(InsightFacts.frequencyWeightSplit(in: entries) == nil)
    }

    @Test func noSplitWhenMostPickedHasSinglePicking() {
        let entries = [
            entry("Peas", 1, month: 6, day: 3),
            entry("Asparagus", 20, month: 4, day: 2)
        ]
        #expect(InsightFacts.frequencyWeightSplit(in: entries) == nil)
    }

    // MARK: oneDayWonder

    @Test func oneDayWonderFindsSinglePickingCrop() {
        let entries = [
            entry("Raspberries", 10, month: 6, day: 1),
            entry("Raspberries", 10, month: 6, day: 5),
            entry("Artichoke", 7, month: 7, day: 12)
        ]
        #expect(InsightFacts.oneDayWonder(in: entries) == .oneDayWonder(crop: "Artichoke"))
    }

    @Test func oneDayWonderNeedsAnotherCropInSeason() {
        let entries = [entry("Artichoke", 7, month: 7, day: 12)]
        #expect(InsightFacts.oneDayWonder(in: entries) == nil)
    }

    @Test func oneDayWonderPicksAlphabeticalFirstOnTie() {
        let entries = [
            entry("Radishes", 2, month: 5, day: 1),
            entry("Artichoke", 7, month: 7, day: 12),
            entry("Peas", 3, month: 6, day: 3),
            entry("Peas", 3, month: 6, day: 9)
        ]
        #expect(InsightFacts.oneDayWonder(in: entries) == .oneDayWonder(crop: "Artichoke"))
    }

    // MARK: marathonCrop

    @Test func marathonFindsLongestSpanOver30Days() {
        let entries = [
            entry("Raspberries", 5, month: 6, day: 1),
            entry("Raspberries", 5, month: 8, day: 20), // ~80-day span
            entry("Peas", 3, month: 6, day: 3),
            entry("Peas", 3, month: 6, day: 20)          // 17-day span
        ]
        guard case .marathonCrop(let crop, let spanDays)? = InsightFacts.marathonCrop(in: entries) else {
            Issue.record("expected marathonCrop fact")
            return
        }
        #expect(crop == "Raspberries")
        #expect(spanDays == 80)
    }

    @Test func marathonNeedsAtLeast30DaySpan() {
        let entries = [
            entry("Peas", 3, month: 6, day: 3),
            entry("Peas", 3, month: 6, day: 20)
        ]
        #expect(InsightFacts.marathonCrop(in: entries) == nil)
    }

    // MARK: lateBloomer / earlyBird

    @Test func lateBloomerSkewsToSeasonEnd() {
        // Season spans Apr 1 – Sep 30 via asparagus; boysenberries sit at the end.
        let entries = [
            entry("Asparagus", 10, month: 4, day: 1),
            entry("Asparagus", 10, month: 5, day: 1),
            entry("Boysenberries", 6, month: 9, day: 10),
            entry("Boysenberries", 6, month: 9, day: 30)
        ]
        #expect(InsightFacts.seasonTimingOutlier(in: entries) == .lateBloomer(crop: "Boysenberries"))
    }

    @Test func earlyBirdSkewsToSeasonStart() {
        let entries = [
            entry("Asparagus", 10, month: 4, day: 1),
            entry("Asparagus", 10, month: 4, day: 10),
            entry("Raspberries", 6, month: 6, day: 10),
            entry("Raspberries", 6, month: 9, day: 30)
        ]
        #expect(InsightFacts.seasonTimingOutlier(in: entries) == .earlyBird(crop: "Asparagus"))
    }

    @Test func noTimingOutlierWhenEveryoneSpansTheMiddle() {
        let entries = [
            entry("Peas", 3, month: 5, day: 1),
            entry("Peas", 3, month: 8, day: 1),
            entry("Beans", 3, month: 5, day: 15),
            entry("Beans", 3, month: 7, day: 20)
        ]
        #expect(InsightFacts.seasonTimingOutlier(in: entries) == nil)
    }

    @Test func timingOutlierNeedsMultipleCrops() {
        let entries = [
            entry("Boysenberries", 6, month: 9, day: 10),
            entry("Boysenberries", 6, month: 9, day: 30)
        ]
        #expect(InsightFacts.seasonTimingOutlier(in: entries) == nil)
    }
}
