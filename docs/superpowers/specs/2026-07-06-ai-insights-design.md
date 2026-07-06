# AI Insights for the Harvest Report — Design

Date: 2026-07-06
Status: Approved

## Goal

Replace the `AIInsightCard` placeholder on the Report tab with real, personalized,
**qualitative** insights about the selected season's harvest — e.g. "You picked
strawberries most often, but your asparagus out-weighed them pound for pound."
Wording is generated on-device with Apple Intelligence (FoundationModels, iOS 26)
when available, with a hand-written template fallback everywhere else.

Explicit non-goal: quantitative/statistical comparisons ("your harvest is 20%
bigger than last year"). No percentages, no year-over-year math in insight text.

## Architecture

Three layers, facts-first: deterministic code decides *what* is interesting; the
model (or templates) only decides *how to say it*. This prevents hallucinated
numbers and keeps the AI and non-AI experiences structurally identical.

```
[HarvestEntry] season entries
        │
        ▼
InsightFacts (pure service)        — extracts typed InsightFact values
        │
        ▼
InsightComposer (protocol)
  ├─ TemplateComposer              — always available, instant
  └─ FoundationModelComposer      — iOS 26 + Apple Intelligence available
        │
        ▼
[Insight] { kind, text, cropName? } → cached → InsightDeck (UI)
```

### 1. Fact extraction — `GardenHarvest/Services/InsightFacts.swift`

Pure functions over a season's `[HarvestEntry]` (reusing `LogGrouping` /
`ReportStats` helpers where they fit). Emits `InsightFact` values, each tagged
with the crop name(s) involved. Fact kinds, in interestingness priority order:

1. **Frequency vs. weight split** — the most-picked crop (by picking count)
   differs from the heaviest crop (by total ounces). Only emitted when they
   actually differ.
2. **Marathon crop** — longest span from first to last picking (≥ 2 pickings,
   span ≥ 30 days).
3. **Late bloomer / early bird** — crop whose pickings skew latest (or
   earliest) relative to the season's span.
4. **Busiest picking day** — the single date with the most distinct crops
   picked (≥ 3 crops).
5. **Steady producer** — crop with ≥ 5 pickings spread most evenly across its
   span.
6. **Variety collector** — crop with the most distinct logged `variant`
   values (≥ 2).
7. **One-day wonder** — a crop picked exactly once all season.

Each extractor returns `nil` when its threshold isn't met. The top 3–5
non-nil facts (priority order) become cards. Zero facts (e.g. a season with a
single entry) → no deck is shown.

`InsightFact` carries structured payload (crop names, dates, counts) so
composers can phrase it, but composers must not surface raw numbers beyond
what's naturally qualitative ("a dozen pickings" is fine; "37.5 oz" is not —
weights already live elsewhere on the report page).

### 2. Wording — `InsightComposer` protocol, two implementations

`GardenHarvest/Services/InsightComposer.swift` (+ `FoundationModelComposer.swift`):

- **`TemplateComposer`** — 2–3 hand-written whimsical sentence variants per
  fact kind, matching the app's "harvest unwrapped" tone (cf.
  `ReportStats.superlativeTitles`). Variant chosen by a stable seed
  (season + fact kind) so wording doesn't churn on every view. Synchronous,
  used on all devices as the instant/base wording and as the permanent
  wording when AI is unavailable.
- **`FoundationModelComposer`** — gated behind `#available(iOS 26, *)` and a
  runtime `SystemLanguageModel.default.availability == .available` check
  (model absent on non-eligible devices, when Apple Intelligence is off, or
  mid-download). One `LanguageModelSession` request per generation covering
  all selected facts at once. Guided generation via an `@Generable` response
  struct: an array of short insight strings, one per fact, in order.
  Session instructions: playful gardener tone, one sentence per insight, no
  percentages, no invented numbers, no facts beyond those provided. Any
  error / timeout → keep template wording silently.

Because the deployment target is iOS 17, all FoundationModels imports and
types are isolated in files/paths compiled behind availability checks.

### 3. Caching & refresh — `InsightStore`

- Cache in `UserDefaults` keyed per season: the composed `[Insight]` plus a
  **fingerprint** of the season's entries (entry count + total ounces + max
  entry date).
- On report view for a season: if fingerprint matches, show cached insights.
  If not (new/edited harvests — the mid-season staleness concern): recompute
  facts, show template wording immediately, kick off AI rewording as a
  background `Task`, swap the deck's text in-place when it lands, update the
  cache.

### 4. UI — `InsightDeck` replaces `AIInsightCard`

`GardenHarvest/Views/Report/InsightDeck.swift`, slotted where
`AIInsightCard()` sits in `ReportView` (`AIInsightCard.swift` is deleted and
removed from `project.pbxproj` — which is edited by hand, never xcodegen).

- Keeps the existing "✦ AI Insight" eyebrow header row.
- Horizontally swipeable paged deck (`TabView` with `.page` style, index dots
  in theme colors), fixed comfortable card height.
- Each card: background tinted with the fact's crop color (via existing
  `Crop.colorHex` / `CropColorAssigner`), the crop's `CropIconPlate` icon —
  or the ✦ sparkle on a `Theme.accent` tint for multi-crop facts — and the
  insight sentence.
- Card switch gets a springy scale-and-tilt transition animation.
- Empty facts → deck (and header) hidden, matching how other report sections
  disappear for empty seasons.
- While AI rewording is in flight there is no spinner — template text is
  already real content; text simply animates to the new wording if/when it
  arrives.

## Error handling

- FoundationModels unavailable (OS, device, setting, download) → templates,
  no user-facing notice.
- Generation failure, guardrail refusal, or mismatched response count →
  discard, keep templates, no retry loop (next fingerprint change retries).
- Corrupt/missing cache → recompute from scratch.

## Amendment (2026-07-06, post-review)

The AI-rewording of template cards proved low-value and is removed. Revised roles:

- **Fact cards are template-only** on every device. The deck header reads
  "Fun Facts" with no icon; the carousel wraps around (sentinel-page
  technique) so swiping past either end loops.
- **The AI's job is a "season story"**: one 2–4 sentence second-person
  narrative generated on-device from the season's fact statements
  (`promptLine`, now phrased as "You picked…") plus any non-empty harvest
  notes ("Jun 14 Strawberries: <note>" lines, capped). No notes → narrate
  from facts alone. It renders in its own section below the deck, labeled
  "The story of the season", and is hidden entirely when Apple Intelligence
  is unavailable or generation fails.
- **Cache**: `InsightStore.Cached` drops `aiComposed` in favor of
  `story: String?`; a nil story retries on next view when the model is
  available, same fingerprint invalidation as before.

## Testing

- `InsightFactsTests` — each extractor: triggering data, threshold-miss data,
  empty season; priority ordering and 3–5 selection.
- `TemplateComposerTests` — every fact kind produces non-empty text; seed
  stability (same season → same wording).
- `InsightStoreTests` — fingerprint change detection, cache round-trip.
- `FoundationModelComposer` — thin, availability-gated; verified manually on
  an Apple Intelligence device/simulator (not unit tested).
