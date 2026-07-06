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
}
