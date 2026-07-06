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

    // MARK: busiestDay

    @Test func busiestDayNeedsThreeCrops() {
        let entries = [
            entry("Peas", 3, month: 6, day: 14),
            entry("Strawberries", 4, month: 6, day: 14),
            entry("Raspberries", 5, month: 6, day: 15)
        ]
        #expect(InsightFacts.busiestDay(in: entries) == nil)
    }

    @Test func busiestDayReportsCropsSorted() {
        let entries = [
            entry("Peas", 3, month: 6, day: 14),
            entry("Strawberries", 4, month: 6, day: 14),
            entry("Strawberries", 2, month: 6, day: 14), // same crop twice, counts once
            entry("Asparagus", 8, month: 6, day: 14),
            entry("Raspberries", 5, month: 6, day: 15)
        ]
        guard case .busiestDay(let date, let crops)? = InsightFacts.busiestDay(in: entries) else {
            Issue.record("expected busiestDay fact")
            return
        }
        #expect(crops == ["Asparagus", "Peas", "Strawberries"])
        #expect(Calendar.current.component(.day, from: date) == 14)
    }

    // MARK: steadyProducer

    @Test func steadyProducerRewardsEvenSpread() {
        // Raspberries: 5 pickings, evenly ~2 weeks apart across 56 days.
        let entries = [
            entry("Raspberries", 5, month: 6, day: 1),
            entry("Raspberries", 5, month: 6, day: 15),
            entry("Raspberries", 5, month: 6, day: 29),
            entry("Raspberries", 5, month: 7, day: 13),
            entry("Raspberries", 5, month: 7, day: 27)
        ]
        #expect(InsightFacts.steadyProducer(in: entries)
            == .steadyProducer(crop: "Raspberries", pickings: 5))
    }

    @Test func steadyProducerRejectsLongDrySpell() {
        // 5 pickings but a 44-day gap in a 56-day span (ratio > 0.35).
        let entries = [
            entry("Raspberries", 5, month: 6, day: 1),
            entry("Raspberries", 5, month: 6, day: 5),
            entry("Raspberries", 5, month: 6, day: 9),
            entry("Raspberries", 5, month: 6, day: 13),
            entry("Raspberries", 5, month: 7, day: 27)
        ]
        #expect(InsightFacts.steadyProducer(in: entries) == nil)
    }

    @Test func steadyProducerNeedsFivePickings() {
        let entries = [
            entry("Raspberries", 5, month: 6, day: 1),
            entry("Raspberries", 5, month: 6, day: 15),
            entry("Raspberries", 5, month: 6, day: 29),
            entry("Raspberries", 5, month: 7, day: 13)
        ]
        #expect(InsightFacts.steadyProducer(in: entries) == nil)
    }

    // MARK: varietyCollector

    @Test func varietyCollectorCountsDistinctVariants() {
        let entries = [
            entry("Strawberries", 4, month: 5, day: 1, variant: "Albion"),
            entry("Strawberries", 4, month: 5, day: 8, variant: "Seascape"),
            entry("Strawberries", 4, month: 5, day: 15, variant: "Albion"),
            entry("Peas", 3, month: 6, day: 3, variant: "Sugar Snap")
        ]
        #expect(InsightFacts.varietyCollector(in: entries)
            == .varietyCollector(crop: "Strawberries", variantCount: 2))
    }

    @Test func varietyCollectorIgnoresNilAndEmptyVariants() {
        let entries = [
            entry("Strawberries", 4, month: 5, day: 1, variant: "Albion"),
            entry("Strawberries", 4, month: 5, day: 8, variant: ""),
            entry("Strawberries", 4, month: 5, day: 15)
        ]
        #expect(InsightFacts.varietyCollector(in: entries) == nil)
    }

    // MARK: topFacts

    @Test func topFactsEmptyForEmptySeason() {
        #expect(InsightFacts.topFacts(in: []).isEmpty)
    }

    @Test func topFactsOrdersByPriorityAndCapsAtFive() {
        // Rich season triggering many extractors at once.
        let entries = [
            // Strawberries: most picked (4), two variants, evenly spread over ~2 months
            entry("Strawberries", 3, month: 5, day: 1, variant: "Albion"),
            entry("Strawberries", 3, month: 5, day: 20, variant: "Seascape"),
            entry("Strawberries", 3, month: 6, day: 10, variant: "Albion"),
            entry("Strawberries", 3, month: 6, day: 28, variant: "Albion"),
            // Asparagus: heaviest, early bird
            entry("Asparagus", 30, month: 4, day: 1),
            entry("Asparagus", 30, month: 4, day: 15),
            // Raspberries: marathon span Apr–Sep
            entry("Raspberries", 5, month: 4, day: 5),
            entry("Raspberries", 5, month: 9, day: 20),
            // Artichoke: one-day wonder
            entry("Artichoke", 7, month: 7, day: 12),
            // Busiest day: 3 crops on Jun 10
            entry("Peas", 2, month: 6, day: 10),
            entry("Asparagus", 4, month: 6, day: 10)
        ]
        let facts = InsightFacts.topFacts(in: entries)
        #expect(facts.count <= 5)
        #expect(facts.first?.kind == "frequencyWeightSplit")
        // Priority order preserved: each fact's priority index increases.
        let order = ["frequencyWeightSplit", "marathonCrop", "lateBloomer", "earlyBird",
                     "busiestDay", "steadyProducer", "varietyCollector", "oneDayWonder"]
        let indices = facts.compactMap { order.firstIndex(of: $0.kind) }
        #expect(indices == indices.sorted())
    }

    @Test func topFactsSkipsUnmetExtractors() {
        // Single crop, two pickings, short span: nothing should trigger.
        let entries = [
            entry("Peas", 3, month: 6, day: 3),
            entry("Peas", 3, month: 6, day: 10)
        ]
        #expect(InsightFacts.topFacts(in: entries).isEmpty)
    }

    // MARK: promptLine

    @Test func promptLinesArePlainEnglishFactStatements() {
        let facts: [InsightFact] = [
            .frequencyWeightSplit(mostPicked: "Strawberries", heaviest: "Asparagus"),
            .oneDayWonder(crop: "Artichoke")
        ]
        #expect(facts[0].promptLine
            == "The gardener picked Strawberries more often than any other crop, but Asparagus weighed the most in total.")
        #expect(facts[1].promptLine == "Artichoke was picked exactly once all season.")
    }
}
