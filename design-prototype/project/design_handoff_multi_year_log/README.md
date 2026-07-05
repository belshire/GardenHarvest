# Handoff: Multi-Year Harvest Log (Garden Harvest Tracker)

## Overview
This is the **Log** view for a personal garden harvest-tracking iOS app. The user logs each
picking (crop + weight in oz, with optional note/photo/date). The Log lets them browse every
season they've tracked — stepping between years, drilling into months, filtering to a single
crop, and seeing that crop's yield across all years ("dossier"). This handoff covers the Log
redesign specifically, but the bundled prototype is the whole app so the Log has real context
(Home, quick-log entry, Unwrapped report).

## About the Design Files
The files in this bundle are **design references authored in HTML** — interactive prototypes
that show the intended look and behavior. They are **not production code to copy directly**.
The task is to **recreate these designs in the target codebase's environment** (this app is
iOS — SwiftUI is the natural fit) using its established patterns, components, and data layer.
If no codebase exists yet, pick the most appropriate framework and implement there.

The prototypes are built as "Design Components" (a small custom HTML runtime). Ignore the
runtime mechanics — read them for **layout, styling, data shape, and interaction logic**.

## Fidelity
**High-fidelity.** Colors, typography, spacing, and interactions are final and intentional.
Recreate the UI closely, substituting the codebase's native components where equivalent
(e.g. a native bottom sheet for the crop filter).

---

## Data Model
Each harvest entry:
```
Entry {
  crop: string          // e.g. "Raspberries", "Tomatoes Cherry"
  oz: number            // weight in ounces (source unit; display converts to lb/oz)
  date: string          // ISO "YYYY-MM-DD"
  note: string          // optional; variant + free note joined by " · " e.g. "large · some woody"
  photo: object | null  // optional { source: "Camera" | "Library" }
}
```
The Log operates over the **full multi-year entry list**. "Current season" is a constant
(2026 in the prototype) used by Home/Unwrapped; the Log defaults to it but can browse any year
present in the data. Years are derived from the distinct `date` year values, sorted descending.

**Weight formatting** (`wt`): values ≥ 16 oz render as `"{lb} lb {oz} oz"` (drop the oz part
when it's 0, e.g. `"3 lb"`); below 16 oz render as `"{n} oz"`. Round to 1 decimal; drop a
trailing `.0`.

---

## Screen: Harvest Log (Almanac)

Vertical scroll view. Fixed iOS status bar (9:41) at top, translucent bottom tab bar
(Home / Log / Unwrapped) with Log active. Body padding `8px 20px 96px`, vertical `gap: 12px`.
Pinned (non-scrolling-away) header elements below use `flex-shrink: 0`.

### 1. Year stepper (header)
- Row: `‹` button — centered title block — `›` button. `align-items: center; gap: 10px`.
- Stepper buttons: 44×44 circle, `1px solid` line color, background = card white when enabled /
  transparent when disabled, glyph `‹`/`›` 22px 700. Disabled at the ends of the year range
  (color drops to the line color, cursor default). `‹` = older year, `›` = newer year.
- Center block (centered text): kicker `HARVEST LOG` (DM Mono, 10.5px, 700, uppercase,
  letter-spacing 2px, accent color) above the year `2026` (DM Serif Display, 32px, ink).

### 2. Summary card
- Full-width, background = **accent** `#ff6a4d`, white text, radius 24px, padding `14px 16px`.
- Big total (DM Serif Display, 30px) e.g. `40 lb 2.4 oz`.
- Subline (12.5px, 600, 92% opacity): `"{pickings} pickings · {cropCount} crops"` for the year.

### 3. Crop filter pill
- Full-width button, card white, `1px solid` line, radius 14px, padding `11px 14px`,
  soft shadow, `gap: 9px`.
- Left: 14px dot — solid crop color when a crop is selected, else a diagonal
  `linear-gradient(135deg, #ff6a4d, #4caf50)`.
- Label (14.5px, 700, ink): selected crop name or `"All crops"`.
- Right: caret `⌄` (16px, sub color).
- Tap → opens the **Crop filter sheet** (below).

### 4. Crop dossier — "Across the years" (only when a crop is selected)
- Card (card white, `1px solid` line, radius 24px, padding 14px, `gap: 9px`).
- Head label `ACROSS THE YEARS` (11px, 800, uppercase, letter-spacing 1.2px, sub color).
- One tappable row per year (desc): year label (44px wide, DM Mono 14px; **active year** =
  accent color + 800 weight, others ink) — progress track (flex, 14px tall, line-colored
  track, radius 999) with a fill bar in the **crop's color** sized to `value / maxYearValue` —
  value label (76px, right-aligned, DM Mono 12.5px 800; `"—"` when 0).
- Active year row has a faint accent wash background `rgba(255,106,77,.10)`.
- Tapping a year row sets the Log's active year (updates everything, including the day list
  below).
- Below the card: section label `"{Crop} in {year}"` (same style as head label).

### 5. Months (collapsible) — the day list
Rendered for the active year, filtered to the selected crop if any. Months in **descending**
order. Each month:
- **Header button** (card white, `1px solid` line, radius 14px, padding `12px 14px`,
  soft shadow, `margin-top: 8px`, full width): month name (DM Serif Display, 18px, fixed
  96px width, left) — thin progress bar (flex, 8px tall, `margin: 0 12px`, fill = **accent2**
  `#4caf50`, sized to `monthTotal / maxMonthTotal`) — month total (DM Mono 12px 700, accent) —
  chevron `›` (18px, sub) that rotates 90° when expanded (`transition: transform .15s`).
- Tap toggles expansion. Default: the current season's peak month is expanded
  (`2026-6` / June in the prototype).
- **Expanded body**: for each day (desc), a day label then its picking rows.
  - Day label (DM Mono 11px 800 uppercase, letter-spacing 1px, sub color, `margin-top: 8px`):
    `"{Weekday} {Mon} {D}"` e.g. `SAT JUN 27`.
  - Picking row (`align-items: center; gap: 12px; padding: 9px 0; border-bottom: 1px solid line`):
    - Crop disc: 34px circle, background = crop color, white 2-letter initials
      (DM Mono, 700), subtle `inset 0 -3px 8px rgba(0,0,0,.12)`.
    - Middle (flex): crop name (DM Serif Display, 14.5px, 700, ink); optional note beneath
      (11.5px, italic, sub color).
    - Optional photo thumb (34px, radius 9px, hatched placeholder with "IMG" tag) when a photo
      is attached.
    - Weight (DM Mono, 14px, 800, ink) e.g. `12 oz`.
- Empty state (no entries for the year/filter): centered italic sub-color text,
  e.g. `"No Raspberries logged in 2025"` or `"Nothing logged in 2024 yet"`.

### Crop filter sheet (bottom sheet)
- Scrim `rgba(0,0,0,.35)` over the screen; tap to dismiss.
- Sheet pinned near the bottom (`left/right: 10px; bottom: 14px`), white, radius 18px,
  `max-height: 62%`, drop shadow, internal scroll.
- Title `FILTER BY CROP` (12px, 800, uppercase, letter-spacing 1.2px, sub, bottom divider).
- First item `All crops` (gradient dot, `∗` glyph) clears the filter; then every crop that
  appears in **any** year, sorted by all-time total descending. Each row: 30px disc — name
  (15px, 700) — all-time total (DM Mono 12.5px 700, sub, right). Selected row has the accent
  wash background.
- Selecting a crop sets the filter and closes the sheet (keeps the current year).

---

## Interactions & Behavior
- **Year stepping**: `‹` older / `›` newer, clamped to the available year range; disabled
  buttons at the extremes.
- **Crop filter persists across year changes** — this is intentional so the user can compare
  the same crop year to year. Tapping a year in the dossier switches the active year while
  keeping the crop.
- **Month expand/collapse** is per `year-month` key, independent state.
- **Opening the app on the Log** defaults to the current season, current-season peak month
  expanded, no crop filter.
- Transitions: chevron rotation `.15s`; the bottom sheet slides up (use the platform's native
  sheet presentation).

## State
```
logYear: number                 // active year in the Log
logCrop: string | null          // active crop filter (null = All crops)
expandedMonths: { [ "YYYY-M" ]: boolean }   // which month sections are open
cropSheetOpen: boolean
```
Derived per render: years list (desc), year-scoped entries, per-crop all-time totals (for the
sheet), per-year totals for the selected crop (for the dossier), month/day groupings.

## Design Tokens
- **Accent (primary)** `#ff6a4d` · on-accent text `#ffffff`
- **Accent 2 (green)** `#4caf50` — month bars, positive deltas
- **Ink (text)** `#22381c` · **Sub (muted)** `#6a8560`
- **Card** `#ffffff` · **Panel bg** `linear-gradient(180deg,#f0f8e8,#e2f2d3)`
- **Hairline** `rgba(34,56,28,.10)` (borders/tracks) · **accent wash** `rgba(255,106,77,.10)`
- **Crop colors**: Asparagus `#5a9a3d` · Strawberries `#e8434a` · Raspberries `#c02f66` ·
  Blueberries `#3f6ad0` · Boysenberries `#6f3fa8` · Artichoke `#7f9a4e` · Radishes `#e05583` ·
  Peas `#8cbf4f` · Mushrooms `#b08a63` · Tomatoes Cherry `#ef4f34`. Unknown crops: derive a
  stable hue from the name hash (`hsl(hash%360, 50%, 52%)`).
- **Radii**: cards 24px · pills/rows 14px · sheet 18px · discs/tracks 999px
- **Type**: Headings **DM Serif Display**; body/UI **Nunito Sans**; numerals/labels **DM Mono**
- **Shadow (soft)** `0 6px 18px rgba(30,50,20,.08)` · **sheet** `0 16px 48px rgba(0,0,0,.34)`
- **Spacing**: body gap 12px; row padding 9px 0; card padding 14–16px

## Assets
- No raster assets. Crop icons are colored discs with letter initials (placeholders for future
  custom illustrations). Photo thumbnails are hatched placeholders labeled "IMG" — wire to real
  photo attachments in the app.
- Fonts via Google Fonts (DM Serif Display, Nunito Sans, DM Mono) — swap to bundled/native
  equivalents as the codebase prefers.

## Files
- `Garden Harvest App.dc.html` — the full single-screen prototype (Home, Entry, **Log**,
  Unwrapped, Add). This is the primary reference; the Log logic lives here + in GardenPhone.
- `GardenPhone.dc.html` — the phone UI component. The Log screen markup is under the
  `isLog` block; the Almanac logic is the "multi-year Almanac log" section of `renderVals`.
- `Log View.dc.html` — the exploration that produced this direction. Contains **Direction B
  (Almanac)** — chosen — and **Direction A (Feed)** for context. Reference only.
- `support.js` — prototype runtime. Not part of the design; do not port.

### How to view the prototypes
Open `Garden Harvest App.dc.html` in a browser. Tap the **Log** tab. Step years with `‹`/`›`,
open the crop pill to filter, tap a month header to expand, and (with a crop selected) tap a
year in the dossier to jump.
