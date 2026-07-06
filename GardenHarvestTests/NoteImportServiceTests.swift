import Testing
import Foundation
@testable import GardenHarvest

struct NoteImportServiceTests {
    private func date(_ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    private func existing(_ crop: String, _ ounces: Double, month: Int, day: Int,
                          variant: String? = nil) -> HarvestEntry {
        HarvestEntry(cropName: crop, ounces: ounces, date: date(month, day), variant: variant)
    }

    private func parsed(_ crop: String, _ ounces: Double, month: Int, day: Int?,
                        variant: String? = nil, note: String = "") -> HarvestNoteParser.ParsedEntry {
        HarvestNoteParser.ParsedEntry(crop: crop, ounces: ounces, month: month, day: day,
                                      variant: variant, note: note)
    }

    private func plan(_ entries: [HarvestNoteParser.ParsedEntry],
                      year: Int? = 2026,
                      existingEntries: [HarvestEntry] = [],
                      existingCrops: [Crop] = []) -> NoteImportService.ImportPlan {
        NoteImportService.plan(
            parsed: HarvestNoteParser.ParsedNote(year: year, entries: entries, issues: []),
            fallbackYear: 2026,
            existingEntries: existingEntries,
            existingCrops: existingCrops
        )
    }

    // MARK: dedup

    @Test func priorYearEntryIsNotADuplicate() {
        // The store holds seeded prior seasons; a 2025 entry sharing
        // month/day/ounces must not absorb a 2026 note line.
        let priorYear = HarvestEntry(
            cropName: "Peas", ounces: 4,
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 23))!
        )
        let result = plan(
            [parsed("Peas", 4, month: 6, day: 23)],
            existingEntries: [priorYear]
        )
        #expect(result.new.count == 1)
        #expect(result.duplicateCount == 0)
    }

    @Test func exactMatchIsSkippedAsDuplicate() {
        let result = plan(
            [parsed("Peas", 4, month: 6, day: 23)],
            existingEntries: [existing("Peas", 4, month: 6, day: 23)]
        )
        #expect(result.new.isEmpty)
        #expect(result.duplicateCount == 1)
    }

    @Test func differentOuncesIsNotADuplicate() {
        let result = plan(
            [parsed("Peas", 5, month: 6, day: 23)],
            existingEntries: [existing("Peas", 4, month: 6, day: 23)]
        )
        #expect(result.new.count == 1)
        #expect(result.duplicateCount == 0)
    }

    @Test func variantDistinguishesEntries() {
        let result = plan(
            [parsed("Raspberries", 1, month: 6, day: 11, variant: "large")],
            existingEntries: [existing("Raspberries", 1, month: 6, day: 11, variant: "small")]
        )
        #expect(result.new.count == 1)
    }

    @Test func cropNameDriftStillMatches() {
        // "Artichokes" in the note, "Artichoke" in the store.
        let result = plan(
            [parsed("Artichokes", 9, month: 6, day: 9)],
            existingEntries: [existing("Artichoke", 9, month: 6, day: 9)],
            existingCrops: [Crop(name: "Artichoke", colorHex: "#aabbcc", sortIndex: 0)]
        )
        #expect(result.new.isEmpty)
        #expect(result.duplicateCount == 1)
        #expect(result.newCropNames.isEmpty)
    }

    @Test func eachExistingEntryAbsorbsOnlyOneIncoming() {
        // Note records two identical pickings; store has one → import one.
        let result = plan(
            [parsed("Peas", 4, month: 6, day: 23), parsed("Peas", 4, month: 6, day: 23)],
            existingEntries: [existing("Peas", 4, month: 6, day: 23)]
        )
        #expect(result.new.count == 1)
        #expect(result.duplicateCount == 1)
    }

    @Test func undatedEntryMatchesSameMonthAndOunces() {
        // The seed put March asparagus on 3/10; Katie's note has it undated.
        let result = plan(
            [parsed("Asparagus", 18, month: 3, day: nil)],
            existingEntries: [existing("Asparagus", 18, month: 3, day: 10)]
        )
        #expect(result.new.isEmpty)
        #expect(result.duplicateCount == 1)
    }

    @Test func undatedEntryWithoutMatchGetsTheFifteenth() {
        let result = plan([parsed("Asparagus", 18, month: 3, day: nil)])
        #expect(result.new.count == 1)
        #expect(result.new.first?.dayAssumed == true)
        let day = Calendar.current.component(.day, from: result.new.first!.date)
        #expect(day == 15)
    }

    @Test func reimportOfIdenticalNoteIsANoOp() {
        let incoming = [
            parsed("Peas", 4, month: 6, day: 23),
            parsed("Strawberries", 3.5, month: 6, day: 15),
            parsed("Asparagus", 18, month: 3, day: nil)
        ]
        let store = [
            existing("Peas", 4, month: 6, day: 23),
            existing("Strawberries", 3.5, month: 6, day: 15),
            existing("Asparagus", 18, month: 3, day: 15)
        ]
        let result = plan(incoming, existingEntries: store)
        #expect(result.new.isEmpty)
        #expect(result.duplicateCount == 3)
    }

    // MARK: crops & variants

    @Test func unknownCropIsPlannedOnce() {
        let result = plan([
            parsed("Kohlrabi", 4, month: 6, day: 23),
            parsed("Kohlrabi", 2, month: 6, day: 25)
        ])
        #expect(result.newCropNames == ["Kohlrabi"])
    }

    @Test func newVariantOnExistingCropIsPlanned() {
        let crop = Crop(name: "Raspberries", colorHex: "#aabbcc", sortIndex: 0, variants: ["small"])
        let result = plan(
            [parsed("Raspberries", 1, month: 6, day: 11, variant: "large")],
            existingCrops: [crop]
        )
        #expect(result.newVariants == ["Raspberries": ["large"]])
    }

    @Test func knownVariantIsNotReplanned() {
        let crop = Crop(name: "Raspberries", colorHex: "#aabbcc", sortIndex: 0, variants: ["small", "large"])
        let result = plan(
            [parsed("Raspberries", 1, month: 6, day: 11, variant: "large")],
            existingCrops: [crop]
        )
        #expect(result.newVariants.isEmpty)
    }

    // MARK: year

    @Test func headerYearWinsOverFallback() {
        let result = NoteImportService.plan(
            parsed: HarvestNoteParser.ParsedNote(
                year: 2024,
                entries: [parsed("Peas", 4, month: 6, day: 23)],
                issues: []
            ),
            fallbackYear: 2026,
            existingEntries: [],
            existingCrops: []
        )
        let year = Calendar.current.component(.year, from: result.new.first!.date)
        #expect(year == 2024)
    }

    @Test func fallbackYearUsedWhenHeaderMissing() {
        let result = plan([parsed("Peas", 4, month: 6, day: 23)], year: nil)
        let year = Calendar.current.component(.year, from: result.new.first!.date)
        #expect(year == 2026)
    }
}
