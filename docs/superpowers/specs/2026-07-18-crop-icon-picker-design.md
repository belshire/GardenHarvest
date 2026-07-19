# Crop Icon Picker — Design

**Date:** 2026-07-18
**Status:** Approved

## Problem

The app auto-picks a crop icon from the crop name via `CropIconAssigner` (62 built-in
`VegIcons` assets). There is no way to choose a different icon — even though several
icons exist for the same crop family (e.g. radish / white-radish / purple-daikon,
onion / red-onion, four mushroom variants) — and no way to use a custom image.
The icon is derived, never stored: every view resolves it from the crop *name*.

## Goals

- Pick any of the built-in `VegIcons` when adding a crop, or upload a photo from
  the photo library.
- Change the icon of an existing crop.
- The chosen icon appears everywhere the crop is rendered (Home tiles, Log rows,
  Entry picker, Report, filter sheet, share card).
- Existing crops and fresh installs behave exactly as today until a user picks
  an icon (auto-match remains the default).

## Non-goals

- Camera capture or Files-app import (photo library only).
- A cropping/adjustment UI for uploaded photos (center-crop square only).
- Changing crop colors or any other crop attribute.

## Design

### Model

`Crop` gains two optional fields; both `nil` for existing data (SwiftData
lightweight migration, no versioned schema needed):

```swift
var iconAssetName: String?                       // e.g. "VegIcons/red-onion"
@Attribute(.externalStorage) var customIconData: Data?  // uploaded photo, JPEG
```

Resolution precedence, implemented in one place (`CropIconResolver`):

1. `customIconData` → circle-cropped photo
2. `iconAssetName` → that asset
3. `CropIconAssigner.assetName(for: name)` → auto-match (today's behavior)
4. Colored initials disc (today's fallback)

Setting a custom photo clears `iconAssetName` and vice versa ("Auto" clears both).

### Rendering — `CropIconPlate`

`CropIconPlate` gains optional inputs for the stored choice (`customImageData:
Data?` and the existing `assetOverride: String?`), applying the precedence above.
A custom photo renders as a circle-cropped image filling the plate (`scaledToFill`,
clipped to circle), replacing the gradient dish for that case.

Call sites that hold a `Crop` (`CropTileView`, `CropFilterSheet`) pass its stored
fields directly. Name-only call sites (`LogMonthSection`, `LogView`, `EntryView`,
`ReportView`, `ShareCardView`, `InsightDeck`) resolve the `Crop` by name from the
crops list they already have access to (adding a lightweight `@Query`/lookup
dictionary where needed).

### Icon catalog

A static `IconCatalog.allSlugs: [String]` lists every `VegIcons` slug (the 61
crop icons; `cornucopia` excluded — it is the "All crops" symbol). Derived once,
checked by a unit test against the unique values of `CropIconAssigner.iconMap`.

### Picker UI — `IconPickerSheet`

A sheet presenting:

- A search field filtering slugs by name.
- An **Auto** tile — shows what auto-match yields for the crop name; selecting
  clears both overrides.
- An **Upload photo** tile — `PhotosPicker`; the picked image is center-cropped
  square, downscaled to 512×512, JPEG-encoded, and stored in `customIconData`.
- A grid (4 columns) of all built-in icons on the standard plate; the current
  selection is ring-highlighted. Tapping selects and dismisses.

The sheet takes a binding-style callback (`onSelect(IconChoice)`), so it works
for both flows below without touching persistence itself.

### Add flow — `AddCropView`

- The large icon preview becomes a button opening `IconPickerSheet`.
- Selection is held in `@State` (`IconChoice`: `.auto`, `.asset(String)`,
  `.custom(Data)`); the preview and caption reflect it ("Tap to change icon" /
  "Custom icon" instead of "Auto-matched icon").
- On commit, the choice is written to the new `Crop`. If the crop already exists,
  a non-auto choice updates the existing crop's icon fields.

### Edit flow — Home

In Home's existing wiggle edit mode, tapping a tile (currently a no-op) opens
`IconPickerSheet` for that crop; selection writes the fields and saves the
context. Drag-to-reorder is unchanged.

### Error handling

- Photo load/encode failure: keep the previous selection; show no partial state.
- A stored `iconAssetName` that no longer exists in the catalog falls through to
  auto-match (guard via `UIImage(named:)` check in the resolver).

### Testing

- Unit: resolver precedence (custom > asset > auto > initials), mutual exclusion
  of the two override fields, `IconCatalog` completeness vs `iconMap`,
  center-crop/downscale helper output size.
- Manual (simulator): pick each choice type in Add flow; edit an existing crop;
  verify Log/Entry/Report render the override; verify migration by launching on
  a store created before the change.

### Project file

New Swift files are added to `project.pbxproj` **by hand** (never xcodegen).
