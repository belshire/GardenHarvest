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

    // MARK: cache round-trip

    @Test func saveAndLoadRoundTrip() {
        let defaults = freshDefaults()
        let cached = InsightStore.Cached(
            fingerprint: "abc123",
            insights: [Insight(kind: "oneDayWonder", text: "Hello", cropName: "Artichoke")],
            aiComposed: true
        )
        InsightStore.save(cached, season: 2026, defaults: defaults)
        #expect(InsightStore.load(season: 2026, defaults: defaults) == cached)
    }

    @Test func loadReturnsNilForUnknownSeason() {
        #expect(InsightStore.load(season: 1999, defaults: freshDefaults()) == nil)
    }

    @Test func seasonsAreCachedIndependently() {
        let defaults = freshDefaults()
        let c2025 = InsightStore.Cached(fingerprint: "f25", insights: [], aiComposed: false)
        let c2026 = InsightStore.Cached(fingerprint: "f26", insights: [], aiComposed: true)
        InsightStore.save(c2025, season: 2025, defaults: defaults)
        InsightStore.save(c2026, season: 2026, defaults: defaults)
        #expect(InsightStore.load(season: 2025, defaults: defaults) == c2025)
        #expect(InsightStore.load(season: 2026, defaults: defaults) == c2026)
    }
}
