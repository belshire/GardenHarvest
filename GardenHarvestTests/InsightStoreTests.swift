import Testing
import Foundation
@testable import GardenHarvest

struct InsightStoreTests {
    private func entry(_ crop: String, _ ounces: Double, month: Int, day: Int) -> HarvestEntry {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        let date = Calendar.current.date(from: components)!
        return HarvestEntry(cropName: crop, ounces: ounces, date: date)
    }

    private func freshDefaults() -> UserDefaults {
        let suite = "InsightStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    // MARK: fingerprint

    @Test func fingerprintIgnoresEntryOrder() {
        let a = [entry("Peas", 3, month: 6, day: 3), entry("Asparagus", 20, month: 4, day: 2)]
        let b = [entry("Asparagus", 20, month: 4, day: 2), entry("Peas", 3, month: 6, day: 3)]
        #expect(InsightStore.fingerprint(of: a) == InsightStore.fingerprint(of: b))
    }

    @Test func fingerprintChangesWhenOuncesMoveBetweenCrops() {
        // Same count, same grand total, same dates — still a different season.
        let a = [entry("Peas", 5, month: 6, day: 3), entry("Asparagus", 3, month: 6, day: 3)]
        let b = [entry("Peas", 3, month: 6, day: 3), entry("Asparagus", 5, month: 6, day: 3)]
        #expect(InsightStore.fingerprint(of: a) != InsightStore.fingerprint(of: b))
    }

    @Test func fingerprintChangesWhenEntryAdded() {
        let a = [entry("Peas", 3, month: 6, day: 3)]
        let b = a + [entry("Peas", 3, month: 6, day: 10)]
        #expect(InsightStore.fingerprint(of: a) != InsightStore.fingerprint(of: b))
    }

    @Test func fingerprintChangesWhenNoteEdited() {
        // Notes feed the season story, so editing one must regenerate it.
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let a = [HarvestEntry(cropName: "Strawberries", ounces: 4, date: date, note: "Fought off the birds")]
        let b = [HarvestEntry(cropName: "Strawberries", ounces: 4, date: date, note: "Birds won this round")]
        let c = [HarvestEntry(cropName: "Strawberries", ounces: 4, date: date)]
        #expect(InsightStore.fingerprint(of: a) != InsightStore.fingerprint(of: b))
        #expect(InsightStore.fingerprint(of: a) != InsightStore.fingerprint(of: c))
    }

    @Test func fingerprintChangesWhenVariantEdited() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let a = [HarvestEntry(cropName: "Strawberries", ounces: 4, date: date, variant: "Albion")]
        let b = [HarvestEntry(cropName: "Strawberries", ounces: 4, date: date, variant: "Seascape")]
        let c = [HarvestEntry(cropName: "Strawberries", ounces: 4, date: date)]
        #expect(InsightStore.fingerprint(of: a) != InsightStore.fingerprint(of: b))
        #expect(InsightStore.fingerprint(of: a) != InsightStore.fingerprint(of: c))
    }

    // MARK: cache round-trip

    @Test func saveAndLoadRoundTrip() {
        let defaults = freshDefaults()
        let cached = InsightStore.Cached(
            fingerprint: "abc123",
            insights: [Insight(kind: "oneDayWonder", text: "Hello", cropName: "Artichoke")],
            story: "What a season it was."
        )
        InsightStore.save(cached, season: 2026, defaults: defaults)
        #expect(InsightStore.load(season: 2026, defaults: defaults) == cached)
    }

    @Test func roundTripPreservesNilStory() {
        let defaults = freshDefaults()
        let cached = InsightStore.Cached(fingerprint: "abc123", insights: [], story: nil)
        InsightStore.save(cached, season: 2026, defaults: defaults)
        #expect(InsightStore.load(season: 2026, defaults: defaults)?.story == nil)
    }

    @Test func loadReturnsNilForUnknownSeason() {
        #expect(InsightStore.load(season: 1999, defaults: freshDefaults()) == nil)
    }

    @Test func loadIgnoresPreVersionedCaches() {
        // v1 caches may hold AI-reworded card text; they must be orphaned.
        let defaults = freshDefaults()
        let v1Payload = try! JSONEncoder().encode(
            InsightStore.Cached(fingerprint: "f", insights: [], story: nil)
        )
        defaults.set(v1Payload, forKey: "insights.season.2026")
        #expect(InsightStore.load(season: 2026, defaults: defaults) == nil)
    }

    @Test func seasonsAreCachedIndependently() {
        let defaults = freshDefaults()
        let c2025 = InsightStore.Cached(fingerprint: "f25", insights: [], story: nil)
        let c2026 = InsightStore.Cached(fingerprint: "f26", insights: [], story: "Berries abounded.")
        InsightStore.save(c2025, season: 2025, defaults: defaults)
        InsightStore.save(c2026, season: 2026, defaults: defaults)
        #expect(InsightStore.load(season: 2025, defaults: defaults) == c2025)
        #expect(InsightStore.load(season: 2026, defaults: defaults) == c2026)
    }
}
