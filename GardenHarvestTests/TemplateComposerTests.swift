import Testing
import Foundation
@testable import GardenHarvest

struct TemplateComposerTests {
    private let june14: Date = {
        Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 14))!
    }()

    private var allFactKinds: [InsightFact] {
        [
            .frequencyWeightSplit(mostPicked: "Strawberries", heaviest: "Asparagus"),
            .marathonCrop(crop: "Raspberries", spanDays: 80),
            .lateBloomer(crop: "Boysenberries"),
            .earlyBird(crop: "Asparagus"),
            .busiestDay(date: june14, crops: ["Asparagus", "Peas", "Strawberries"]),
            .steadyProducer(crop: "Raspberries", pickings: 9),
            .varietyCollector(crop: "Strawberries", variantCount: 3),
            .oneDayWonder(crop: "Artichoke")
        ]
    }

    @Test func everyFactKindGetsSubstitutedText() {
        let insights = TemplateComposer().compose(facts: allFactKinds, season: 2026)
        #expect(insights.count == allFactKinds.count)
        for insight in insights {
            #expect(!insight.text.isEmpty)
            #expect(!insight.text.contains("{")) // no unfilled placeholders
        }
    }

    @Test func insightCarriesKindAndPrimaryCrop() {
        let insights = TemplateComposer().compose(facts: allFactKinds, season: 2026)
        #expect(insights[0].kind == "frequencyWeightSplit")
        #expect(insights[0].cropName == "Strawberries")
        #expect(insights[4].kind == "busiestDay")
        #expect(insights[4].cropName == nil) // multi-crop → sparkle card
    }

    @Test func wordingIsStableForSameSeason() {
        let a = TemplateComposer().compose(facts: allFactKinds, season: 2026)
        let b = TemplateComposer().compose(facts: allFactKinds, season: 2026)
        #expect(a == b)
    }

    @Test func textNeverContainsPercentSign() {
        for season in [2024, 2025, 2026, 2027] {
            for insight in TemplateComposer().compose(facts: allFactKinds, season: season) {
                #expect(!insight.text.contains("%"))
            }
        }
    }
}
