# Crop Icon Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users pick any built-in VegIcons icon or a photo-library image for a crop (add + edit flows), persisted on the `Crop` model and rendered everywhere the crop appears.

**Architecture:** Two optional override fields on `Crop` (`iconAssetName`, `customIconData`); a pure `CropIconResolver` implements precedence custom photo → picked asset → auto-match → initials; `CropIconPlate` gains a `resolvedIcon` input honored by all call sites; a reusable `IconPickerSheet` (search + Auto + PhotosPicker upload + 61-icon grid) is presented from `AddCropView` and from Home's wiggle edit mode.

**Tech Stack:** SwiftUI, SwiftData, PhotosUI (`PhotosPicker`), Swift Testing (`import Testing`), UIKit for image processing.

**Spec:** `docs/superpowers/specs/2026-07-18-crop-icon-picker-design.md`

---

## Project conventions (read first)

- **NEVER run xcodegen** — it wipes signing. Every new file is added to `GardenHarvest.xcodeproj/project.pbxproj` **by hand** (instructions in Task 1, then referenced).
- Build: `xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`
- Test one suite: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/<SuiteName> 2>&1 | tail -30`
- Tests use Swift Testing style (`struct XTests { @Test func … #expect(…) }`), see `GardenHarvestTests/CropIconAssignerTests.swift`.
- UI styling comes from `Theme` (`Theme.card`, `Theme.ink`, `Theme.accent`, `Theme.hairline`, `Theme.Font.body/heading/mono`). Match existing views.

### How to add a file to project.pbxproj (used by several tasks)

For each new file, generate two 24-hex-char IDs:

```bash
python3 -c "import uuid; print(uuid.uuid4().hex[:24].upper()); print(uuid.uuid4().hex[:24].upper())"
```

Then add four entries, mirroring an existing sibling file. For an **app-target** file, mirror `CropIconPlate.swift` (pbxproj lines ~54, ~135, ~319, ~468):

1. `PBXBuildFile` section: `<ID1> /* Foo.swift in Sources */ = {isa = PBXBuildFile; fileRef = <ID2> /* Foo.swift */; };`
2. `PBXFileReference` section: `<ID2> /* Foo.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Foo.swift; sourceTree = "<group>"; };`
3. The `children` list of the correct **group**: find the group by grepping for a file in the same directory (e.g. `CropColorAssigner.swift` for `Services/`, `AddCropView.swift` for `Views/Add/`) and add `<ID2> /* Foo.swift */,` beside it.
4. The app target's `PBXSourcesBuildPhase` `files` list (where `CropIconPlate.swift in Sources` appears): add `<ID1> /* Foo.swift in Sources */,`.

For a **test-target** file, do the same but mirror `CropIconAssignerTests.swift` everywhere (its group and the *test* target's Sources phase).

Verify with a build after every pbxproj edit.

---

### Task 1: Crop model override fields

**Files:**
- Modify: `GardenHarvest/Models/Crop.swift`

- [ ] **Step 1: Add the two optional fields**

Replace the body of `Crop.swift`'s class with:

```swift
@Model
final class Crop {
    @Attribute(.unique) var name: String
    var colorHex: String
    var sortIndex: Int
    var variants: [String]
    /// Explicit icon pick from the VegIcons catalog, e.g. "VegIcons/red-onion".
    /// nil means auto-match from the name.
    var iconAssetName: String?
    /// Center-cropped square JPEG picked from the photo library. Takes
    /// precedence over `iconAssetName`; the two are kept mutually exclusive
    /// by `Crop.iconChoice`.
    @Attribute(.externalStorage) var customIconData: Data?

    init(
        name: String,
        colorHex: String,
        sortIndex: Int,
        variants: [String] = [],
        iconAssetName: String? = nil,
        customIconData: Data? = nil
    ) {
        self.name = name
        self.colorHex = colorHex
        self.sortIndex = sortIndex
        self.variants = variants
        self.iconAssetName = iconAssetName
        self.customIconData = customIconData
    }
}
```

(Keep the existing `Identifiable` extension unchanged. Both new fields are optional with defaults, so existing call sites and on-device stores migrate untouched.)

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Run full existing test suite** (guards SwiftData schema regressions, e.g. `ModelPersistenceTests`, `SeedDataServiceTests`)

Run: `xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -30`
Expected: all suites PASS.

- [ ] **Step 4: Commit**

```bash
git add GardenHarvest/Models/Crop.swift
git commit -m "feat: add icon override fields to Crop model"
```

---

### Task 2: IconChoice, Crop.iconChoice, CropIconResolver

**Files:**
- Create: `GardenHarvest/Services/CropIconResolver.swift`
- Test: `GardenHarvestTests/CropIconResolverTests.swift`
- Modify: `GardenHarvest.xcodeproj/project.pbxproj` (both new files; see conventions)

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
@testable import GardenHarvest

struct CropIconResolverTests {
    private let png = Data([0x89, 0x50, 0x4E, 0x47]) // content irrelevant to the resolver

    @Test func customDataWinsOverEverything() {
        let icon = CropIconResolver.resolve(
            name: "Kale", iconAssetName: "VegIcons/carrot", customIconData: png,
            assetExists: { _ in true }
        )
        #expect(icon == .custom(png))
    }

    @Test func pickedAssetBeatsAutoMatch() {
        let icon = CropIconResolver.resolve(
            name: "Kale", iconAssetName: "VegIcons/red-onion", customIconData: nil,
            assetExists: { _ in true }
        )
        #expect(icon == .asset("VegIcons/red-onion"))
    }

    @Test func missingPickedAssetFallsThroughToAutoMatch() {
        let icon = CropIconResolver.resolve(
            name: "Kale", iconAssetName: "VegIcons/gone", customIconData: nil,
            assetExists: { _ in false }
        )
        #expect(icon == .asset("VegIcons/kale"))
    }

    @Test func noOverridesUsesAutoMatchThenInitials() {
        #expect(CropIconResolver.resolve(
            name: "Kale", iconAssetName: nil, customIconData: nil, assetExists: { _ in true }
        ) == .asset("VegIcons/kale"))
        #expect(CropIconResolver.resolve(
            name: "Rhubarb", iconAssetName: nil, customIconData: nil, assetExists: { _ in true }
        ) == .initials)
    }

    @Test func lookupByNameFindsTheCropsOverrides() {
        let crop = Crop(name: "Radishes", colorHex: "#aabbcc", sortIndex: 0,
                        iconAssetName: "VegIcons/purple-daikon")
        let icon = CropIconResolver.resolve(name: "Radishes", in: [crop])
        #expect(icon == .asset("VegIcons/purple-daikon"))
        // Unknown names still auto-match.
        #expect(CropIconResolver.resolve(name: "Kale", in: [crop]) == .asset("VegIcons/kale"))
    }

    @Test func iconChoiceSetterKeepsOverridesMutuallyExclusive() {
        let crop = Crop(name: "Kale", colorHex: "#aabbcc", sortIndex: 0)
        #expect(crop.iconChoice == .auto)

        crop.iconChoice = .asset("VegIcons/carrot")
        #expect(crop.iconAssetName == "VegIcons/carrot")
        #expect(crop.customIconData == nil)

        crop.iconChoice = .custom(png)
        #expect(crop.customIconData == png)
        #expect(crop.iconAssetName == nil)

        crop.iconChoice = .auto
        #expect(crop.iconAssetName == nil)
        #expect(crop.customIconData == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test … -only-testing:GardenHarvestTests/CropIconResolverTests 2>&1 | tail -30`
Expected: FAIL — compile errors (`CropIconResolver` undefined). *(Add the test file to the test target in pbxproj first, or this fails for the wrong reason.)*

- [ ] **Step 3: Write the implementation**

`GardenHarvest/Services/CropIconResolver.swift`:

```swift
import UIKit

/// The icon a crop should display after applying override precedence:
/// custom photo > picked asset > auto-match by name > initials disc.
enum ResolvedCropIcon: Equatable {
    case custom(Data)
    case asset(String)
    case initials
}

/// A user's selection in the icon picker; `Crop.iconChoice` maps it onto the
/// model's override fields.
enum IconChoice: Equatable {
    case auto
    case asset(String)
    case custom(Data)
}

enum CropIconResolver {
    /// `assetExists` is injectable so tests don't depend on the app bundle's
    /// asset catalog.
    static func resolve(
        name: String,
        iconAssetName: String?,
        customIconData: Data?,
        assetExists: (String) -> Bool = { UIImage(named: $0) != nil }
    ) -> ResolvedCropIcon {
        if let data = customIconData { return .custom(data) }
        if let asset = iconAssetName, assetExists(asset) { return .asset(asset) }
        if let auto = CropIconAssigner.assetName(for: name) { return .asset(auto) }
        return .initials
    }

    static func resolve(for crop: Crop) -> ResolvedCropIcon {
        resolve(name: crop.name, iconAssetName: crop.iconAssetName, customIconData: crop.customIconData)
    }

    static func resolve(name: String, in crops: [Crop]) -> ResolvedCropIcon {
        let crop = crops.first { $0.name == name }
        return resolve(name: name, iconAssetName: crop?.iconAssetName, customIconData: crop?.customIconData)
    }
}

extension Crop {
    var iconChoice: IconChoice {
        get {
            if let data = customIconData { return .custom(data) }
            if let asset = iconAssetName { return .asset(asset) }
            return .auto
        }
        set {
            switch newValue {
            case .auto:
                iconAssetName = nil
                customIconData = nil
            case .asset(let name):
                iconAssetName = name
                customIconData = nil
            case .custom(let data):
                customIconData = data
                iconAssetName = nil
            }
        }
    }
}
```

Add both files to pbxproj (app target / test target) per the conventions section.

- [ ] **Step 4: Run tests to verify they pass**

Same command. Expected: all `CropIconResolverTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/CropIconResolver.swift GardenHarvestTests/CropIconResolverTests.swift GardenHarvest.xcodeproj/project.pbxproj
git commit -m "feat: add CropIconResolver with override precedence and IconChoice"
```

---

### Task 3: IconImageProcessor (center-crop + downscale)

**Files:**
- Create: `GardenHarvest/Services/IconImageProcessor.swift`
- Test: `GardenHarvestTests/IconImageProcessorTests.swift`
- Modify: `GardenHarvest.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the failing tests**

```swift
import UIKit
import Testing
@testable import GardenHarvest

struct IconImageProcessorTests {
    /// Renders a solid-color image of the given size and returns its PNG data.
    private func imageData(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .image { context in
                UIColor.systemGreen.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
        return image.pngData()!
    }

    @Test func landscapeImageBecomesSquareAtTargetSide() {
        let out = IconImageProcessor.squareIconData(from: imageData(width: 1000, height: 600))
        let image = out.flatMap(UIImage.init(data:))
        #expect(image != nil)
        #expect(image!.size.width * image!.scale == 512)
        #expect(image!.size.height * image!.scale == 512)
    }

    @Test func portraitAndSmallImagesAlsoBecomeSquare() {
        let out = IconImageProcessor.squareIconData(from: imageData(width: 60, height: 100))
        let image = out.flatMap(UIImage.init(data:))
        #expect(image!.size.width * image!.scale == 512)
        #expect(image!.size.height * image!.scale == 512)
    }

    @Test func garbageDataReturnsNil() {
        #expect(IconImageProcessor.squareIconData(from: Data([0x00, 0x01])) == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test … -only-testing:GardenHarvestTests/IconImageProcessorTests 2>&1 | tail -30`
Expected: FAIL — `IconImageProcessor` undefined (pbxproj: add the test file first).

- [ ] **Step 3: Write the implementation**

`GardenHarvest/Services/IconImageProcessor.swift`:

```swift
import UIKit

enum IconImageProcessor {
    /// Center-crops the image square, scales it to `side`×`side` pixels, and
    /// JPEG-encodes it for storage in `Crop.customIconData`. Returns nil when
    /// the data isn't a decodable image.
    static func squareIconData(from data: Data, side: CGFloat = 512) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let shortest = min(image.size.width, image.size.height)
        guard shortest > 0 else { return nil }

        let scale = side / shortest
        let origin = CGPoint(
            x: -(image.size.width - shortest) / 2 * scale,
            y: -(image.size.height - shortest) / 2 * scale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let squared = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
            .image { _ in
                image.draw(in: CGRect(
                    origin: origin,
                    size: CGSize(width: image.size.width * scale, height: image.size.height * scale)
                ))
            }
        return squared.jpegData(compressionQuality: 0.85)
    }
}
```

Add both files to pbxproj.

- [ ] **Step 4: Run tests to verify they pass**

Expected: all `IconImageProcessorTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/IconImageProcessor.swift GardenHarvestTests/IconImageProcessorTests.swift GardenHarvest.xcodeproj/project.pbxproj
git commit -m "feat: add IconImageProcessor for custom icon photos"
```

---

### Task 4: IconCatalog

**Files:**
- Create: `GardenHarvest/Services/IconCatalog.swift`
- Test: `GardenHarvestTests/IconCatalogTests.swift`
- Modify: `GardenHarvest.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import GardenHarvest

struct IconCatalogTests {
    @Test func catalogMatchesEverySlugTheAssignerCanProduce() {
        // Every icon the auto-matcher knows is offered in the picker, and the
        // picker offers nothing the catalog doesn't ship (cornucopia excluded
        // by design — it is the "All crops" symbol).
        #expect(Set(IconCatalog.allSlugs) == Set(CropIconAssigner.iconMap.values))
    }

    @Test func slugsAreUniqueAndSorted() {
        #expect(IconCatalog.allSlugs == IconCatalog.allSlugs.sorted())
        #expect(Set(IconCatalog.allSlugs).count == IconCatalog.allSlugs.count)
    }

    @Test func displayNameAndAssetNameFormatting() {
        #expect(IconCatalog.displayName(for: "red-bell-pepper") == "Red Bell Pepper")
        #expect(IconCatalog.assetName(for: "kale") == "VegIcons/kale")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test … -only-testing:GardenHarvestTests/IconCatalogTests 2>&1 | tail -30`
Expected: FAIL — `IconCatalog` undefined.

- [ ] **Step 3: Write the implementation**

`GardenHarvest/Services/IconCatalog.swift`:

```swift
/// Every VegIcons slug offered in the icon picker. Cornucopia is excluded —
/// it is the "All crops" filter symbol, not a crop icon. Kept in sync with
/// `CropIconAssigner.iconMap` by `IconCatalogTests`.
enum IconCatalog {
    static let allSlugs: [String] = [
        "apple", "artichoke", "arugula", "asparagus", "avocado", "banana",
        "basil", "beet", "blackberry", "blueberries", "broccoli",
        "brussels-sprout", "butternut-squash", "cabbage", "cantaloupe",
        "carrot", "cauliflower", "celeriac", "champignon-mushroom",
        "cherry-tomatoes", "chili-pepper", "corn", "cucumber", "daikon",
        "edamame", "eggplant", "garlic", "ginger", "green-beans", "kale",
        "kiwi", "leek", "lime", "mango", "onion", "orange",
        "orange-bell-pepper", "oyster-mushroom", "parsnip", "passion-fruit",
        "pear", "peas", "pomegranate", "porcini-mushroom", "potato",
        "pumpkin", "purple-daikon", "radish", "raspberry", "red-bell-pepper",
        "red-onion", "shiitake-mushroom", "spinach", "strawberry",
        "sweet-potato", "tomato", "turmeric", "turnip", "watermelon",
        "white-radish", "zucchini"
    ]

    static func assetName(for slug: String) -> String { "VegIcons/\(slug)" }

    /// "red-bell-pepper" -> "Red Bell Pepper", for search and accessibility.
    static func displayName(for slug: String) -> String {
        slug.split(separator: "-").map(\.capitalized).joined(separator: " ")
    }
}
```

Add both files to pbxproj.

- [ ] **Step 4: Run tests to verify they pass**

Expected: all `IconCatalogTests` PASS.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/IconCatalog.swift GardenHarvestTests/IconCatalogTests.swift GardenHarvest.xcodeproj/project.pbxproj
git commit -m "feat: add IconCatalog listing all pickable VegIcons"
```

---

### Task 5: CropIconPlate renders resolved icons; direct call sites

**Files:**
- Modify: `GardenHarvest/Views/CropIconPlate.swift`
- Modify: `GardenHarvest/Views/Home/CropTileView.swift:11-17`
- Modify: `GardenHarvest/Views/Entry/EntryView.swift:104-110`
- Modify: `GardenHarvest/Views/Log/LogView.swift:246-255` (`filterIconPlate`)
- Modify: `GardenHarvest/Views/Report/ReportView.swift:~131` (top-crops row)

- [ ] **Step 1: Rewrite CropIconPlate**

Replace the whole struct with:

```swift
import SwiftUI

/// Circular plate that shows a crop's vegetable icon on a soft radial-gradient
/// dish, a circle-cropped custom photo, or the colored initials disc.
struct CropIconPlate: View {
    let cropName: String
    let colorHex: String
    /// Outer plate diameter.
    let plateSize: CGFloat
    /// Icon image size inside the plate.
    let iconSize: CGFloat
    /// Fallback initials disc diameter.
    let discSize: CGFloat
    /// Explicit asset to show regardless of the crop, e.g. the cornucopia for
    /// the "All crops" filter row. Wins over `resolvedIcon`.
    var assetOverride: String? = nil
    /// Pre-resolved icon from a crop's stored override fields (see
    /// `CropIconResolver`). nil keeps the name-based auto-match, so call
    /// sites without a `Crop` behave exactly as before.
    var resolvedIcon: ResolvedCropIcon? = nil

    private static let plateInner = Color.white
    private static let plateOuter = Color(hex: "#eef3e4")

    var body: some View {
        ZStack {
            switch effectiveIcon {
            case .custom(let data):
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: plateSize, height: plateSize)
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "#22381c").opacity(0.18), radius: plateSize * 0.05, y: plateSize * 0.02)
                } else {
                    dish
                    initialsDisc
                }
            case .asset(let assetName):
                dish
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: Color(hex: "#22381c").opacity(0.22), radius: 3.5, y: 2)
            case .initials:
                dish
                initialsDisc
            }
        }
        .frame(width: plateSize, height: plateSize)
    }

    private var effectiveIcon: ResolvedCropIcon {
        if let assetOverride { return .asset(assetOverride) }
        if let resolvedIcon { return resolvedIcon }
        if let auto = CropIconAssigner.assetName(for: cropName) { return .asset(auto) }
        return .initials
    }

    private var dish: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Self.plateInner, Self.plateOuter],
                    center: UnitPoint(x: 0.5, y: 0.38),
                    startRadius: 0,
                    endRadius: plateSize * 0.62
                )
            )
            .shadow(color: Color(hex: "#22381c").opacity(0.07), radius: plateSize * 0.07, y: plateSize * 0.03)
    }

    private var initialsDisc: some View {
        Circle()
            .fill(Color(hex: colorHex))
            .frame(width: discSize, height: discSize)
            .shadow(color: .black.opacity(0.12), radius: 4, y: -1.5)
            .overlay(
                Text(cropName.cropInitials)
                    .font(Theme.Font.mono(discSize > 44 ? 15 : 12, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}
```

- [ ] **Step 2: Update call sites that already hold crop data**

In `CropTileView.swift`, add to the `CropIconPlate(...)` call:

```swift
                    resolvedIcon: CropIconResolver.resolve(for: crop)
```

In `EntryView.swift` (header plate, has `crop: Crop?` via line 40):

```swift
                    resolvedIcon: crop.map { CropIconResolver.resolve(for: $0) }
```

In `LogView.swift` `filterIconPlate(...)` (the view has `@Query private var crops: [Crop]`):

```swift
            resolvedIcon: logCrop.map { CropIconResolver.resolve(name: $0, in: crops) },
```

(keep the existing `assetOverride:` argument — argument order must match the struct's property order: `assetOverride` before `resolvedIcon`).

In `ReportView.swift` top-crops row (~line 131; the view has `@Query private var crops: [Crop]`), add to the `CropIconPlate(...)` call, using whatever local variable holds that row's crop name:

```swift
            resolvedIcon: CropIconResolver.resolve(name: <rowCropName>, in: crops)
```

- [ ] **Step 3: Build and run full test suite**

Expected: `BUILD SUCCEEDED`, all suites PASS (no behavior change while all overrides are nil).

- [ ] **Step 4: Commit**

```bash
git add GardenHarvest/Views/CropIconPlate.swift GardenHarvest/Views/Home/CropTileView.swift GardenHarvest/Views/Entry/EntryView.swift GardenHarvest/Views/Log/LogView.swift GardenHarvest/Views/Report/ReportView.swift
git commit -m "feat: render resolved crop icons in CropIconPlate and direct call sites"
```

---

### Task 6: Thread resolver into closure-based views

**Files:**
- Modify: `GardenHarvest/Views/Log/LogMonthSection.swift` (property list ~line 16, `pickingRow` ~line 135)
- Modify: `GardenHarvest/Views/Log/CropFilterSheet.swift` (property list, `row` ~line 54)
- Modify: `GardenHarvest/Views/Report/InsightDeck.swift` (property list ~line 11, plate ~line 81)
- Modify: `GardenHarvest/Views/Log/LogView.swift` (constructs `LogMonthSection` and `CropFilterSheet`)
- Modify: `GardenHarvest/Views/Report/ReportView.swift` (constructs `InsightDeck`)

These views receive a `colorHex: (String) -> String` closure instead of querying crops; follow the same pattern with a `resolveIcon` closure.

- [ ] **Step 1: Add the closure property and use it**

In each of the three views, directly below the existing `let colorHex: (String) -> String` property add:

```swift
    let resolveIcon: (String) -> ResolvedCropIcon
```

Then add to that view's `CropIconPlate(...)` call(s):

- `LogMonthSection.pickingRow`: `resolvedIcon: resolveIcon(entry.cropName)`
- `InsightDeck` (~line 81, inside `if let crop = insight.cropName`): `resolvedIcon: resolveIcon(crop)`
- `CropFilterSheet.row`: `resolvedIcon: name.map(resolveIcon)` — placed **after** the existing `assetOverride:` argument to match property order.

- [ ] **Step 2: Pass the closure from the constructing views**

In `LogView.swift`, at every `LogMonthSection(` and `CropFilterSheet(` construction, add alongside the existing `colorHex:` argument:

```swift
            resolveIcon: { CropIconResolver.resolve(name: $0, in: crops) },
```

In `ReportView.swift`, at the `InsightDeck(` construction, add the same line.

- [ ] **Step 3: Build and run full test suite**

Expected: `BUILD SUCCEEDED`, all suites PASS.

- [ ] **Step 4: Commit**

```bash
git add GardenHarvest/Views/Log/LogMonthSection.swift GardenHarvest/Views/Log/CropFilterSheet.swift GardenHarvest/Views/Report/InsightDeck.swift GardenHarvest/Views/Log/LogView.swift GardenHarvest/Views/Report/ReportView.swift
git commit -m "feat: thread icon resolver into log, filter, and insight views"
```

---

### Task 7: Share card honors overrides

**Files:**
- Modify: `GardenHarvest/Views/Report/ShareCardView.swift` (model ~lines 6-23, icon drawing ~line 162, MVP plate ~line 69)
- Modify: the file constructing `HarvestShareCardModel` (grep `HarvestShareCardModel(` — in the Report flow)

`HarvestShareCardView` is rendered via `ImageRenderer` and must stay environment-free, so resolved icons ride on the model.

- [ ] **Step 1: Extend the model**

In `HarvestShareCardModel`, add to `TopCrop`:

```swift
        let icon: ResolvedCropIcon
```

and to the model itself (near the other `mvp…` fields):

```swift
    let mvpIcon: ResolvedCropIcon?
```

- [ ] **Step 2: Use resolved icons when drawing**

Around line 162, replace the `if let assetName = CropIconAssigner.assetName(for: crop.name)`-based branch with a switch on `crop.icon`:

```swift
            switch crop.icon {
            case .custom(let data):
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: <existing icon size>, height: <existing icon size>)
                        .clipShape(Circle())
                } else {
                    // fall back to the existing initials/color circle branch
                }
            case .asset(let assetName):
                // existing Image(assetName) branch, unchanged
            case .initials:
                // existing colored-circle branch, unchanged
            }
```

(`<existing icon size>` = whatever frame the current asset branch uses; keep the surrounding layout untouched.) Do the equivalent where the MVP crop's `CropIconPlate`/icon is drawn (~line 69): pass `resolvedIcon: model.mvpIcon` if it uses `CropIconPlate`, or switch the same way if it draws manually.

- [ ] **Step 3: Populate at the construction site**

Where `HarvestShareCardModel` and its `TopCrop`s are built (that view has access to `crops` via `@Query` or receives them — mirror how `colorHex` is sourced there), set:

```swift
            icon: CropIconResolver.resolve(name: <cropName>, in: crops)
            // and
            mvpIcon: mvpName.map { CropIconResolver.resolve(name: $0, in: crops) }
```

- [ ] **Step 4: Build and run full test suite**

Expected: `BUILD SUCCEEDED`, all suites PASS.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Views/Report/
git commit -m "feat: carry resolved crop icons into the share card model"
```

---

### Task 8: IconPickerSheet

**Files:**
- Create: `GardenHarvest/Views/Add/IconPickerSheet.swift`
- Modify: `GardenHarvest.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the sheet**

```swift
import SwiftUI
import PhotosUI

/// Sheet for choosing a crop's icon: auto-match, any VegIcons asset, or a
/// photo-library image (center-cropped by `IconImageProcessor`). Persistence
/// is the caller's job via `onSelect`.
struct IconPickerSheet: View {
    let cropName: String
    let colorHex: String
    let current: IconChoice
    let onSelect: (IconChoice) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var photoItem: PhotosPickerItem?

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    private var filteredSlugs: [String] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return IconCatalog.allSlugs }
        return IconCatalog.allSlugs.filter {
            IconCatalog.displayName(for: $0).lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose an icon")
                .font(Theme.Font.heading(19, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .padding(.top, 22)
            searchField
            ScrollView {
                LazyVGrid(columns: Self.columns, spacing: 14) {
                    if search.isEmpty {
                        autoTile
                        uploadTile
                    }
                    ForEach(filteredSlugs, id: \.self) { slug in
                        iconTile(slug)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let processed = IconImageProcessor.squareIconData(from: raw) {
                    onSelect(.custom(processed))
                    dismiss()
                }
                // Load/decode failure: keep the previous selection, stay open.
                photoItem = nil
            }
        }
    }

    private var searchField: some View {
        TextField("Search icons…", text: $search)
            .font(Theme.Font.body(15, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            .padding(.horizontal, 20)
    }

    /// Shows what auto-match yields for this crop; selecting clears overrides.
    private var autoTile: some View {
        tileButton(isSelected: current == .auto, label: "Auto") {
            onSelect(.auto)
            dismiss()
        } content: {
            CropIconPlate(cropName: cropName, colorHex: colorHex,
                          plateSize: 56, iconSize: 44, discSize: 48)
        }
    }

    private var uploadTile: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 6) {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "photo.badge.plus").foregroundStyle(Theme.accent))
                Text("Photo")
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func iconTile(_ slug: String) -> some View {
        let assetName = IconCatalog.assetName(for: slug)
        return tileButton(
            isSelected: current == .asset(assetName),
            label: IconCatalog.displayName(for: slug)
        ) {
            onSelect(.asset(assetName))
            dismiss()
        } content: {
            CropIconPlate(cropName: cropName, colorHex: colorHex,
                          plateSize: 56, iconSize: 44, discSize: 48,
                          assetOverride: assetName)
        }
    }

    private func tileButton(
        isSelected: Bool,
        label: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> some View
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                content()
                    .overlay(
                        Circle().stroke(isSelected ? Theme.accent : .clear, lineWidth: 3)
                    )
                Text(label)
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.sub)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
```

Add the file to pbxproj (app target, `Views/Add` group beside `AddCropView.swift`).

- [ ] **Step 2: Build**

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add GardenHarvest/Views/Add/IconPickerSheet.swift GardenHarvest.xcodeproj/project.pbxproj
git commit -m "feat: add IconPickerSheet with search, auto, upload, and icon grid"
```

---

### Task 9: AddCropView integration

**Files:**
- Modify: `GardenHarvest/Views/Add/AddCropView.swift`

- [ ] **Step 1: Add state and sheet**

Add below the existing `@State private var name`:

```swift
    @State private var iconChoice: IconChoice = .auto
    @State private var showIconPicker = false
```

Add to the `ScrollView`'s modifier chain (next to `.onAppear`):

```swift
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(
                cropName: trimmedName,
                colorHex: CropColorAssigner.colorHex(for: trimmedName),
                current: iconChoice,
                onSelect: { iconChoice = $0 }
            )
        }
```

- [ ] **Step 2: Make the preview a picker button**

Replace `iconPreview` and `previewCaption` with:

```swift
    private var resolvedPreviewIcon: ResolvedCropIcon? {
        switch iconChoice {
        case .auto: return nil
        case .asset(let name): return .asset(name)
        case .custom(let data): return .custom(data)
        }
    }

    private var iconPreview: some View {
        Button {
            showIconPicker = true
        } label: {
            VStack(spacing: 8) {
                if trimmedName.isEmpty && iconChoice == .auto {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .foregroundStyle(Theme.hairline)
                        .frame(width: 128, height: 128)
                        .overlay(
                            Text("🌱")
                                .font(.system(size: 46))
                                .opacity(0.5)
                        )
                } else {
                    CropIconPlate(
                        cropName: trimmedName,
                        colorHex: CropColorAssigner.colorHex(for: trimmedName),
                        plateSize: 128,
                        iconSize: 98,
                        discSize: 108,
                        resolvedIcon: resolvedPreviewIcon
                    )
                }
                Text(previewCaption)
                    .font(Theme.Font.mono(11.5, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(captionIsAccented ? Theme.accent2 : Theme.sub)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .animation(.easeOut(duration: 0.18), value: iconChoice)
        .animation(.easeOut(duration: 0.18), value: matchedIconName)
    }

    private var captionIsAccented: Bool {
        iconChoice != .auto || matchedIconName != nil
    }

    private var previewCaption: String {
        switch iconChoice {
        case .custom: return "Custom photo · tap to change"
        case .asset: return "Icon picked · tap to change"
        case .auto:
            if matchedIconName != nil { return "Auto-matched · tap to change" }
            if trimmedName.isEmpty { return "Start typing, or tap to pick an icon" }
            return "No icon match · tap to pick one"
        }
    }
```

(Keep `matchedIconName` as is. A picked icon deliberately survives name edits and suggestion taps — an explicit choice shouldn't be silently discarded; Auto stays live-updating.)

- [ ] **Step 3: Persist the choice in `commit()`**

Replace the `if !crops.contains…` block's body and add the existing-crop branch:

```swift
        if let existing = crops.first(where: { $0.name == canonicalName }) {
            // Re-adding a known crop: only a deliberate pick overwrites its icon.
            if iconChoice != .auto {
                existing.iconChoice = iconChoice
                try? modelContext.save()
            }
        } else {
            let crop = Crop(
                name: canonicalName,
                colorHex: CropColorAssigner.colorHex(for: canonicalName),
                sortIndex: (crops.map(\.sortIndex).max() ?? -1) + 1,
                variants: []
            )
            crop.iconChoice = iconChoice
            modelContext.insert(crop)
            try? modelContext.save()
        }
```

- [ ] **Step 4: Build and run full test suite**

Expected: `BUILD SUCCEEDED`, all suites PASS.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Views/Add/AddCropView.swift
git commit -m "feat: icon picker in AddCropView with persisted choice"
```

---

### Task 10: Edit existing crops from Home's wiggle mode

**Files:**
- Modify: `GardenHarvest/Views/Home/HomeView.swift` (state ~line 10, `tile(for:)` ~line 97, body ~line 25)

- [ ] **Step 1: Open the picker from an edit-mode tap**

Add state below `@State private var draggingCrop`:

```swift
    @State private var iconEditingCrop: Crop?
```

In `tile(for:)`, replace the `CropTileView` action closure:

```swift
        let base = CropTileView(crop: crop, totalOunces: totalOunces) {
            if isEditing {
                iconEditingCrop = crop
            } else {
                onSelectCrop(crop.name)
            }
        }
```

Add to the `ScrollView`'s modifier chain (next to `.onDrop`):

```swift
        .sheet(item: $iconEditingCrop) { crop in
            IconPickerSheet(
                cropName: crop.name,
                colorHex: crop.colorHex,
                current: crop.iconChoice,
                onSelect: { choice in
                    crop.iconChoice = choice
                    try? modelContext.save()
                }
            )
        }
```

- [ ] **Step 2: Build and run full test suite**

Expected: `BUILD SUCCEEDED`, all suites PASS.

- [ ] **Step 3: Commit**

```bash
git add GardenHarvest/Views/Home/HomeView.swift
git commit -m "feat: change a crop's icon from Home edit mode"
```

---

### Task 11: End-to-end verification in the simulator

**Files:** none (verification only)

- [ ] **Step 1: Migration check** — install the previous commit's build in the simulator, add crops and log entries, then install this branch's build over it. Expected: launches cleanly, all icons unchanged (auto-match).

- [ ] **Step 2: Add flow** — Add Crop → type "Radishes" → tap the preview → pick `purple-daikon`. Expected: preview shows it, caption "Icon picked · tap to change"; after commit, the Home tile, Entry header, Log rows, filter sheet, and Report all show purple-daikon.

- [ ] **Step 3: Custom photo** — Add another crop → tap preview → Photo → pick any photo. Expected: circle-cropped photo in preview and, after commit, everywhere the crop renders (including the share card image saved from Report).

- [ ] **Step 4: Edit flow** — Home → long-press to wiggle mode → tap a tile → pick a different icon, then repeat and pick **Auto**. Expected: icon changes propagate immediately; Auto restores the name-derived icon.

- [ ] **Step 5: Search + failure path** — In the sheet, search "pepper" (expect 3 tiles, no Auto/Photo tiles while searching); cancel a photo pick (expect selection unchanged).

- [ ] **Step 6: Full test suite one last time**, then commit any fixes.

---

## Self-review notes

- Spec coverage: model (T1), resolver/precedence + mutual exclusion (T2), photo processing (T3), catalog (T4), rendering everywhere (T5-T7), picker UI incl. Auto/upload/search (T8), add flow (T9), edit flow (T10), migration + manual checks (T11). Error handling: decode failure keeps prior selection (T8 `onChange`), missing asset falls back (T2 resolver).
- `PhotosPicker` needs no Info.plist usage string (out-of-process picker).
- Property order in `CropIconPlate` calls: `assetOverride` before `resolvedIcon`.
