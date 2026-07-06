# AI Insights Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `AIInsightCard` placeholder on the Report tab with a swipeable deck of qualitative season insights, worded by the on-device Apple Intelligence model (FoundationModels, iOS 26) when available and by hand-written templates everywhere else.

**Architecture:** Facts-first, three layers. `InsightFacts` deterministically extracts typed `InsightFact` values from a season's entries; an `InsightComposer` (template or FoundationModels) turns them into `Insight` sentences; `InsightStore` caches composed insights per season keyed by a fingerprint of the entries so any data change regenerates them. The UI is a paged `InsightDeck` with crop-tinted cards.

**Tech Stack:** Swift 5 / SwiftUI / SwiftData, Swift Testing (`@Test` / `#expect`), FoundationModels (iOS 26, availability-gated; deployment target stays iOS 17).

**Spec:** `docs/superpowers/specs/2026-07-06-ai-insights-design.md`

**Project conventions that override defaults:**
- `project.pbxproj` is managed **by hand**. NEVER run `xcodegen` — it wipes signing. New files get manually added pbxproj entries (Task 1 does all of them).
- Tests run with: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/<SuiteName> 2>&1 | tail -30`
- Builds run with: `xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`
- Test files instantiate `HarvestEntry` directly without a ModelContainer (see `GardenHarvestTests/ReportStatsTests.swift` for the pattern).

---

### Task 1: Stub files + pbxproj registration

Create every new file as a compiling stub and register all of them in `project.pbxproj` once, so later tasks never touch the project file.

**Files:**
- Create: `GardenHarvest/Services/InsightFacts.swift`
- Create: `GardenHarvest/Services/InsightComposer.swift`
- Create: `GardenHarvest/Services/InsightStore.swift`
- Create: `GardenHarvest/Services/FoundationModelComposer.swift`
- Create: `GardenHarvest/Views/Report/InsightDeck.swift`
- Create: `GardenHarvestTests/InsightFactsTests.swift`
- Create: `GardenHarvestTests/TemplateComposerTests.swift`
- Create: `GardenHarvestTests/InsightStoreTests.swift`
- Modify: `GardenHarvest.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create stub source files**

`GardenHarvest/Services/InsightFacts.swift`:
```swift
import Foundation

/// Deterministic extraction of qualitative season insights. Filled in by
/// later tasks; composers only decide wording, never facts.
enum InsightFacts {}
```

`GardenHarvest/Services/InsightComposer.swift`:
```swift
import Foundation

/// Composed insight text plus the crop whose icon/color the card shows.
/// Filled in by later tasks.
enum InsightComposerStub {}
```

`GardenHarvest/Services/InsightStore.swift`:
```swift
import Foundation

/// Per-season insight cache keyed by a fingerprint of the entries.
/// Filled in by later tasks.
enum InsightStore {}
```

`GardenHarvest/Services/FoundationModelComposer.swift`:
```swift
import Foundation

/// On-device Apple Intelligence wording (iOS 26+). Filled in by later tasks.
enum FoundationModelComposerStub {}
```

`GardenHarvest/Views/Report/InsightDeck.swift`:
```swift
import SwiftUI

/// Swipeable deck of season insight cards. Filled in by later tasks.
struct InsightDeckStub {}
```

`GardenHarvestTests/InsightFactsTests.swift`:
```swift
import Testing
import Foundation
@testable import GardenHarvest

struct InsightFactsTests {}
```

`GardenHarvestTests/TemplateComposerTests.swift`:
```swift
import Testing
import Foundation
@testable import GardenHarvest

struct TemplateComposerTests {}
```

`GardenHarvestTests/InsightStoreTests.swift`:
```swift
import Testing
import Foundation
@testable import GardenHarvest

struct InsightStoreTests {}
```

- [ ] **Step 2: Register all eight files in project.pbxproj (by hand)**

The project uses sequential hex IDs. The most recent pair is `1A7C440BD90FE231AC64B013` (file ref) / `2B8D551CE00FE231AC64C013` (build file) for `YearStepper.swift`. Use the next eight suffixes:

| File | PBXFileReference ID | PBXBuildFile ID | Target |
|---|---|---|---|
| InsightFacts.swift | 1A7C440BD90FE231AC64B014 | 2B8D551CE00FE231AC64C014 | app |
| InsightComposer.swift | 1A7C440BD90FE231AC64B015 | 2B8D551CE00FE231AC64C015 | app |
| InsightStore.swift | 1A7C440BD90FE231AC64B016 | 2B8D551CE00FE231AC64C016 | app |
| FoundationModelComposer.swift | 1A7C440BD90FE231AC64B017 | 2B8D551CE00FE231AC64C017 | app |
| InsightDeck.swift | 1A7C440BD90FE231AC64B018 | 2B8D551CE00FE231AC64C018 | app |
| InsightFactsTests.swift | 1A7C440BD90FE231AC64B019 | 2B8D551CE00FE231AC64C019 | tests |
| TemplateComposerTests.swift | 1A7C440BD90FE231AC64B01A | 2B8D551CE00FE231AC64C01A | tests |
| InsightStoreTests.swift | 1A7C440BD90FE231AC64B01B | 2B8D551CE00FE231AC64C01B | tests |

Four edits per file, each following the exact pattern of the `DateProvider.swift` (app) or `YearRolloverTests.swift` (tests) lines already in the file:

1. **PBXBuildFile section** (top of file, near line 31): e.g.
   `2B8D551CE00FE231AC64C014 /* InsightFacts.swift in Sources */ = {isa = PBXBuildFile; fileRef = 1A7C440BD90FE231AC64B014 /* InsightFacts.swift */; };`
2. **PBXFileReference section** (near line 95): e.g.
   `1A7C440BD90FE231AC64B014 /* InsightFacts.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = InsightFacts.swift; sourceTree = "<group>"; };`
3. **Group children**: the four `Services` files go in the Services group (the children list containing `1A7C440BD90FE231AC64B011 /* DateProvider.swift */`, near line 177); `InsightDeck.swift` goes in the Report group (the children list containing `1A7C440BD90FE231AC64B00D /* AIInsightCard.swift */`, near line 286); the three test files go in the tests group (children list containing `1A7C440BD90FE231AC64B012 /* YearRolloverTests.swift */`, near line 246).
4. **Sources build phase**: app files go in the app target's `PBXSourcesBuildPhase` files list (the one containing `2B8D551CE00FE231AC64C011 /* DateProvider.swift in Sources */`, near line 431); test files go in the test target's list (the one containing `2B8D551CE00FE231AC64C012 /* YearRolloverTests.swift in Sources */`, near line 405).

- [ ] **Step 3: Build to verify registration**

Run: `xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add GardenHarvest GardenHarvestTests GardenHarvest.xcodeproj/project.pbxproj
git commit -m "Add stub files and project entries for AI insights"
```

---

### Task 2: `InsightFact` model + frequency/weight split + one-day wonder

**Files:**
- Modify: `GardenHarvest/Services/InsightFacts.swift`
- Test: `GardenHarvestTests/InsightFactsTests.swift`

- [ ] **Step 1: Write the failing tests**

Replace `GardenHarvestTests/InsightFactsTests.swift` with:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: FAIL — compile errors, `InsightFacts` has no member `frequencyWeightSplit` / no `InsightFact` type.

- [ ] **Step 3: Implement**

Replace `GardenHarvest/Services/InsightFacts.swift` with:

```swift
import Foundation

/// A qualitative observation about one season's harvest. Extraction is
/// deterministic so composers (template or AI) only decide wording, never
/// facts. Each case carries the crop(s) involved so the insight card can
/// show the right icon and color.
enum InsightFact: Equatable {
    /// The most-picked crop (by picking count) differs from the heaviest
    /// crop (by total ounces).
    case frequencyWeightSplit(mostPicked: String, heaviest: String)
    /// Longest first-to-last picking span.
    case marathonCrop(crop: String, spanDays: Int)
    /// Crop whose pickings sit latest in the season.
    case lateBloomer(crop: String)
    /// Crop whose pickings sit earliest in the season.
    case earlyBird(crop: String)
    /// The date with the most distinct crops picked.
    case busiestDay(date: Date, crops: [String])
    /// Many pickings, no long dry spells across its span.
    case steadyProducer(crop: String, pickings: Int)
    /// Crop with the most distinct logged variants.
    case varietyCollector(crop: String, variantCount: Int)
    /// A crop picked exactly once all season (only when others were picked more).
    case oneDayWonder(crop: String)

    /// Crop whose icon/color the card should use; nil → generic sparkle.
    var primaryCrop: String? {
        switch self {
        case .frequencyWeightSplit(let mostPicked, _):
            return mostPicked
        case .marathonCrop(let crop, _), .lateBloomer(let crop), .earlyBird(let crop),
             .steadyProducer(let crop, _), .varietyCollector(let crop, _),
             .oneDayWonder(let crop):
            return crop
        case .busiestDay:
            return nil
        }
    }

    /// Stable identifier for template seeding and cache round-trips.
    var kind: String {
        switch self {
        case .frequencyWeightSplit: return "frequencyWeightSplit"
        case .marathonCrop: return "marathonCrop"
        case .lateBloomer: return "lateBloomer"
        case .earlyBird: return "earlyBird"
        case .busiestDay: return "busiestDay"
        case .steadyProducer: return "steadyProducer"
        case .varietyCollector: return "varietyCollector"
        case .oneDayWonder: return "oneDayWonder"
        }
    }
}

/// Deterministic extraction of qualitative season insights. Each extractor
/// returns nil when its threshold isn't met; ties break alphabetically so
/// results are stable run to run.
enum InsightFacts {
    /// Picking counts per crop (each entry is one picking).
    static func pickingCounts(_ entries: [HarvestEntry]) -> [String: Int] {
        Dictionary(grouping: entries, by: \.cropName).mapValues(\.count)
    }

    static func frequencyWeightSplit(in entries: [HarvestEntry]) -> InsightFact? {
        let counts = pickingCounts(entries)
        guard let mostPicked = counts
            .sorted(by: { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value })
            .first, mostPicked.value >= 2
        else { return nil }
        guard let heaviest = ReportStats.rankedCrops(entries).first,
              heaviest.name != mostPicked.key
        else { return nil }
        return .frequencyWeightSplit(mostPicked: mostPicked.key, heaviest: heaviest.name)
    }

    static func oneDayWonder(in entries: [HarvestEntry]) -> InsightFact? {
        let counts = pickingCounts(entries)
        guard counts.count >= 2,
              let wonder = counts.filter({ $0.value == 1 }).keys.sorted().first
        else { return nil }
        return .oneDayWonder(crop: wonder)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/InsightFacts.swift GardenHarvestTests/InsightFactsTests.swift
git commit -m "Add InsightFact model with frequency/weight split and one-day wonder"
```

---

### Task 3: Marathon crop + late bloomer / early bird

**Files:**
- Modify: `GardenHarvest/Services/InsightFacts.swift`
- Test: `GardenHarvestTests/InsightFactsTests.swift`

- [ ] **Step 1: Write the failing tests** (append inside `InsightFactsTests`)

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: FAIL — no member `marathonCrop` / `seasonTimingOutlier`.

- [ ] **Step 3: Implement** (append inside `enum InsightFacts`)

```swift
    /// Longest first-to-last picking span among crops with ≥ 2 pickings,
    /// emitted only when it reaches 30 days. Ties break alphabetically.
    static func marathonCrop(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let spans: [(crop: String, days: Int)] = Dictionary(grouping: entries, by: \.cropName)
            .compactMap { crop, cropEntries in
                let days = cropEntries.map { calendar.startOfDay(for: $0.date) }
                guard cropEntries.count >= 2, let first = days.min(), let last = days.max()
                else { return nil }
                let span = calendar.dateComponents([.day], from: first, to: last).day ?? 0
                return (crop, span)
            }
        guard let longest = spans
            .sorted(by: { $0.days == $1.days ? $0.crop < $1.crop : $0.days > $1.days })
            .first, longest.days >= 30
        else { return nil }
        return .marathonCrop(crop: longest.crop, spanDays: longest.days)
    }

    /// The crop (≥ 2 pickings) whose mean picking position across the
    /// season's date span sits latest (≥ 0.75 → late bloomer) or earliest
    /// (≤ 0.25 → early bird). Late bloomer wins when both exist. Needs at
    /// least two crops so the outlier has something to stand out from.
    static func seasonTimingOutlier(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let allDays = entries.map { calendar.startOfDay(for: $0.date) }
        guard Set(entries.map(\.cropName)).count >= 2,
              let seasonStart = allDays.min(), let seasonEnd = allDays.max(),
              seasonStart < seasonEnd
        else { return nil }
        let span = Double(calendar.dateComponents([.day], from: seasonStart, to: seasonEnd).day ?? 1)

        let means: [(crop: String, mean: Double)] = Dictionary(grouping: entries, by: \.cropName)
            .compactMap { crop, cropEntries in
                guard cropEntries.count >= 2 else { return nil }
                let positions = cropEntries.map { entry -> Double in
                    let day = calendar.startOfDay(for: entry.date)
                    let offset = calendar.dateComponents([.day], from: seasonStart, to: day).day ?? 0
                    return Double(offset) / span
                }
                return (crop, positions.reduce(0, +) / Double(positions.count))
            }

        if let late = means
            .filter({ $0.mean >= 0.75 })
            .sorted(by: { $0.mean == $1.mean ? $0.crop < $1.crop : $0.mean > $1.mean })
            .first {
            return .lateBloomer(crop: late.crop)
        }
        if let early = means
            .filter({ $0.mean <= 0.25 })
            .sorted(by: { $0.mean == $1.mean ? $0.crop < $1.crop : $0.mean < $1.mean })
            .first {
            return .earlyBird(crop: early.crop)
        }
        return nil
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: PASS (11 tests)

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/InsightFacts.swift GardenHarvestTests/InsightFactsTests.swift
git commit -m "Add marathon-crop and season-timing-outlier insight facts"
```

---

### Task 4: Busiest day + steady producer + variety collector

**Files:**
- Modify: `GardenHarvest/Services/InsightFacts.swift`
- Test: `GardenHarvestTests/InsightFactsTests.swift`

- [ ] **Step 1: Write the failing tests** (append inside `InsightFactsTests`)

```swift
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
        // 5 pickings but one 40-day gap in a 56-day span (ratio > 0.35).
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: FAIL — no member `busiestDay` / `steadyProducer` / `varietyCollector`.

- [ ] **Step 3: Implement** (append inside `enum InsightFacts`)

```swift
    /// The single date with the most distinct crops picked (≥ 3). Ties break
    /// toward the earliest date so results are stable.
    static func busiestDay(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let byDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .mapValues { Set($0.map(\.cropName)) }
        guard let busiest = byDay
            .sorted(by: { $0.value.count == $1.value.count ? $0.key < $1.key : $0.value.count > $1.value.count })
            .first, busiest.value.count >= 3
        else { return nil }
        return .busiestDay(date: busiest.key, crops: busiest.value.sorted())
    }

    /// Crop with ≥ 5 pickings across ≥ 28 days whose longest gap between
    /// consecutive pickings is at most 35% of its span — i.e. it kept
    /// producing with no long dry spells. Best (smallest max-gap ratio) wins.
    static func steadyProducer(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let candidates: [(crop: String, pickings: Int, ratio: Double)] =
            Dictionary(grouping: entries, by: \.cropName).compactMap { crop, cropEntries in
                guard cropEntries.count >= 5 else { return nil }
                let days = cropEntries.map { calendar.startOfDay(for: $0.date) }.sorted()
                let span = calendar.dateComponents([.day], from: days.first!, to: days.last!).day ?? 0
                guard span >= 28 else { return nil }
                let maxGap = zip(days, days.dropFirst())
                    .map { calendar.dateComponents([.day], from: $0, to: $1).day ?? 0 }
                    .max() ?? 0
                return (crop, cropEntries.count, Double(maxGap) / Double(span))
            }
        guard let best = candidates
            .sorted(by: { $0.ratio == $1.ratio ? $0.crop < $1.crop : $0.ratio < $1.ratio })
            .first, best.ratio <= 0.35
        else { return nil }
        return .steadyProducer(crop: best.crop, pickings: best.pickings)
    }

    /// Crop with the most distinct non-empty logged variants (≥ 2).
    static func varietyCollector(in entries: [HarvestEntry]) -> InsightFact? {
        let variantCounts = Dictionary(grouping: entries, by: \.cropName)
            .mapValues { cropEntries in
                Set(cropEntries.compactMap { $0.variant }.filter { !$0.isEmpty }).count
            }
        guard let collector = variantCounts
            .sorted(by: { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value })
            .first, collector.value >= 2
        else { return nil }
        return .varietyCollector(crop: collector.key, variantCount: collector.value)
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: PASS (18 tests)

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/InsightFacts.swift GardenHarvestTests/InsightFactsTests.swift
git commit -m "Add busiest-day, steady-producer, and variety-collector facts"
```

---

### Task 5: `topFacts` selection

**Files:**
- Modify: `GardenHarvest/Services/InsightFacts.swift`
- Test: `GardenHarvestTests/InsightFactsTests.swift`

- [ ] **Step 1: Write the failing tests** (append inside `InsightFactsTests`)

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: FAIL — no member `topFacts`.

- [ ] **Step 3: Implement** (append inside `enum InsightFacts`)

```swift
    /// The season's insight cards: every triggered extractor in
    /// interestingness priority order, capped at five.
    static func topFacts(in entries: [HarvestEntry], calendar: Calendar = .current) -> [InsightFact] {
        let extracted: [InsightFact?] = [
            frequencyWeightSplit(in: entries),
            marathonCrop(in: entries, calendar: calendar),
            seasonTimingOutlier(in: entries, calendar: calendar),
            busiestDay(in: entries, calendar: calendar),
            steadyProducer(in: entries, calendar: calendar),
            varietyCollector(in: entries),
            oneDayWonder(in: entries)
        ]
        return Array(extracted.compactMap { $0 }.prefix(5))
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: PASS (21 tests)

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/InsightFacts.swift GardenHarvestTests/InsightFactsTests.swift
git commit -m "Add prioritized topFacts selection for insight cards"
```

---

### Task 6: `Insight`, composer protocol, and `TemplateComposer`

**Files:**
- Modify: `GardenHarvest/Services/InsightComposer.swift`
- Test: `GardenHarvestTests/TemplateComposerTests.swift`

- [ ] **Step 1: Write the failing tests**

Replace `GardenHarvestTests/TemplateComposerTests.swift` with:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/TemplateComposerTests 2>&1 | tail -30`
Expected: FAIL — `TemplateComposer` / `Insight` not defined.

- [ ] **Step 3: Implement**

Replace `GardenHarvest/Services/InsightComposer.swift` with:

```swift
import Foundation

/// One composed insight card: the sentence, the fact kind it came from, and
/// the crop whose icon/color the card shows (nil → generic sparkle card).
struct Insight: Codable, Equatable {
    let kind: String
    let text: String
    let cropName: String?
}

/// Turns extracted facts into card sentences. Two implementations: templates
/// (always available, instant) and the on-device Apple Intelligence model.
protocol InsightComposer {
    func compose(facts: [InsightFact], season: Int) -> [Insight]
}

/// Hand-written whimsical wording, seeded by season + fact kind so the pick
/// is stable across views but varies year to year.
struct TemplateComposer: InsightComposer {
    func compose(facts: [InsightFact], season: Int) -> [Insight] {
        facts.map { fact in
            Insight(kind: fact.kind, text: text(for: fact, season: season),
                    cropName: fact.primaryCrop)
        }
    }

    private func text(for fact: InsightFact, season: Int) -> String {
        let variants = templates(for: fact)
        return variants[abs(season &* 7 &+ fact.kind.count) % variants.count]
    }

    private func templates(for fact: InsightFact) -> [String] {
        switch fact {
        case .frequencyWeightSplit(let mostPicked, let heaviest):
            return [
                "Most trips to the garden ended with \(mostPicked.lowercased()) in hand — but it was the \(heaviest.lowercased()) quietly tipping the scales.",
                "\(mostPicked) won on sheer number of pickings; \(heaviest.lowercased()) won the weigh-in."
            ]
        case .marathonCrop(let crop, _):
            return [
                "The long-haul award goes to \(crop.lowercased()) — first to show up, still going at the finish.",
                "\(crop) just kept giving, stretching across more of the season than anything else."
            ]
        case .lateBloomer(let crop):
            return [
                "\(crop) took the scenic route, saving their best for the tail end of the season.",
                "While the rest of the garden wound down, \(crop.lowercased()) were just warming up."
            ]
        case .earlyBird(let crop):
            return [
                "\(crop) beat everyone out of the gate this season.",
                "The season opened with \(crop.lowercased()) leading the charge."
            ]
        case .busiestDay(let date, let crops):
            let label = ReportStats.monthDayLabel(date)
            return [
                "\(label) was peak garden chaos — \(crops.count) different crops in one glorious haul.",
                "Circle \(label) on the calendar: \(crops.count) crops picked in a single day."
            ]
        case .steadyProducer(let crop, _):
            return [
                "No drama, no dry spells: \(crop.lowercased()) were your steadiest producer.",
                "\(crop) showed up again and again — the most dependable member of the patch."
            ]
        case .varietyCollector(let crop, let variantCount):
            return [
                "You didn't just grow \(crop.lowercased()) — you collected them, \(variantCount) varieties strong.",
                "\(crop) came in \(variantCount) different varieties this season. A true connoisseur move."
            ]
        case .oneDayWonder(let crop):
            return [
                "\(crop) made exactly one appearance — blink and you missed it.",
                "A single, glorious picking of \(crop.lowercased()). Some legends only need one day."
            ]
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/TemplateComposerTests 2>&1 | tail -30`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/InsightComposer.swift GardenHarvestTests/TemplateComposerTests.swift
git commit -m "Add Insight model, composer protocol, and template composer"
```

---

### Task 7: `InsightStore` — fingerprint and cache

**Files:**
- Modify: `GardenHarvest/Services/InsightStore.swift`
- Test: `GardenHarvestTests/InsightStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

Replace `GardenHarvestTests/InsightStoreTests.swift` with:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightStoreTests 2>&1 | tail -30`
Expected: FAIL — `InsightStore` has no member `fingerprint` / `Cached`.

- [ ] **Step 3: Implement**

Replace `GardenHarvest/Services/InsightStore.swift` with:

```swift
import Foundation

/// Per-season insight cache in UserDefaults. Keyed by a fingerprint of the
/// season's entries so any add / edit / delete invalidates the cache — the
/// deck regenerates whenever the data changes, never on a timer.
enum InsightStore {
    struct Cached: Codable, Equatable {
        let fingerprint: String
        let insights: [Insight]
        /// True once the on-device model has reworded the templates, so we
        /// don't re-run generation for unchanged data.
        let aiComposed: Bool
    }

    /// Order-independent FNV-1a hash over every entry's crop, ounces, and
    /// date, so moving weight between crops or editing a date invalidates
    /// even when count and grand total stay the same.
    static func fingerprint(of entries: [HarvestEntry]) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        let lines = entries
            .map { "\($0.cropName)|\($0.ounces)|\($0.date.timeIntervalSince1970)" }
            .sorted()
        for line in lines {
            for byte in line.utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x100000001b3
            }
            hash ^= 0x0A
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }

    static func load(season: Int, defaults: UserDefaults = .standard) -> Cached? {
        guard let data = defaults.data(forKey: key(for: season)) else { return nil }
        return try? JSONDecoder().decode(Cached.self, from: data)
    }

    static func save(_ cached: Cached, season: Int, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: key(for: season))
    }

    private static func key(for season: Int) -> String {
        "insights.season.\(season)"
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightStoreTests 2>&1 | tail -30`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/InsightStore.swift GardenHarvestTests/InsightStoreTests.swift
git commit -m "Add fingerprinted per-season insight cache"
```

---

### Task 8: Fact prompt lines + `FoundationModelComposer`

The FoundationModels call itself can't run in unit tests (needs an Apple Intelligence device); keep it thin and test the prompt lines that feed it.

**Files:**
- Modify: `GardenHarvest/Services/InsightFacts.swift` (add `promptLine`)
- Modify: `GardenHarvest/Services/FoundationModelComposer.swift`
- Test: `GardenHarvestTests/InsightFactsTests.swift`

- [ ] **Step 1: Write the failing tests** (append inside `InsightFactsTests`)

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: FAIL — no member `promptLine`.

- [ ] **Step 3: Implement `promptLine`** (append inside `extension`-free `enum InsightFact` body, or as an extension at the bottom of `InsightFacts.swift`)

```swift
extension InsightFact {
    /// Plain-English statement of the fact, fed verbatim to the on-device
    /// model so it rewords exactly this and nothing more.
    var promptLine: String {
        switch self {
        case .frequencyWeightSplit(let mostPicked, let heaviest):
            return "The gardener picked \(mostPicked) more often than any other crop, but \(heaviest) weighed the most in total."
        case .marathonCrop(let crop, let spanDays):
            return "\(crop) had the longest harvest run, spanning about \(spanDays) days from first picking to last."
        case .lateBloomer(let crop):
            return "\(crop) produced mostly at the very end of the season, later than every other crop."
        case .earlyBird(let crop):
            return "\(crop) produced at the very start of the season, earlier than every other crop."
        case .busiestDay(let date, let crops):
            return "The busiest day was \(ReportStats.monthDayLabel(date)), when \(crops.count) different crops were picked: \(crops.joined(separator: ", "))."
        case .steadyProducer(let crop, let pickings):
            return "\(crop) was the steadiest producer, with \(pickings) pickings spread evenly with no long dry spells."
        case .varietyCollector(let crop, let variantCount):
            return "The gardener grew \(variantCount) different varieties of \(crop), more than any other crop."
        case .oneDayWonder(let crop):
            return "\(crop) was picked exactly once all season."
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/InsightFactsTests 2>&1 | tail -30`
Expected: PASS (22 tests)

- [ ] **Step 5: Implement `FoundationModelComposer`**

Replace `GardenHarvest/Services/FoundationModelComposer.swift` with:

```swift
import Foundation
import FoundationModels

/// Rewords extracted facts with the on-device Apple Intelligence model.
/// Availability is double-gated: `#available(iOS 26, *)` at call sites plus
/// the runtime model check (absent on non-eligible devices, when Apple
/// Intelligence is off, or while the model downloads). Any failure returns
/// nil and the caller keeps template wording — never a user-facing error.
@available(iOS 26.0, *)
enum FoundationModelComposer {
    @Generable
    struct Wordings {
        @Guide(description: "Exactly one short, playful sentence per fact, in the same order the facts were given.")
        let sentences: [String]
    }

    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    static func compose(facts: [InsightFact], season: Int) async -> [Insight]? {
        guard isAvailable, !facts.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: """
            You write one-sentence insights for a home gardener's \(season) \
            year-in-review. Tone: warm, playful, a little whimsical. Write \
            exactly one sentence per fact, in the order given. Use only the \
            facts provided. Never invent numbers, weights, percentages, or \
            comparisons that are not stated in the fact.
            """)
        let prompt = "Reword each of these harvest facts as one fun sentence:\n"
            + facts.enumerated()
                .map { "\($0.offset + 1). \($0.element.promptLine)" }
                .joined(separator: "\n")
        guard let response = try? await session.respond(to: prompt, generating: Wordings.self),
              response.content.sentences.count == facts.count
        else { return nil }
        return zip(facts, response.content.sentences).map { fact, sentence in
            Insight(kind: fact.kind, text: sentence, cropName: fact.primaryCrop)
        }
    }
}
```

- [ ] **Step 6: Build to verify the gated code compiles**

Run: `xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`
Expected: `BUILD SUCCEEDED`. (If the `respond(to:generating:)` label differs in the installed SDK, check `xcrun --show-sdk-path` docs via autocomplete and adjust the call — the shape is one respond call returning a typed `Wordings`.)

- [ ] **Step 7: Commit**

```bash
git add GardenHarvest/Services/InsightFacts.swift GardenHarvest/Services/FoundationModelComposer.swift GardenHarvestTests/InsightFactsTests.swift
git commit -m "Add fact prompt lines and FoundationModels composer (iOS 26 gated)"
```

---

### Task 9: `InsightDeck` UI

**Files:**
- Modify: `GardenHarvest/Views/Report/InsightDeck.swift`

No unit tests for pure SwiftUI layout; the existing codebase doesn't snapshot-test views. Verified by build + manual check in Task 10.

- [ ] **Step 1: Implement the deck**

Replace `GardenHarvest/Views/Report/InsightDeck.swift` with:

```swift
import SwiftUI

/// Swipeable deck of season insight cards: crop-tinted backgrounds, the
/// crop's icon plate (sparkle for multi-crop facts), springy scale on page
/// change, and index dots. Replaces the old AIInsightCard placeholder.
struct InsightDeck: View {
    let insights: [Insight]
    /// Resolves a crop's display color, matching the rest of the report.
    let colorHex: (String) -> String

    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            TabView(selection: $page) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    card(insight)
                        .scaleEffect(page == index ? 1 : 0.9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: page)
                        .padding(.horizontal, 2)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 132)
            if insights.count > 1 {
                dots
            }
        }
        .onChange(of: insights.count) { page = 0 }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Text("✦")
                .font(Theme.Font.body(14, weight: .heavy))
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text("AI Insight")
                .font(Theme.Font.body(11, weight: .heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
        }
    }

    private func card(_ insight: Insight) -> some View {
        let tint = insight.cropName.map { Color(hex: colorHex($0)) } ?? Theme.accent
        return HStack(spacing: 14) {
            if let crop = insight.cropName {
                CropIconPlate(
                    cropName: crop,
                    colorHex: colorHex(crop),
                    plateSize: 52,
                    iconSize: 38,
                    discSize: 42
                )
            } else {
                Text("✦")
                    .font(Theme.Font.body(24, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 52, height: 52)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            Text(insight.text)
                .font(Theme.Font.body(14.5, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            ZStack {
                Theme.card
                tint.opacity(0.14)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .animation(.easeInOut(duration: 0.3), value: insight.text)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(insights.indices, id: \.self) { index in
                Circle()
                    .fill(page == index ? Theme.accent : Theme.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add GardenHarvest/Views/Report/InsightDeck.swift
git commit -m "Add swipeable InsightDeck with crop-tinted cards"
```

---

### Task 10: Wire into `ReportView`, delete the placeholder, full verification

**Files:**
- Modify: `GardenHarvest/Views/Report/ReportView.swift`
- Delete: `GardenHarvest/Views/Report/AIInsightCard.swift`
- Modify: `GardenHarvest.xcodeproj/project.pbxproj` (remove the 4 AIInsightCard lines)

- [ ] **Step 1: Wire the deck into ReportView**

In `GardenHarvest/Views/Report/ReportView.swift`:

Add state below `@State private var season = DateProvider.currentYear`:

```swift
    /// Insight cards for the current season: instant template wording,
    /// upgraded in place by the on-device model when available. Regenerated
    /// whenever the season's entries change (see insightKey).
    @State private var insights: [Insight] = []
```

Replace the `AIInsightCard()` line in `body` with:

```swift
                if !insights.isEmpty {
                    InsightDeck(insights: insights, colorHex: colorHex(for:))
                        .id(season)
                }
```

Add after `.fullScreenCover(...)` on the ScrollView:

```swift
        .task(id: insightKey) { await refreshInsights() }
```

Add these members (e.g. after `toggleCrop`):

```swift
    /// Changes whenever the viewed season or its data changes, driving
    /// .task(id:) so insights regenerate mid-season as new harvests land.
    private var insightKey: String {
        "\(season)|\(InsightStore.fingerprint(of: seasonEntries))"
    }

    @MainActor
    private func refreshInsights() async {
        let entries = seasonEntries
        let facts = InsightFacts.topFacts(in: entries)
        guard !facts.isEmpty else {
            insights = []
            return
        }
        let fingerprint = InsightStore.fingerprint(of: entries)

        if let cached = InsightStore.load(season: season), cached.fingerprint == fingerprint {
            insights = cached.insights
            if cached.aiComposed { return }
        } else {
            insights = TemplateComposer().compose(facts: facts, season: season)
            InsightStore.save(
                .init(fingerprint: fingerprint, insights: insights, aiComposed: false),
                season: season
            )
        }

        if #available(iOS 26.0, *), FoundationModelComposer.isAvailable {
            guard let ai = await FoundationModelComposer.compose(facts: facts, season: season),
                  fingerprint == InsightStore.fingerprint(of: seasonEntries)
            else { return }
            withAnimation(.easeInOut(duration: 0.3)) { insights = ai }
            InsightStore.save(
                .init(fingerprint: fingerprint, insights: ai, aiComposed: true),
                season: season
            )
        }
    }
```

Also update the file's doc comment: change `an AI-insight placeholder` to `the AI insight deck`.

- [ ] **Step 2: Delete the placeholder**

```bash
rm GardenHarvest/Views/Report/AIInsightCard.swift
```

Remove all four `AIInsightCard` lines from `GardenHarvest.xcodeproj/project.pbxproj` (IDs `1A7C440BD90FE231AC64B00D` and `2B8D551CE00FE231AC64C00D` — one PBXBuildFile line, one PBXFileReference line, one Report-group child line, one Sources-phase line).

- [ ] **Step 3: Run the full test suite**

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -30`
Expected: `TEST SUCCEEDED` — all suites, including the pre-existing ones.

- [ ] **Step 4: Manual verification in the simulator**

Launch the app in the iPhone 17 Pro simulator, open the Report tab, and verify:
- The insight deck appears below "When it peaked" with template wording (the simulator has no Apple Intelligence model, so templates are the expected wording).
- Cards swipe horizontally with the spring scale animation; dots track the page.
- Crop cards show the crop icon and tint; the busiest-day card (if present) shows the sparkle.
- Log a new harvest entry, return to Report: the deck regenerates (fingerprint change).
- Step to an empty season with the year stepper: the deck disappears.
- FoundationModels wording can only be verified on a physical Apple Intelligence device (iPhone 15 Pro+ with Apple Intelligence enabled) — note this for the user rather than blocking on it.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Views/Report/ReportView.swift GardenHarvest.xcodeproj/project.pbxproj
git rm --cached GardenHarvest/Views/Report/AIInsightCard.swift 2>/dev/null || true
git add -A GardenHarvest/Views/Report
git commit -m "Replace AI insight placeholder with live insight deck"
```

---

## Self-Review Notes

- Spec coverage: fact extraction (Tasks 2–5), template + protocol (Task 6), cache/fingerprint (Task 7), FoundationModels composer (Task 8), deck UI (Task 9), wiring + placeholder removal + empty-state behavior (Task 10). All spec sections have tasks.
- The `respond(to:generating:)` call in Task 8 is the one step that may need a small signature adjustment against the installed Xcode SDK; the guard-and-nil error handling around it is SDK-independent.
- `TemplateComposer.text(for:season:)` seeds with `fact.kind.count`, which collides for kinds of equal length — acceptable: the seed only picks between 2 whimsical variants and stability is what's tested.
```
