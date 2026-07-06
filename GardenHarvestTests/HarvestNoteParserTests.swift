import Testing
import Foundation
@testable import GardenHarvest

struct HarvestNoteParserTests {
    // MARK: header & month context

    @Test func headerYearIsCaptured() {
        let parsed = HarvestNoteParser.parse("Garden Harvest 2026:\n\nJune:\nPeas, 4oz (6/23)")
        #expect(parsed.year == 2026)
        #expect(parsed.entries.count == 1)
        #expect(parsed.issues.isEmpty)
    }

    @Test func missingHeaderMeansNilYear() {
        let parsed = HarvestNoteParser.parse("June:\nPeas, 4oz (6/23)")
        #expect(parsed.year == nil)
    }

    @Test func undatedLineUsesMonthHeading() {
        let parsed = HarvestNoteParser.parse("March:\nAsparagus, 18oz")
        #expect(parsed.entries == [
            HarvestNoteParser.ParsedEntry(crop: "Asparagus", ounces: 18, month: 3, day: nil, variant: nil, note: "")
        ])
    }

    @Test func entryWithoutAnyMonthContextIsAnIssue() {
        let parsed = HarvestNoteParser.parse("Asparagus, 18oz")
        #expect(parsed.entries.isEmpty)
        #expect(parsed.issues.count == 1)
    }

    // MARK: dates

    @Test func parenDateWinsAndSetsMonthAndDay() {
        let parsed = HarvestNoteParser.parse("April:\nAsparagus, 31oz (4/7)")
        #expect(parsed.entries == [
            HarvestNoteParser.ParsedEntry(crop: "Asparagus", ounces: 31, month: 4, day: 7, variant: nil, note: "")
        ])
    }

    @Test func dateRangeUsesFirstDay() {
        let parsed = HarvestNoteParser.parse("May:\nStrawberries, 1 oz (5/9-10)")
        #expect(parsed.entries.first?.day == 9)
        #expect(parsed.entries.first?.month == 5)
    }

    // MARK: formatting quirks

    @Test func commaIsOptionalAndSpacesCollapse() {
        let parsed = HarvestNoteParser.parse("June:\nBlueberries 2oz (6/4)\nStrawberries  5 oz (6/15)")
        #expect(parsed.entries.map(\.crop) == ["Blueberries", "Strawberries"])
        #expect(parsed.entries.map(\.ounces) == [2, 5])
    }

    @Test func missingOzUnitStillParses() {
        let parsed = HarvestNoteParser.parse("June:\nTomatoes Cherry, 0.63 (6/23)")
        #expect(parsed.entries == [
            HarvestNoteParser.ParsedEntry(crop: "Tomatoes Cherry", ounces: 0.63, month: 6, day: 23, variant: nil, note: "")
        ])
    }

    @Test func variantWordBeforeAmountIsCaptured() {
        let parsed = HarvestNoteParser.parse("June:\nRaspberries, small 7.6 oz (6/11)\nRaspberries, large 1 oz (6/11)")
        #expect(parsed.entries.map(\.variant) == ["small", "large"])
        #expect(parsed.entries.map(\.crop) == ["Raspberries", "Raspberries"])
    }

    // MARK: multi-weight lines

    @Test func bareSecondWeightBecomesSecondEntry() {
        let parsed = HarvestNoteParser.parse("June:\nArtichokes 9oz, 11.5 oz (6/9)")
        #expect(parsed.entries.count == 2)
        #expect(parsed.entries.map(\.ounces) == [9, 11.5])
        #expect(parsed.entries.allSatisfy { $0.crop == "Artichokes" && $0.day == 9 })
    }

    @Test func secondWeightWithTextBecomesNote() {
        let parsed = HarvestNoteParser.parse("April:\nAsparagus, 22oz, 14oz some woody (4/13)")
        #expect(parsed.entries == [
            HarvestNoteParser.ParsedEntry(crop: "Asparagus", ounces: 22, month: 4, day: 13, variant: nil, note: "14oz some woody")
        ])
    }

    // MARK: junk

    @Test func impossibleDatesBecomeIssues() {
        let parsed = HarvestNoteParser.parse("June:\nPeas, 4oz (13/45)\nPeas, 4oz (6/32)\nPeas, 4oz (0/1)")
        #expect(parsed.entries.isEmpty)
        #expect(parsed.issues.count == 3)
    }

    @Test func unparseableLinesBecomeIssuesNotGuesses() {
        let parsed = HarvestNoteParser.parse("June:\nsomething about the weather\nPeas, 4oz (6/23)")
        #expect(parsed.entries.count == 1)
        #expect(parsed.issues.count == 1)
        #expect(parsed.issues.first?.contains("weather") == true)
    }

    // MARK: golden test against the real note

    /// Normalized comparison key; crop names are lowercased with a trailing
    /// "s" dropped so "Artichokes" matches the transcription's "Artichoke".
    private func key(_ crop: String, _ month: Int, _ day: Int?, _ ounces: Double) -> String {
        var name = crop.lowercased()
        if name.hasSuffix("s") { name = String(name.dropLast()) }
        return "\(name)|\(month)|\(day.map(String.init) ?? "x")|\(ounces)"
    }

    @Test func goldenParseOfRealNoteMatchesSeedTranscription() {
        let parsed = HarvestNoteParser.parse(Self.realNote)
        #expect(parsed.year == 2026)
        #expect(parsed.issues.isEmpty)

        let base = SeedDataService.parseBase()
        #expect(parsed.entries.count == base.count)

        // Documented transcription differences, excluded from both sides:
        // the seed hand-assigned days to March's undated lines, and summed
        // the 4/13 asparagus (22oz usable + 14oz woody → 36).
        let noteExceptions: Set<String> = [
            key("Asparagus", 3, nil, 18),
            key("Mushrooms", 3, nil, 8),
            key("Asparagus", 4, 13, 22)
        ]
        let baseExceptions: Set<String> = [
            key("Asparagus", 3, 10, 18),
            key("Mushrooms", 3, 12, 8),
            key("Asparagus", 4, 13, 36)
        ]

        let noteKeys = parsed.entries
            .map { key($0.crop, $0.month, $0.day, $0.ounces) }
            .filter { !noteExceptions.contains($0) }
            .sorted()
        let baseKeys = base
            .map { entry -> String in
                let parts = entry.monthDay.components(separatedBy: "-")
                return key(entry.crop, Int(parts[0])!, Int(parts[1])!, entry.ounces)
            }
            .filter { !baseExceptions.contains($0) }
            .sorted()
        #expect(noteKeys == baseKeys)

        // Variants survive: the raspberry small/large split.
        let smallCount = parsed.entries.filter { $0.variant == "small" }.count
        let largeCount = parsed.entries.filter { $0.variant == "large" }.count
        #expect(smallCount == 9)
        #expect(largeCount == 11)
    }

    static let realNote = """
Garden Harvest 2026:

March:
Asparagus, 18oz
Mushrooms, 8oz

April: 
Asparagus, 31oz (4/7)
Asparagus, 22oz, 14oz some woody (4/13)
Asparagus, 14oz (4/15)
Asparagus, 12oz (4/19)
Asparagus, 8oz (4/21)
Asparagus, 12 oz (4/23)
Asparagus, 8oz (4/26)
Asparagus, 8oz (4/28)
Asparagus, 16oz (4/30)

May:
Asparagus, 6oz (5/2)
Asparagus, 14.5 oz (5/4)
Asparagus, 6oz (5/7)
Asparagus, 4 oz (5/9)
Strawberries, 1 oz (5/9-10)
Strawberries, 1 oz (5/11)
Asparagus, 19.5 oz (5/12)
Artichoke, 11.5 oz (5/12)
Radishes, 6.75 oz (5/12)
Strawberries, 1 oz (5/12)
Strawberries, 0.75 oz (5/13)
Asparagus, 13 oz (5/14)
Strawberries, 3.5 oz (5/15)
Asparagus, 3 oz (5/16)
Strawberries, 2.75 oz (5/16)
Asparagus, 1.5 oz (5/18)
Strawberries, 1 oz (5/18)
Strawberries, 4 oz (5/19)
Strawberries, 1.5oz (5/20)
Asparagus, 8oz (5/20)
Asparagus, 12 oz (5/23)
Strawberries, 4.5 oz (5/23)
Radishes,  2.75 oz (5/23)
Artichoke, 10.25 oz (5/23)
Strawberries, 10.75 oz (5/25)
Asparagus, 4oz (5/27)
Strawberries, 8.5 oz (5/27)
Asparagus, 3oz (5/30)
Strawberries, 14oz (5/30)
Strawberries, 10oz (5/31)

June: 
Strawberries, 1.5 oz (6/1)
Strawberries, 3.5 oz (6/3)
Asparagus, 2oz (6/3)
Strawberries, 1 oz (6/4)
Blueberries 2oz (6/4)
Asparagus 2oz (6/6)
Strawberries 3.5 oz (6/6)
Raspberries 4oz (6/6)
Asparagus 1.75oz (6/9)
Strawberries 10.75 oz (6/9)
Raspberries 9.5 oz (6/9)
Blueberries 3oz (6/9)
Artichokes 9oz, 11.5 oz (6/9)
Raspberries, small 7.6 oz (6/11)
Strawberries, 9 oz (6/11)
Blueberries, 1.2 oz (6/11)
Asparagus, 5.2 oz (6/11)
Raspberries, large 1 oz (6/11)
Boysenberries 2.15 oz (6/11)
Strawberries, 5.5 oz (6/13)
Blueberries, 1.2 oz (6/13)
Asparagus, 1.1oz (6/13)
Raspberries, large 0.6 oz (6/13)
Boysenberries 0.75 oz (6/13)
Raspberries, small 4.5 oz (6/14)
Raspberries, large 1 oz (6/14)
Boysenberries 0.55 oz (6/14)
Blueberries, 5oz (6/15)
Raspberries, small 4.75oz (6/15)
Raspberries, large 0.75 oz (6/15)
Strawberries  5 oz (6/15)
Boysenberries 1 oz (6/16)
Raspberries, small 4 oz (6/16)
Raspberries, large 1.7 oz (6/16)
Strawberries  0.7 oz (6/16)
Blueberries, 2 oz (6/17)
Boysenberries 1.8 oz (6/17)
Raspberries, small 6.5 oz (6/17)
Raspberries, large 5.75 oz (6/17)
Strawberries  2.2 oz (6/17)
Peas 6.5 oz (6/18)
Raspberries 5oz (6/20)
Strawberries  3.4 oz (6/21)
Blueberries,  1.1 oz (6/21)
Raspberries, small 7.4 oz (6/21)
Raspberries, large 9.8 oz (6/21)
Peas, 3.9oz (6/21)
Artichoke, 10.8 oz (6/21)
Boysenberries 3.4 oz (6/22)
Strawberries, 3.2oz (6/23)
Blueberries,  2 oz (6/23)
Raspberries, small 3.4oz (6/23)
Raspberries, large 12.4 oz (6/23)
Peas, 4oz (6/23)
Tomatoes Cherry, 0.63 (6/23)
Boysenberries 0.5 oz (6/23)
Blueberries,  0.75 oz (6/25)
Raspberries, small 3.5oz (6/25)
Raspberries, large 8.75 oz (6/25)
Strawberries, 3.4 oz (6/25)
Boysenberries 1 oz (6/25)
Blueberries,  0.75 oz (6/27)
Raspberries, small 1oz (6/27)
Raspberries, large 12 oz (6/27)
Strawberries, 7.9oz (6/27)
Peas, 9.5oz (6/27)
Raspberries, large 4.3 oz (6/28)
Strawberries, 3.6 oz (6/28)
"""
}
