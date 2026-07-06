# Harvest Note Import — Design

Date: 2026-07-06
Status: Approved

## Goal

Bulk-import harvest entries from Katie's Apple Note (the `harvets.txt`
format), pasted as text or picked as a `.txt` file, deduplicating against
entries already in the store so re-importing a grown copy of the same note is
safe and idempotent. Entry point: the Log tab.

## The note format (observed in `harvets.txt`)

```
Garden Harvest 2026:

March:
Asparagus, 18oz                      ← undated (month heading is the context)
Mushrooms, 8oz

April:
Asparagus, 31oz (4/7)                ← (M/D) day marker
Asparagus, 22oz, 14oz some woody (4/13)   ← second weight WITH text → note
...
Strawberries, 1 oz (5/9-10)          ← date range → first day
Blueberries 2oz (6/4)                ← comma optional
Raspberries, small 7.6 oz (6/11)     ← variant word before the amount
Artichokes 9oz, 11.5 oz (6/9)        ← two bare weights → two entries
Tomatoes Cherry, 0.63 (6/23)         ← missing "oz"
Strawberries  5 oz (6/15)            ← stray double spaces
```

Rules locked in with Blake:
- **Multi-weight lines:** the first weight is the amount. Each additional
  *bare* weight ("9oz, 11.5 oz") becomes its own entry on the same day; a
  trailing weight *with text* ("14oz some woody") becomes the note verbatim.
- **Undated lines** get the 15th of their month and are flagged in preview.
- **Year** comes from the header ("Garden Harvest 2026"); if absent, the
  import sheet shows a year picker defaulting to the current season.
- **Crop-name drift:** names match existing crops case-insensitively and
  ignoring a trailing "s" ("Artichokes" → "Artichoke"). Unmatched names
  create a new `Crop` (color via `CropColorAssigner`, sortIndex appended).
- **Variants:** a descriptor word between crop and amount ("small", "large")
  is the entry's variant; if the matched crop doesn't list it yet it is
  appended to `crop.variants`.
- Unparseable lines are never guessed at — they are listed in the preview.
- Month headings and the header line are recognized in English ("March:" …
  "December:"), matching how the note is written.

## Deduplication

An incoming entry is a **duplicate** (skipped) when an existing entry
matches all of: normalized crop name, same calendar day, same ounces
(±0.001), same variant (nil == nil). Undated incoming entries instead match
on crop + ounces + same *month* — the seeded March asparagus lives on 3/10,
and Katie's undated original must not import as a second entry.

Matching is multiset-aware: each existing entry can absorb only one incoming
duplicate, so two genuinely identical pickings in the note import as two
entries when only one exists. Duplicates *within* the pasted note follow the
same rule against each other plus the store.

## Architecture

```
pasted text / .txt file
        │
        ▼
HarvestNoteParser (pure)      — text → ParsedNote { year, entries, issues }
        │
        ▼
NoteImportService (pure core) — plan(parsed, existingEntries, existingCrops)
        │                        → ImportPlan { new, duplicates, newCrops,
        ▼                                       newVariants }
ImportSheet (UI)              — paste box + file picker → preview → commit
```

- **`HarvestNoteParser`** (`GardenHarvest/Services/HarvestNoteParser.swift`):
  pure text parsing, no SwiftData. Produces value types:
  `ParsedEntry { crop, ounces, month, day?, variant?, note }` plus
  `issues: [String]` (line + reason for anything skipped).
- **`NoteImportService`** (`GardenHarvest/Services/NoteImportService.swift`):
  pure planning function taking parsed entries + existing `[HarvestEntry]` /
  `[Crop]` snapshots, returning the `ImportPlan`; plus a small
  `apply(plan:context:)` that inserts entries, creates crops, appends
  variants, and saves. Only `apply` touches SwiftData.
- **`ImportSheet`** (`GardenHarvest/Views/Log/ImportSheet.swift`): sheet with
  a paste `TextEditor`, a "Choose file" button (`.fileImporter`, `.txt`),
  year picker when the header year is missing, then the preview list
  (import count, per-crop breakdown, skipped duplicates count, new crops,
  flagged undated/noted lines, unparseable lines) and the Import button.
  Entry point: an "Import" toolbar-style button on the Log page header.

## Error handling

- Empty/garbage input → preview shows zero importable entries and the issue
  list; Import button disabled.
- File that can't be read as UTF-8 → inline error in the sheet.
- Import applies in one save; any thrown error leaves the store untouched
  and surfaces an alert.

## Testing

- `HarvestNoteParserTests` — every quirk above gets a case: dated, undated,
  range, comma-less, variant, multi-weight (both meanings), missing oz,
  header year, month sections, junk lines → issues.
  **Golden test:** parsing the full `harvets.txt` content reproduces the
  `SeedDataService.rawData` entry set (modulo the two documented
  transcription differences: the summed 4/13 asparagus and the hand-picked
  March days).
- `NoteImportServiceTests` — dedup exact/undated-month rules, multiset
  absorption, new-crop and new-variant detection, idempotent re-import
  (plan against already-imported store yields zero new).
- UI verified by build + simulator.
