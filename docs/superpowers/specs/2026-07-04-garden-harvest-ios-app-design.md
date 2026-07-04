# Garden Harvest — iOS App Design

## Source material

This app is being built from a Claude Design handoff bundle (`Garden harvest tracker
app-handoff.zip`, extracted to the scratchpad during design review). The bundle contains
HTML/CSS/JS prototypes ("Design Components") that are pixel-precise references, not code to
port directly:

- `Garden Harvest App.dc.html` — primary reference; root component wiring state/handlers and
  the seed data (`RAW` 2026 harvest string, `gen()` synthetic-history algorithm).
- `GardenPhone.dc.html` — the phone UI; all screen layout, styling, and interaction logic
  (`renderVals()`).
- `design_handoff_multi_year_log/README.md` — detailed prose spec for the Log (Almanac) screen:
  data model, layout, tokens, interactions. Reference only for the Log screen (out of scope
  this pass, see below).
- `Log View.dc.html` — exploration artifact (Direction A/B). Reference only, not implemented.
- `uploads/harvets.txt` (also present at the project root as `harvets.txt`) — the user's real
  2026 harvest log in freeform text; this is the literal source of the `RAW` data baked into
  the prototype.

Design tokens (from the prototype's `theme()`): accent `#ff6a4d`, accent2 `#4caf50`, ink
`#22381c`, sub `#6a8560`, card `#ffffff`, panel `linear-gradient(180deg,#f0f8e8,#e2f2d3)`,
hairline `rgba(34,56,28,.10)`. Fonts: headings **DM Serif Display**, body/UI **Nunito Sans**,
numerals/labels **DM Mono** (via Google Fonts in the prototype — bundle as native app fonts).

## Scope for this pass

Build the **core logging loop**: Home → Entry → Add, backed by a real SwiftData store, with
a working bottom tab bar. Log (Almanac) and Unwrapped (season recap) are present as tabs but
show a simple "Coming soon" placeholder — they are a follow-up pass once the core flow is
verified in daily use.

## Project setup

- Xcode project named `GardenHarvest`, SwiftUI app lifecycle, SwiftData for persistence.
- Bundle identifier: `com.belshire.GardenHarvest`.
- Deployment target: iOS 17.0. Devices: iPhone only. Orientation: portrait only.
- No back-compat shims — use SwiftData, `NavigationStack`, `PhotosPicker`, `@Observable`
  freely as iOS 17+ baseline APIs.

## Data model

```swift
@Model
final class HarvestEntry {
    var cropName: String
    var ounces: Double
    var date: Date
    var note: String            // free-text note only (variant is separate, see below)
    var variant: String?        // e.g. "small" / "large" for crops with variants
    var photoData: Data?
    var photoSource: String?    // "Camera" | "Library"
}

@Model
final class Crop {
    var name: String              // unique
    var colorHex: String          // assigned at creation (explicit or hash-derived)
    var isQuickLog: Bool
    var sortIndex: Int
    var variants: [String]        // e.g. ["small", "large"]; empty = no variant chips
}
```

Rationale for splitting `variant` out of `note`: the prototype joins them into one display
string (`variant · note`), but keeping them as distinct fields is more useful for a real data
store (querying/filtering by variant later) and costs nothing extra.

The master vegetable list (~55 names used for Add-screen autocomplete suggestions) is a
static Swift constant (`MasterCropList.names`), not persisted — it only becomes a `Crop` row
when the user actually adds/selects one.

"Season" = current calendar year (`Calendar.current.component(.year, from: .now)`), replacing
the prototype's hardcoded 2026. All "this season" totals filter `HarvestEntry.date` by year.

## Seed data

On first launch (no existing `Crop`/`HarvestEntry` rows), seed the store with:

1. **Known crops** — the 10 crops with explicit colors/variants in the prototype
   (`Asparagus`, `Strawberries`, `Raspberries`, `Blueberries`, `Boysenberries`, `Artichoke`,
   `Radishes`, `Peas`, `Mushrooms`, `Tomatoes Cherry`), each created as a `Crop` row with its
   prototype color hex; the 8 "quick" ones (`QUICK` list, all but `Mushrooms` and
   `Tomatoes Cherry`) get `isQuickLog = true`. `Raspberries` gets `variants = ["small",
   "large"]`.
2. **Real 2026 entries** — parsed from the prototype's `RAW` string (same data as
   `harvets.txt`), dated into the current year.
3. **Synthetic 2024/2025 history** — ported verbatim from the prototype's `seed(n)` /
   `gen(base, year, scale, drop)` functions (same deterministic pseudo-random formula, same
   scale/drop constants: 2024 → scale 0.62, drop 0.32; 2025 → scale 0.84, drop 0.18) so the
   numbers match what was seen in the prototype, just shifted to `currentYear - 2` /
   `currentYear - 1` instead of hardcoded 2024/2025.

This seeding logic lives in a small `SeedDataService` (or similar), invoked once at app
launch, guarded by an existence check so it never re-seeds/duplicates on subsequent launches.

## Screens

### Home
- Header: kicker ("{season} season · {today's date}") + "What did you pick?" prompt.
- Total card: accent-colored, big total for the season (formatted lb/oz), subtext
  "picked this season across N crops".
- "Quick log — tap to add" section label.
- 3-column grid of quick-log crop tiles (colored initial disc, name, running total or "—"),
  plus a dashed "+ Add veg" tile. Tapping a tile navigates to Entry for that crop.
- Custom bottom bar (translucent blur, 3 items: Home / Log / Unwrapped) using SF Symbols
  (`house.fill`, `list.bullet`, `sparkles`) instead of the prototype's text glyphs — same
  visual weight, more idiomatic for iOS.

### Entry (log a harvest)
- Back button + "LOG HARVEST" title.
- Crop disc + name, centered.
- Big oz display (tap-driven, not a text field) fed by a custom keypad.
- Bump chips: −1 / +0.5 / +1 / +5.
- Variant chips (only rendered if the crop has `variants`), single-select, toggle off on
  re-tap.
- Custom 3-column numeric keypad (1–9, ., 0, ⌫).
- Date chips: Today / Yesterday / 2 days ago (single-select; sets the entry's date).
- Photo button (toggles "＋ Photo" / "✓ Photo") + note text field, side by side.
- Photo preview row when a photo is attached (thumbnail, "Photo attached / From {source}",
  Remove button).
- Save button — disabled state "Enter a weight" while oz is 0, otherwise "Log {oz} oz {crop}".
- On save: toast "🌱 Logged {oz} oz {crop}" on Home, auto-dismissing after ~2.4s.

### Add (new vegetable)
- Back button + "NEW VEGETABLE" title.
- "What did you grow?" label + text field (autofocus).
- Live autocomplete list against `MasterCropList.names` (substring match, case-insensitive,
  capped at 6), each row tagged "grown before" if it matches an existing `Crop`.
- "Add to quick log" row with a toggle switch (default on).
- Commit button — disabled state "Name your vegetable" while empty, otherwise
  "Add {name} & log it". On commit: creates the `Crop` (matching an existing master-list
  name's casing if applicable) and navigates straight to Entry for it.

### Log / Unwrapped tabs
- Placeholder screens only this pass: tab bar item + centered "Coming soon" text matching the
  app's type/color tokens. Full Almanac (Log) and season-recap (Unwrapped) behavior is
  deferred to a follow-up pass, using the existing
  `design_handoff_multi_year_log/README.md` spec and the `isUnwrapped`/`isLog` blocks in
  `GardenPhone.dc.html` as the reference when that pass starts.

### Photo capture
- Tapping the photo button shows a native `confirmationDialog` ("Add a photo of this pick" /
  Take Photo / Choose from Library / Cancel) — more idiomatic than the prototype's custom
  bottom sheet, same intent.
- "Choose from Library" → `PhotosPicker` (PhotosUI), loads the selected image as `Data`.
- "Take Photo" → a `UIImagePickerController` wrapper (`UIViewControllerRepresentable`) for
  camera capture, since there's no pure-SwiftUI camera API on iOS 17.
- Selected image stored as `HarvestEntry.photoData` + `photoSource` ("Camera"/"Library").

## Testing

Unit tests (Swift Testing framework) for pure logic, ported/verified against the prototype's
behavior:

- **Weight formatting** — oz → `"{n} oz"` below 16, `"{lb} lb {oz} oz"` (dropping a zero oz
  part) at/above 16, rounded to 1 decimal with trailing `.0` dropped.
- **Crop color assignment** — explicit hex for known crops, deterministic hash → HSL fallback
  for unknown ones, matching the prototype's `cc()` hash formula.
- **Date-chip shifting** — Today/Yesterday/2-days-ago resolve to the correct calendar dates.
- **Seed data generation** — the ported `seed()`/`gen()` functions reproduce the same
  relative scaling/jitter/date-shift behavior as the prototype (deterministic given the same
  inputs).

No XCUITest suite this pass — manual verification of the Home → Entry → Save and Home → Add →
Entry flows in the iOS Simulator, given the scope of a personal-use app.
