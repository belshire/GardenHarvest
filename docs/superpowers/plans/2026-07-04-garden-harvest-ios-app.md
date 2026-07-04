# Garden Harvest iOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold a SwiftUI + SwiftData iOS app ("GardenHarvest") implementing the core harvest-logging loop (Home → Entry → Add) from the Claude Design handoff, seeded with the user's real 2026 harvest data plus ported synthetic 2024/2025 history.

**Architecture:** Single Xcode project (generated via `xcodegen` from `project.yml`, since no Xcode GUI is available in this environment) with a SwiftData model layer (`HarvestEntry`, `Crop`), a small set of pure-logic services ported verbatim from the prototype's JS (weight formatting, crop color hashing, date chips, seed-data generation), and SwiftUI views organized by screen (Home, Entry, Add) under a custom tab-bar root. Every task leaves the app in a buildable, runnable state.

**Tech Stack:** Swift 6.3 / Xcode 26, SwiftUI, SwiftData (iOS 17+), PhotosUI (`PhotosPicker`), `UIImagePickerController` (camera, wrapped via `UIViewControllerRepresentable`), Swift Testing (`import Testing`, `@Test`, `#expect`) for unit tests, `xcodegen` for project-file generation.

**Reference spec:** `docs/superpowers/specs/2026-07-04-garden-harvest-ios-app-design.md`

---

## File structure

```
garden-tracker/
  project.yml                              # xcodegen project spec
  GardenHarvest.xcodeproj/                  # generated — do not hand-edit
  GardenHarvest/
    GardenHarvestApp.swift                  # @main App, ModelContainer, seeding
    Assets.xcassets/                        # AccentColor only, this pass
    Models/
      HarvestEntry.swift
      Crop.swift
    Seed/
      MasterCropList.swift                  # ~56-item autocomplete list
      SeedDataService.swift                 # RAW parser + seed()/gen() port + seedIfNeeded
    Services/
      WeightFormatter.swift                 # oz -> "X oz" / "X lb Y oz"
      CropColorAssigner.swift               # known colors + hash fallback
      DateChip.swift                        # Today / Yesterday / 2 days ago
    Theme/
      Theme.swift                           # design tokens, Color(hex:), fonts
      ChipButtonStyle.swift                 # shared pill-chip button style
    Views/
      AppTab.swift
      RootView.swift                        # tab switcher + panel background
      BottomTabBar.swift
      ComingSoonView.swift                  # Log / Unwrapped placeholders
      Home/
        HomeContainerView.swift             # NavigationStack + toast + routing
        HomeView.swift                      # total card + quick-log grid
        CropTileView.swift
        AddCropTileView.swift
        ToastView.swift
      Entry/
        EntryView.swift                     # log-a-harvest screen
        CameraPicker.swift                  # UIImagePickerController wrapper
      Add/
        AddCropView.swift                   # new-vegetable screen
  GardenHarvestTests/
    ColorHexTests.swift
    ModelPersistenceTests.swift
    MasterCropListTests.swift
    WeightFormatterTests.swift
    CropColorAssignerTests.swift
    DateChipTests.swift
    SeedDataServiceTests.swift
    SeedIfNeededTests.swift
```

**Build/test device used throughout:** `iPhone 17 Pro` (confirmed available via `xcrun simctl list devices available`).

**After every task that adds new Swift files**, re-run `xcodegen generate` before building — xcodegen enumerates source files at generation time, so newly created files won't appear in the `.xcodeproj` until it's regenerated.

---

### Task 1: Scaffold the Xcode project with xcodegen

**Files:**
- Create: `project.yml`
- Create: `GardenHarvest/GardenHarvestApp.swift`
- Create: `GardenHarvest/Assets.xcassets/Contents.json`
- Create: `GardenHarvest/Assets.xcassets/AccentColor.colorset/Contents.json`

- [ ] **Step 1: Install xcodegen**

Run: `brew install xcodegen`
Expected: installs successfully; `xcodegen --version` prints a version number.

- [ ] **Step 2: Create the source directories**

Run:
```bash
mkdir -p GardenHarvest/Assets.xcassets/AccentColor.colorset
mkdir -p GardenHarvestTests
```

- [ ] **Step 3: Write `project.yml`**

```yaml
name: GardenHarvest
options:
  bundleIdPrefix: com.belshire
  deploymentTarget:
    iOS: "17.0"
settings:
  base:
    SWIFT_VERSION: "5.0"
targets:
  GardenHarvest:
    type: application
    platform: iOS
    sources:
      - path: GardenHarvest
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.belshire.GardenHarvest
        TARGETED_DEVICE_FAMILY: "1"
        GENERATE_INFOPLIST_FILE: true
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
        INFOPLIST_KEY_NSCameraUsageDescription: "Garden Harvest uses your camera to attach a photo to a harvest entry."
        INFOPLIST_KEY_NSPhotoLibraryUsageDescription: "Garden Harvest lets you attach a photo from your library to a harvest entry."
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        CODE_SIGN_STYLE: Automatic
  GardenHarvestTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: GardenHarvestTests
    dependencies:
      - target: GardenHarvest
    settings:
      base:
        GENERATE_INFOPLIST_FILE: true
        CODE_SIGN_STYLE: Automatic
schemes:
  GardenHarvest:
    build:
      targets:
        GardenHarvest: all
        GardenHarvestTests: [test]
    test:
      targets:
        - GardenHarvestTests
    run:
      config: Debug
```

- [ ] **Step 4: Write the minimal app entry point**

`GardenHarvest/GardenHarvestApp.swift`:
```swift
import SwiftUI

@main
struct GardenHarvestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Garden Harvest")
        }
    }
}
```

- [ ] **Step 5: Write the asset catalog**

`GardenHarvest/Assets.xcassets/Contents.json`:
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`GardenHarvest/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x4D",
          "green" : "0x6A",
          "red" : "0xFF"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 6: Generate the Xcode project**

Run: `xcodegen generate`
Expected: `Generated project at GardenHarvest.xcodeproj`

- [ ] **Step 7: Build for simulator**

Run: `xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add project.yml GardenHarvest GardenHarvestTests GardenHarvest.xcodeproj
git commit -m "Scaffold GardenHarvest Xcode project via xcodegen"
```

---

### Task 2: Design tokens — `Theme` and `Color(hex:)`

**Files:**
- Create: `GardenHarvest/Theme/Theme.swift`
- Test: `GardenHarvestTests/ColorHexTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/ColorHexTests.swift`:
```swift
import Testing
import SwiftUI
import UIKit
@testable import GardenHarvest

struct ColorHexTests {
    @Test func parsesHexWithHash() {
        let color = Color(hex: "#ff6a4d")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 1.0) < 0.01)
        #expect(abs(g - Double(0x6a) / 255.0) < 0.01)
        #expect(abs(b - Double(0x4d) / 255.0) < 0.01)
    }

    @Test func parsesHexWithoutHash() {
        let color = Color(hex: "4caf50")
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - Double(0x4c) / 255.0) < 0.01)
        #expect(abs(g - Double(0xaf) / 255.0) < 0.01)
        #expect(abs(b - Double(0x50) / 255.0) < 0.01)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/ColorHexTests 2>&1 | tail -30`
Expected: FAIL — `Color` has no member `hex` initializer (compile error).

- [ ] **Step 3: Write `Theme.swift`**

`GardenHarvest/Theme/Theme.swift`:
```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    static let accent = Color(hex: "#ff6a4d")
    static let accent2 = Color(hex: "#4caf50")
    static let ink = Color(hex: "#22381c")
    static let sub = Color(hex: "#6a8560")
    static let card = Color.white
    static let hairline = Color(hex: "#22381c").opacity(0.10)
    static let panelTop = Color(hex: "#f0f8e8")
    static let panelBottom = Color(hex: "#e2f2d3")

    static var panelBackground: LinearGradient {
        LinearGradient(colors: [panelTop, panelBottom], startPoint: .top, endPoint: .bottom)
    }

    static let cardRadius: CGFloat = 24
    static let tileRadius: CGFloat = 22

    enum Font {
        static func heading(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/ColorHexTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Theme GardenHarvestTests/ColorHexTests.swift GardenHarvest.xcodeproj
git commit -m "Add Theme design tokens and Color(hex:) initializer"
```

---

### Task 3: SwiftData models — `HarvestEntry` and `Crop`

**Files:**
- Create: `GardenHarvest/Models/HarvestEntry.swift`
- Create: `GardenHarvest/Models/Crop.swift`
- Test: `GardenHarvestTests/ModelPersistenceTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/ModelPersistenceTests.swift`:
```swift
import Testing
import SwiftData
import Foundation
@testable import GardenHarvest

struct ModelPersistenceTests {
    @Test func harvestEntryAndCropRoundTripThroughSwiftData() throws {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let crop = Crop(name: "Asparagus", colorHex: "#5a9a3d", isQuickLog: true, sortIndex: 0, variants: [])
        context.insert(crop)
        let entry = HarvestEntry(cropName: "Asparagus", ounces: 18, date: .now)
        context.insert(entry)
        try context.save()

        let fetchedCrops = try context.fetch(FetchDescriptor<Crop>())
        let fetchedEntries = try context.fetch(FetchDescriptor<HarvestEntry>())
        #expect(fetchedCrops.count == 1)
        #expect(fetchedEntries.count == 1)
        #expect(fetchedEntries.first?.ounces == 18)
        #expect(fetchedCrops.first?.variants.isEmpty == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/ModelPersistenceTests 2>&1 | tail -30`
Expected: FAIL — `HarvestEntry` / `Crop` not found in scope.

- [ ] **Step 3: Write the models**

`GardenHarvest/Models/HarvestEntry.swift`:
```swift
import Foundation
import SwiftData

@Model
final class HarvestEntry {
    var cropName: String
    var ounces: Double
    var date: Date
    var note: String
    var variant: String?
    var photoData: Data?
    var photoSource: String?

    init(
        cropName: String,
        ounces: Double,
        date: Date,
        note: String = "",
        variant: String? = nil,
        photoData: Data? = nil,
        photoSource: String? = nil
    ) {
        self.cropName = cropName
        self.ounces = ounces
        self.date = date
        self.note = note
        self.variant = variant
        self.photoData = photoData
        self.photoSource = photoSource
    }
}
```

`GardenHarvest/Models/Crop.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Crop {
    @Attribute(.unique) var name: String
    var colorHex: String
    var isQuickLog: Bool
    var sortIndex: Int
    var variants: [String]

    init(
        name: String,
        colorHex: String,
        isQuickLog: Bool,
        sortIndex: Int,
        variants: [String] = []
    ) {
        self.name = name
        self.colorHex = colorHex
        self.isQuickLog = isQuickLog
        self.sortIndex = sortIndex
        self.variants = variants
    }
}

extension Crop: Identifiable {
    var id: String { name }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/ModelPersistenceTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Models GardenHarvestTests/ModelPersistenceTests.swift GardenHarvest.xcodeproj
git commit -m "Add HarvestEntry and Crop SwiftData models"
```

---

### Task 4: `MasterCropList`

**Files:**
- Create: `GardenHarvest/Seed/MasterCropList.swift`
- Test: `GardenHarvestTests/MasterCropListTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/MasterCropListTests.swift`:
```swift
import Testing
@testable import GardenHarvest

struct MasterCropListTests {
    @Test func containsExpectedCoreCrops() {
        #expect(MasterCropList.names.contains("Asparagus"))
        #expect(MasterCropList.names.contains("Sweet Potatoes"))
        #expect(MasterCropList.names.count == 56)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/MasterCropListTests 2>&1 | tail -30`
Expected: FAIL — `MasterCropList` not found in scope.

- [ ] **Step 3: Write `MasterCropList.swift`**

`GardenHarvest/Seed/MasterCropList.swift`:
```swift
enum MasterCropList {
    static let names: [String] = [
        "Asparagus", "Strawberries", "Raspberries", "Blueberries", "Boysenberries",
        "Blackberries", "Artichoke", "Radishes", "Peas", "Mushrooms", "Tomatoes Cherry",
        "Tomatoes", "Cucumber", "Zucchini", "Kale", "Lettuce", "Carrots", "Green Beans",
        "Peppers", "Bell Peppers", "Squash", "Basil", "Corn", "Onions", "Garlic", "Potatoes",
        "Beets", "Chard", "Spinach", "Broccoli", "Cauliflower", "Cabbage", "Eggplant",
        "Cherries", "Figs", "Plums", "Apples", "Pears", "Grapes", "Melon", "Watermelon",
        "Cantaloupe", "Pumpkin", "Rhubarb", "Gooseberries", "Currants", "Leeks", "Celery",
        "Fennel", "Turnips", "Parsnips", "Okra", "Cilantro", "Parsley", "Mint",
        "Sweet Potatoes"
    ]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/MasterCropListTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Seed/MasterCropList.swift GardenHarvestTests/MasterCropListTests.swift GardenHarvest.xcodeproj
git commit -m "Add master crop autocomplete list"
```

---

### Task 5: `WeightFormatter`

**Files:**
- Create: `GardenHarvest/Services/WeightFormatter.swift`
- Test: `GardenHarvestTests/WeightFormatterTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/WeightFormatterTests.swift`:
```swift
import Testing
@testable import GardenHarvest

struct WeightFormatterTests {
    @Test func ouncesDropsTrailingZeroDecimal() {
        #expect(WeightFormatter.ounces(5.0) == "5")
        #expect(WeightFormatter.ounces(5.5) == "5.5")
        #expect(WeightFormatter.ounces(5.25) == "5.3")
    }

    @Test func poundsAndOuncesBelow16StaysInOunces() {
        #expect(WeightFormatter.poundsAndOunces(15.9) == "15.9 oz")
    }

    @Test func poundsAndOuncesAtExactPoundDropsOzPart() {
        #expect(WeightFormatter.poundsAndOunces(32) == "2 lb")
    }

    @Test func poundsAndOuncesWithRemainder() {
        #expect(WeightFormatter.poundsAndOunces(40.1) == "2 lb 8.1 oz")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/WeightFormatterTests 2>&1 | tail -30`
Expected: FAIL — `WeightFormatter` not found in scope.

- [ ] **Step 3: Write `WeightFormatter.swift`**

`GardenHarvest/Services/WeightFormatter.swift`:
```swift
import Foundation

enum WeightFormatter {
    static func ounces(_ oz: Double) -> String {
        let rounded = (oz * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    static func poundsAndOunces(_ oz: Double) -> String {
        let rounded = (oz * 10).rounded() / 10
        guard rounded >= 16 else { return "\(ounces(rounded)) oz" }
        let pounds = Int(rounded / 16)
        let remainder = ((rounded - Double(pounds) * 16) * 10).rounded() / 10
        if remainder > 0 {
            return "\(pounds) lb \(ounces(remainder)) oz"
        }
        return "\(pounds) lb"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/WeightFormatterTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/WeightFormatter.swift GardenHarvestTests/WeightFormatterTests.swift GardenHarvest.xcodeproj
git commit -m "Add WeightFormatter (oz -> oz/lb display)"
```

---

### Task 6: `CropColorAssigner`

**Files:**
- Create: `GardenHarvest/Services/CropColorAssigner.swift`
- Test: `GardenHarvestTests/CropColorAssignerTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/CropColorAssignerTests.swift`:
```swift
import Testing
@testable import GardenHarvest

struct CropColorAssignerTests {
    @Test func knownCropsUseExplicitColors() {
        #expect(CropColorAssigner.colorHex(for: "Asparagus") == "#5a9a3d")
        #expect(CropColorAssigner.colorHex(for: "Raspberries") == "#c02f66")
        #expect(CropColorAssigner.colorHex(for: "Tomatoes Cherry") == "#ef4f34")
    }

    @Test func unknownCropDerivesDeterministicHashColor() {
        // Hand-computed from the prototype's hash formula (h = h*31 + charCode, unsigned
        // 32-bit, mod 360 for hue) piped through standard HSL(hue, 52%, 55%) -> RGB.
        #expect(CropColorAssigner.colorHex(for: "Kale") == "#c85162")
        #expect(CropColorAssigner.colorHex(for: "Kale") == CropColorAssigner.colorHex(for: "Kale"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/CropColorAssignerTests 2>&1 | tail -30`
Expected: FAIL — `CropColorAssigner` not found in scope.

- [ ] **Step 3: Write `CropColorAssigner.swift`**

`GardenHarvest/Services/CropColorAssigner.swift`:
```swift
import Foundation

enum CropColorAssigner {
    static let knownColors: [String: String] = [
        "Asparagus": "#5a9a3d",
        "Strawberries": "#e8434a",
        "Raspberries": "#c02f66",
        "Blueberries": "#3f6ad0",
        "Boysenberries": "#6f3fa8",
        "Artichoke": "#7f9a4e",
        "Radishes": "#e05583",
        "Peas": "#8cbf4f",
        "Mushrooms": "#b08a63",
        "Tomatoes Cherry": "#ef4f34"
    ]

    static func colorHex(for name: String) -> String {
        if let known = knownColors[name] {
            return known
        }
        var hash: UInt32 = 0
        for scalar in name.unicodeScalars {
            hash = hash &* 31 &+ scalar.value
        }
        let hue = Double(hash % 360)
        return hexFromHSL(hue: hue, saturation: 0.52, lightness: 0.55)
    }

    private static func hexFromHSL(hue: Double, saturation: Double, lightness: Double) -> String {
        let c = (1 - abs(2 * lightness - 1)) * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2
        let (r1, g1, b1): (Double, Double, Double)
        switch hue {
        case 0..<60: (r1, g1, b1) = (c, x, 0)
        case 60..<120: (r1, g1, b1) = (x, c, 0)
        case 120..<180: (r1, g1, b1) = (0, c, x)
        case 180..<240: (r1, g1, b1) = (0, x, c)
        case 240..<300: (r1, g1, b1) = (x, 0, c)
        default: (r1, g1, b1) = (c, 0, x)
        }
        let r = Int(((r1 + m) * 255).rounded())
        let g = Int(((g1 + m) * 255).rounded())
        let b = Int(((b1 + m) * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/CropColorAssignerTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/CropColorAssigner.swift GardenHarvestTests/CropColorAssignerTests.swift GardenHarvest.xcodeproj
git commit -m "Add CropColorAssigner (known colors + hash fallback)"
```

---

### Task 7: `DateChip`

**Files:**
- Create: `GardenHarvest/Services/DateChip.swift`
- Test: `GardenHarvestTests/DateChipTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/DateChipTests.swift`:
```swift
import Testing
import Foundation
@testable import GardenHarvest

struct DateChipTests {
    @Test func todayReturnsStartOfReferenceDay() {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 4; components.hour = 15
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: components)!

        let result = DateChip.today.date(from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour], from: result)
        #expect(resultComponents.year == 2026)
        #expect(resultComponents.month == 7)
        #expect(resultComponents.day == 4)
        #expect(resultComponents.hour == 0)
    }

    @Test func yesterdaySubtractsOneDay() {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 4
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: components)!

        let result = DateChip.yesterday.date(from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        #expect(resultComponents.day == 3)
    }

    @Test func twoDaysAgoSubtractsTwoDays() {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 4
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: components)!

        let result = DateChip.twoDaysAgo.date(from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        #expect(resultComponents.day == 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/DateChipTests 2>&1 | tail -30`
Expected: FAIL — `DateChip` not found in scope.

- [ ] **Step 3: Write `DateChip.swift`**

`GardenHarvest/Services/DateChip.swift`:
```swift
import Foundation

enum DateChip: Int, CaseIterable {
    case today = 0
    case yesterday = 1
    case twoDaysAgo = 2

    var label: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .twoDaysAgo: return "2 days ago"
        }
    }

    func date(from reference: Date = .now, calendar: Calendar = .current) -> Date {
        let startOfReference = calendar.startOfDay(for: reference)
        return calendar.date(byAdding: .day, value: -rawValue, to: startOfReference) ?? startOfReference
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/DateChipTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Services/DateChip.swift GardenHarvestTests/DateChipTests.swift GardenHarvest.xcodeproj
git commit -m "Add DateChip (Today/Yesterday/2 days ago)"
```

---

### Task 8: `SeedDataService` — RAW parsing + synthetic history generation

**Files:**
- Create: `GardenHarvest/Seed/SeedDataService.swift`
- Test: `GardenHarvestTests/SeedDataServiceTests.swift`

This ports the prototype's `RAW` string and its `seed(n)` / `gen(base, year, scale, drop)` functions verbatim so the synthetic 2024/2025 history matches what was seen in the prototype. Reference values below were computed independently in Python using the exact same formula, to confirm the Swift port is correct (not just a faithful-looking transliteration).

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/SeedDataServiceTests.swift`:
```swift
import Testing
import Foundation
@testable import GardenHarvest

struct SeedDataServiceTests {
    @Test func seedIsDeterministicAndMatchesReferenceValues() {
        #expect(abs(SeedDataService.seed(2024) - 0.3445856476391782) < 0.0000001)
        #expect(abs(SeedDataService.seed(2025) - 0.9740680162558419) < 0.0000001)
    }

    @Test func parseBaseProducesAllOneHundredTenEntries() {
        let base = SeedDataService.parseBase()
        #expect(base.count == 110)
        #expect(base.first?.crop == "Asparagus")
        #expect(base.first?.ounces == 18)
        #expect(base.first?.monthDay == "03-10")
        #expect(base.last?.crop == "Strawberries")
        #expect(base.last?.ounces == 3.6)
    }

    @Test func parseBaseKeepsNoteOnEntriesThatHaveOne() {
        let base = SeedDataService.parseBase()
        let woody = base.first { $0.monthDay == "04-13" }
        #expect(woody?.note == "14 oz woody")
        #expect(woody?.ounces == 36)
    }

    @Test func generateProducesExpectedAsparagusEntryTwoYearsAgo() {
        let base = SeedDataService.parseBase()
        let entries = SeedDataService.generate(base: base, year: 2024, scale: 0.62, drop: 0.32)
        let asparagus = entries.first { $0.crop == "Asparagus" && $0.ounces == 10.5 }
        #expect(asparagus != nil)
        #expect(asparagus?.date == SeedDataService.date(year: 2024, monthDay: "03-09"))
    }

    @Test func generateProducesExpectedAsparagusEntryLastYear() {
        let base = SeedDataService.parseBase()
        let entries = SeedDataService.generate(base: base, year: 2025, scale: 0.84, drop: 0.18)
        let asparagus = entries.first { $0.crop == "Asparagus" && $0.ounces == 19.4 }
        #expect(asparagus != nil)
        #expect(asparagus?.date == SeedDataService.date(year: 2025, monthDay: "03-13"))
    }

    @Test func generateProducesExpectedMushroomsEntryBothYears() {
        let base = SeedDataService.parseBase()
        let entries2024 = SeedDataService.generate(base: base, year: 2024, scale: 0.62, drop: 0.32)
        let mushrooms2024 = entries2024.first { $0.crop == "Mushrooms" }
        #expect(mushrooms2024?.ounces == 5.4)
        #expect(mushrooms2024?.date == SeedDataService.date(year: 2024, monthDay: "03-14"))

        let entries2025 = SeedDataService.generate(base: base, year: 2025, scale: 0.84, drop: 0.18)
        let mushrooms2025 = entries2025.first { $0.crop == "Mushrooms" }
        #expect(mushrooms2025?.ounces == 5.5)
        #expect(mushrooms2025?.date == SeedDataService.date(year: 2025, monthDay: "03-09"))
    }

    @Test func currentYearEntriesPreserveOriginalOuncesAndNotes() {
        let seasonSeed = SeedDataService.buildSeasonSeed(currentYear: 2026)
        #expect(seasonSeed.currentYearEntries.count == 110)
        let woody = seasonSeed.currentYearEntries.first { $0.crop == "Asparagus" && $0.note == "14 oz woody" }
        #expect(woody?.ounces == 36)
        #expect(woody?.date == SeedDataService.date(year: 2026, monthDay: "04-13"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/SeedDataServiceTests 2>&1 | tail -30`
Expected: FAIL — `SeedDataService` not found in scope.

- [ ] **Step 3: Write `SeedDataService.swift`**

`GardenHarvest/Seed/SeedDataService.swift`:
```swift
import Foundation

enum SeedDataService {
    struct BaseEntry {
        let crop: String
        let ounces: Double
        let monthDay: String // "MM-DD"
        let note: String
    }

    struct GeneratedEntry {
        let crop: String
        let ounces: Double
        let date: Date
        let note: String
    }

    struct SeasonSeed {
        let currentYearEntries: [GeneratedEntry]
        let lastYearEntries: [GeneratedEntry]
        let twoYearsAgoEntries: [GeneratedEntry]
    }

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    // Real 2026 harvest data, transcribed from the user's `harvets.txt` and the
    // prototype's `RAW` constant. Format: "MM-DD|Crop|ounces|note".
    static let rawData = """
    03-10|Asparagus|18|
    03-12|Mushrooms|8|
    04-07|Asparagus|31|
    04-13|Asparagus|36|14 oz woody
    04-15|Asparagus|14|
    04-19|Asparagus|12|
    04-21|Asparagus|8|
    04-23|Asparagus|12|
    04-26|Asparagus|8|
    04-28|Asparagus|8|
    04-30|Asparagus|16|
    05-02|Asparagus|6|
    05-04|Asparagus|14.5|
    05-07|Asparagus|6|
    05-09|Asparagus|4|
    05-09|Strawberries|1|
    05-11|Strawberries|1|
    05-12|Asparagus|19.5|
    05-12|Artichoke|11.5|
    05-12|Radishes|6.75|
    05-12|Strawberries|1|
    05-13|Strawberries|0.75|
    05-14|Asparagus|13|
    05-15|Strawberries|3.5|
    05-16|Asparagus|3|
    05-16|Strawberries|2.75|
    05-18|Asparagus|1.5|
    05-18|Strawberries|1|
    05-19|Strawberries|4|
    05-20|Strawberries|1.5|
    05-20|Asparagus|8|
    05-23|Asparagus|12|
    05-23|Strawberries|4.5|
    05-23|Radishes|2.75|
    05-23|Artichoke|10.25|
    05-25|Strawberries|10.75|
    05-27|Asparagus|4|
    05-27|Strawberries|8.5|
    05-30|Asparagus|3|
    05-30|Strawberries|14|
    05-31|Strawberries|10|
    06-01|Strawberries|1.5|
    06-03|Strawberries|3.5|
    06-03|Asparagus|2|
    06-04|Strawberries|1|
    06-04|Blueberries|2|
    06-06|Asparagus|2|
    06-06|Strawberries|3.5|
    06-06|Raspberries|4|
    06-09|Asparagus|1.75|
    06-09|Strawberries|10.75|
    06-09|Raspberries|9.5|
    06-09|Blueberries|3|
    06-09|Artichoke|9|
    06-09|Artichoke|11.5|
    06-11|Raspberries|7.6|small
    06-11|Strawberries|9|
    06-11|Blueberries|1.2|
    06-11|Asparagus|5.2|
    06-11|Raspberries|1|large
    06-11|Boysenberries|2.15|
    06-13|Strawberries|5.5|
    06-13|Blueberries|1.2|
    06-13|Asparagus|1.1|
    06-13|Raspberries|0.6|large
    06-13|Boysenberries|0.75|
    06-14|Raspberries|4.5|small
    06-14|Raspberries|1|large
    06-14|Boysenberries|0.55|
    06-15|Blueberries|5|
    06-15|Raspberries|4.75|small
    06-15|Raspberries|0.75|large
    06-15|Strawberries|5|
    06-16|Boysenberries|1|
    06-16|Raspberries|4|small
    06-16|Raspberries|1.7|large
    06-16|Strawberries|0.7|
    06-17|Blueberries|2|
    06-17|Boysenberries|1.8|
    06-17|Raspberries|6.5|small
    06-17|Raspberries|5.75|large
    06-17|Strawberries|2.2|
    06-18|Peas|6.5|
    06-20|Raspberries|5|
    06-21|Strawberries|3.4|
    06-21|Blueberries|1.1|
    06-21|Raspberries|7.4|small
    06-21|Raspberries|9.8|large
    06-21|Peas|3.9|
    06-21|Artichoke|10.8|
    06-22|Boysenberries|3.4|
    06-23|Strawberries|3.2|
    06-23|Blueberries|2|
    06-23|Raspberries|3.4|small
    06-23|Raspberries|12.4|large
    06-23|Peas|4|
    06-23|Tomatoes Cherry|0.63|
    06-23|Boysenberries|0.5|
    06-25|Blueberries|0.75|
    06-25|Raspberries|3.5|small
    06-25|Raspberries|8.75|large
    06-25|Strawberries|3.4|
    06-25|Boysenberries|1|
    06-27|Blueberries|0.75|
    06-27|Raspberries|1|small
    06-27|Raspberries|12|large
    06-27|Strawberries|7.9|
    06-27|Peas|9.5|
    06-28|Raspberries|4.3|large
    06-28|Strawberries|3.6|
    """

    static func parseBase() -> [BaseEntry] {
        rawData
            .split(separator: "\n")
            .map { line -> BaseEntry in
                let parts = String(line).components(separatedBy: "|")
                let monthDay = parts[0]
                let crop = parts[1]
                let ounces = Double(parts[2]) ?? 0
                let note = parts.count > 3 ? parts[3] : ""
                return BaseEntry(crop: crop, ounces: ounces, monthDay: monthDay, note: note)
            }
    }

    /// Ports the prototype's `seed(n){ const x=Math.sin(n*127.1+311.7)*43758.5; return x-Math.floor(x); }`
    static func seed(_ n: Double) -> Double {
        let x = sin(n * 127.1 + 311.7) * 43758.5
        return x - x.rounded(.down)
    }

    static func date(year: Int, monthDay: String) -> Date? {
        let parts = monthDay.components(separatedBy: "-")
        guard parts.count == 2, let month = Int(parts[0]), let day = Int(parts[1]) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return utcCalendar.date(from: components)
    }

    /// Ports the prototype's `gen(base,year,scale,drop)`.
    static func generate(base: [BaseEntry], year: Int, scale: Double, drop: Double) -> [GeneratedEntry] {
        var out: [GeneratedEntry] = []
        let yearOffset = Double(year)
        for (i, entry) in base.enumerated() {
            let index = Double(i)
            if seed(index * 2.3 + yearOffset) < drop { continue }
            let jitter = 0.75 + seed(index * 3.7 + yearOffset) * 0.55
            let ounces = max(0.3, (entry.ounces * scale * jitter * 10).rounded() / 10)
            let shift = Int((seed(index * 5.1 + yearOffset) * 7).rounded(.down)) - 3
            guard let baseDate = date(year: year, monthDay: entry.monthDay) else { continue }
            let shiftedDate = utcCalendar.date(byAdding: .day, value: shift, to: baseDate) ?? baseDate
            out.append(GeneratedEntry(crop: entry.crop, ounces: ounces, date: shiftedDate, note: ""))
        }
        return out
    }

    /// Ports the prototype's `buildAll()`, generalized to any current year instead of the
    /// hardcoded 2026.
    static func buildSeasonSeed(currentYear: Int) -> SeasonSeed {
        let base = parseBase()
        let currentYearEntries: [GeneratedEntry] = base.compactMap { entry in
            guard let entryDate = date(year: currentYear, monthDay: entry.monthDay) else { return nil }
            return GeneratedEntry(crop: entry.crop, ounces: entry.ounces, date: entryDate, note: entry.note)
        }
        let lastYearEntries = generate(base: base, year: currentYear - 1, scale: 0.84, drop: 0.18)
        let twoYearsAgoEntries = generate(base: base, year: currentYear - 2, scale: 0.62, drop: 0.32)
        return SeasonSeed(
            currentYearEntries: currentYearEntries,
            lastYearEntries: lastYearEntries,
            twoYearsAgoEntries: twoYearsAgoEntries
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/SeedDataServiceTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Seed/SeedDataService.swift GardenHarvestTests/SeedDataServiceTests.swift GardenHarvest.xcodeproj
git commit -m "Port seed-data generator (RAW parser + seed()/gen() algorithm)"
```

---

### Task 9: Wire seeding into app launch

**Files:**
- Modify: `GardenHarvest/Seed/SeedDataService.swift`
- Modify: `GardenHarvest/GardenHarvestApp.swift`
- Test: `GardenHarvestTests/SeedIfNeededTests.swift`

- [ ] **Step 1: Write the failing test**

`GardenHarvestTests/SeedIfNeededTests.swift`:
```swift
import Testing
import SwiftData
import Foundation
@testable import GardenHarvest

struct SeedIfNeededTests {
    @Test func seedsTenKnownCropsAndThreeSeasonsOfEntries() throws {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        SeedDataService.seedIfNeeded(context: context, currentYear: 2026)

        let crops = try context.fetch(FetchDescriptor<Crop>())
        let entries = try context.fetch(FetchDescriptor<HarvestEntry>())
        #expect(crops.count == 10)
        #expect(crops.filter(\.isQuickLog).count == 8)
        #expect(entries.filter { Calendar.current.component(.year, from: $0.date) == 2026 }.count == 110)
        #expect(entries.count > 110)

        let raspberries = crops.first { $0.name == "Raspberries" }
        #expect(raspberries?.variants == ["small", "large"])
    }

    @Test func doesNotDuplicateOnSecondCall() throws {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        SeedDataService.seedIfNeeded(context: context, currentYear: 2026)
        SeedDataService.seedIfNeeded(context: context, currentYear: 2026)

        let crops = try context.fetch(FetchDescriptor<Crop>())
        #expect(crops.count == 10)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/SeedIfNeededTests 2>&1 | tail -30`
Expected: FAIL — `SeedDataService.seedIfNeeded` not found in scope.

- [ ] **Step 3: Add `seedIfNeeded` to `SeedDataService.swift`**

Append to `GardenHarvest/Seed/SeedDataService.swift` (inside the `SeedDataService` enum, after `buildSeasonSeed`):
```swift

    static let knownCrops: [(name: String, isQuickLog: Bool, variants: [String])] = [
        ("Asparagus", true, []),
        ("Strawberries", true, []),
        ("Raspberries", true, ["small", "large"]),
        ("Blueberries", true, []),
        ("Boysenberries", true, []),
        ("Artichoke", true, []),
        ("Peas", true, []),
        ("Radishes", true, []),
        ("Mushrooms", false, []),
        ("Tomatoes Cherry", false, [])
    ]

    static func seedIfNeeded(context: ModelContext, currentYear: Int) {
        let existingCrops = (try? context.fetch(FetchDescriptor<Crop>())) ?? []
        guard existingCrops.isEmpty else { return }

        for (index, crop) in knownCrops.enumerated() {
            let record = Crop(
                name: crop.name,
                colorHex: CropColorAssigner.colorHex(for: crop.name),
                isQuickLog: crop.isQuickLog,
                sortIndex: index,
                variants: crop.variants
            )
            context.insert(record)
        }

        let seasonSeed = buildSeasonSeed(currentYear: currentYear)
        let allGenerated = seasonSeed.currentYearEntries + seasonSeed.lastYearEntries + seasonSeed.twoYearsAgoEntries
        for generated in allGenerated {
            context.insert(HarvestEntry(cropName: generated.crop, ounces: generated.ounces, date: generated.date, note: generated.note))
        }

        try? context.save()
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GardenHarvestTests/SeedIfNeededTests 2>&1 | tail -30`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Wire it into the app entry point**

Replace `GardenHarvest/GardenHarvestApp.swift` with:
```swift
import SwiftUI
import SwiftData

@main
struct GardenHarvestApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: HarvestEntry.self, Crop.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            SeedStatusView()
                .task {
                    SeedDataService.seedIfNeeded(
                        context: container.mainContext,
                        currentYear: Calendar.current.component(.year, from: .now)
                    )
                }
        }
        .modelContainer(container)
    }
}

/// Temporary launch screen used only to visually confirm seeding worked in the simulator.
/// Replaced by RootView in Task 10.
private struct SeedStatusView: View {
    @Query private var crops: [Crop]
    @Query private var entries: [HarvestEntry]

    var body: some View {
        VStack(spacing: 8) {
            Text("Garden Harvest").font(.title)
            Text("\(crops.count) crops seeded")
            Text("\(entries.count) entries seeded")
        }
    }
}
```

- [ ] **Step 6: Build and run in the simulator to confirm seeding visually**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. Then boot the simulator and install/launch to confirm the screen reads "10 crops seeded" and "entries seeded" with a count greater than 110 (110 current-year + non-zero counts for the two synthetic years, since the drop rates are well under 100%).

- [ ] **Step 7: Commit**

```bash
git add GardenHarvest/Seed/SeedDataService.swift GardenHarvest/GardenHarvestApp.swift GardenHarvestTests/SeedIfNeededTests.swift GardenHarvest.xcodeproj
git commit -m "Wire SwiftData ModelContainer and first-launch seeding into the app entry point"
```

---

### Task 10: Tab shell — `AppTab`, `BottomTabBar`, `ComingSoonView`, `RootView`

**Files:**
- Create: `GardenHarvest/Views/AppTab.swift`
- Create: `GardenHarvest/Views/BottomTabBar.swift`
- Create: `GardenHarvest/Views/ComingSoonView.swift`
- Create: `GardenHarvest/Views/RootView.swift`
- Modify: `GardenHarvest/GardenHarvestApp.swift`

No unit tests this task — pure SwiftUI layout, verified manually in the simulator per the plan's testing strategy.

- [ ] **Step 1: Write `AppTab.swift`**

`GardenHarvest/Views/AppTab.swift`:
```swift
enum AppTab: Hashable {
    case home, log, unwrapped
}
```

- [ ] **Step 2: Write `BottomTabBar.swift`**

`GardenHarvest/Views/BottomTabBar.swift`:
```swift
import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: AppTab

    private let items: [(tab: AppTab, label: String, icon: String)] = [
        (.home, "Home", "house.fill"),
        (.log, "Log", "list.bullet"),
        (.unwrapped, "Unwrapped", "sparkles")
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.tab) { item in
                Button {
                    selectedTab = item.tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19))
                        Text(item.label)
                            .font(Theme.Font.body(10, weight: .bold))
                    }
                    .foregroundStyle(selectedTab == item.tab ? Theme.accent : Theme.sub)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
```

- [ ] **Step 3: Write `ComingSoonView.swift`**

`GardenHarvest/Views/ComingSoonView.swift`:
```swift
import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.Font.heading(24, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Coming soon")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.panelBackground.ignoresSafeArea())
    }
}
```

- [ ] **Step 4: Write `RootView.swift`**

`GardenHarvest/Views/RootView.swift`:
```swift
import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    Text("Home")
                case .log:
                    ComingSoonView(title: "Harvest Log")
                case .unwrapped:
                    ComingSoonView(title: "Unwrapped")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panelBackground.ignoresSafeArea())

            BottomTabBar(selectedTab: $selectedTab)
        }
    }
}
```

- [ ] **Step 5: Wire `RootView` into the app entry point**

Replace `GardenHarvest/GardenHarvestApp.swift`'s `WindowGroup` body with:
```swift
import SwiftUI
import SwiftData

@main
struct GardenHarvestApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: HarvestEntry.self, Crop.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    SeedDataService.seedIfNeeded(
                        context: container.mainContext,
                        currentYear: Calendar.current.component(.year, from: .now)
                    )
                }
        }
        .modelContainer(container)
    }
}
```

(This removes the temporary `SeedStatusView` from Task 9.)

- [ ] **Step 6: Build and run to verify tab switching**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. Boot the simulator, launch the app, and confirm: Home tab shows "Home" text, tapping Log/Unwrapped switches to their "Coming soon" placeholders, and the active tab icon/label turns the accent orange.

- [ ] **Step 7: Commit**

```bash
git add GardenHarvest/Views/AppTab.swift GardenHarvest/Views/BottomTabBar.swift GardenHarvest/Views/ComingSoonView.swift GardenHarvest/Views/RootView.swift GardenHarvest/GardenHarvestApp.swift GardenHarvest.xcodeproj
git commit -m "Add tab shell (RootView, BottomTabBar, ComingSoonView placeholders)"
```

---

### Task 11: Home screen — `CropTileView`, `AddCropTileView`, `HomeView`

**Files:**
- Create: `GardenHarvest/Views/Home/CropTileView.swift`
- Create: `GardenHarvest/Views/Home/AddCropTileView.swift`
- Create: `GardenHarvest/Views/Home/HomeView.swift`
- Modify: `GardenHarvest/Views/RootView.swift`

No unit tests this task — verified manually.

- [ ] **Step 1: Write `CropTileView.swift`**

`GardenHarvest/Views/Home/CropTileView.swift`:
```swift
import SwiftUI

struct CropTileView: View {
    let crop: Crop
    let totalOunces: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: crop.colorHex))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(initials)
                            .font(Theme.Font.mono(15, weight: .bold))
                            .foregroundStyle(.white)
                    )
                Text(crop.name)
                    .font(Theme.Font.body(12.5, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(totalOunces > 0 ? WeightFormatter.poundsAndOunces(totalOunces) : "—")
                    .font(Theme.Font.mono(11))
                    .foregroundStyle(Theme.sub)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .frame(minHeight: 104)
            .frame(maxWidth: .infinity)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: Theme.tileRadius).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.tileRadius))
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        String(crop.name.filter(\.isLetter).prefix(2)).uppercased()
    }
}
```

- [ ] **Step 2: Write `AddCropTileView.swift`**

`GardenHarvest/Views/Home/AddCropTileView.swift`:
```swift
import SwiftUI

struct AddCropTileView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("+")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.sub)
                    )
                Text("Add veg")
                    .font(Theme.Font.body(12, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .frame(minHeight: 104)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 3: Write `HomeView.swift`**

`GardenHarvest/Views/Home/HomeView.swift`:
```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Crop.sortIndex) private var crops: [Crop]
    @Query private var allEntries: [HarvestEntry]

    let onSelectCrop: (String) -> Void
    let onAddCrop: () -> Void

    private var season: Int { Calendar.current.component(.year, from: .now) }

    private var seasonEntries: [HarvestEntry] {
        allEntries.filter { Calendar.current.component(.year, from: $0.date) == season }
    }

    private var totalsByCrop: [String: Double] {
        Dictionary(grouping: seasonEntries, by: \.cropName).mapValues { $0.reduce(0) { $0 + $1.ounces } }
    }

    private var quickCrops: [Crop] {
        crops.filter(\.isQuickLog)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                totalCard
                Text("Quick log — tap to add")
                    .font(Theme.Font.mono(11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Theme.sub)
                grid
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(seasonLabel)
                .font(Theme.Font.mono(11, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
            Text("What did you pick?")
                .font(Theme.Font.heading(27, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var seasonLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(season) season · \(formatter.string(from: .now))"
    }

    private var totalCard: some View {
        let total = seasonEntries.reduce(0) { $0 + $1.ounces }
        return VStack(alignment: .leading, spacing: 4) {
            Text(WeightFormatter.poundsAndOunces(total))
                .font(Theme.Font.heading(34, weight: .heavy))
            Text("picked this season across \(totalsByCrop.keys.count) crops")
                .font(Theme.Font.body(12.5, weight: .semibold))
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 11), count: 3), spacing: 11) {
            ForEach(quickCrops) { crop in
                CropTileView(crop: crop, totalOunces: totalsByCrop[crop.name] ?? 0) {
                    onSelectCrop(crop.name)
                }
            }
            AddCropTileView(action: onAddCrop)
        }
    }
}
```

- [ ] **Step 4: Wire `HomeView` into `RootView` (no-op callbacks for now)**

Replace `GardenHarvest/Views/RootView.swift`'s `.home` case:
```swift
import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(onSelectCrop: { _ in }, onAddCrop: { })
                case .log:
                    ComingSoonView(title: "Harvest Log")
                case .unwrapped:
                    ComingSoonView(title: "Unwrapped")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panelBackground.ignoresSafeArea())

            BottomTabBar(selectedTab: $selectedTab)
        }
    }
}
```

- [ ] **Step 5: Build and run to verify the Home screen renders real data**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. Launch in the simulator and confirm: the total card shows a nonzero lb/oz total for the current season, the 3-column grid shows the 8 quick-log crop tiles (Asparagus, Strawberries, Raspberries, Blueberries, Boysenberries, Artichoke, Peas, Radishes) each with the correct colored disc and running total, and a dashed "+ Add veg" tile. Tapping a tile does nothing yet (callback is a no-op) — expected at this stage.

- [ ] **Step 6: Commit**

```bash
git add GardenHarvest/Views/Home/CropTileView.swift GardenHarvest/Views/Home/AddCropTileView.swift GardenHarvest/Views/Home/HomeView.swift GardenHarvest/Views/RootView.swift GardenHarvest.xcodeproj
git commit -m "Add Home screen (total card, quick-log grid)"
```

---

### Task 12: Navigation shell — `HomeContainerView`, `ToastView`

**Files:**
- Create: `GardenHarvest/Views/Home/ToastView.swift`
- Create: `GardenHarvest/Views/Home/HomeContainerView.swift`
- Modify: `GardenHarvest/Views/RootView.swift`

No unit tests this task — navigation/toast timing is verified manually.

- [ ] **Step 1: Write `ToastView.swift`**

`GardenHarvest/Views/Home/ToastView.swift`:
```swift
import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.Font.body(13.5, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Theme.ink)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
    }
}
```

- [ ] **Step 2: Write `HomeContainerView.swift` with placeholder Entry/Add destinations**

`GardenHarvest/Views/Home/HomeContainerView.swift`:
```swift
import SwiftUI

enum HomeRoute: Hashable {
    case entry(cropName: String)
    case add
}

struct HomeContainerView: View {
    @State private var path: [HomeRoute] = []
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSelectCrop: { name in path.append(.entry(cropName: name)) },
                onAddCrop: { path.append(.add) }
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .entry(let cropName):
                    VStack(spacing: 16) {
                        Text("Entry: \(cropName)")
                        Button("Save") {
                            path.removeLast()
                            showToast("🌱 Logged \(cropName)")
                        }
                        Button("Back") { path.removeLast() }
                    }
                case .add:
                    VStack(spacing: 16) {
                        Text("Add a vegetable")
                        Button("Back") { path.removeLast() }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 96)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: toastMessage)
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }
}
```

- [ ] **Step 3: Wire `HomeContainerView` into `RootView`**

Replace `GardenHarvest/Views/RootView.swift`'s `.home` case:
```swift
import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeContainerView()
                case .log:
                    ComingSoonView(title: "Harvest Log")
                case .unwrapped:
                    ComingSoonView(title: "Unwrapped")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panelBackground.ignoresSafeArea())

            BottomTabBar(selectedTab: $selectedTab)
        }
    }
}
```

- [ ] **Step 4: Build and run to verify navigation and toast**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. In the simulator: tapping a crop tile pushes the placeholder "Entry: {crop}" screen; tapping "Save" pops back to Home and shows a toast that reads "🌱 Logged {crop}" and disappears after ~2.4s; tapping "+ Add veg" pushes the placeholder "Add a vegetable" screen, and "Back" pops back on both.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Views/Home/ToastView.swift GardenHarvest/Views/Home/HomeContainerView.swift GardenHarvest/Views/RootView.swift GardenHarvest.xcodeproj
git commit -m "Add navigation shell (HomeContainerView, toast) with placeholder destinations"
```

---

### Task 13: `EntryView` — log a harvest

**Files:**
- Create: `GardenHarvest/Theme/ChipButtonStyle.swift`
- Create: `GardenHarvest/Views/Entry/EntryView.swift`
- Modify: `GardenHarvest/Views/Home/HomeContainerView.swift`

No unit tests this task — the underlying formatters/services are already unit-tested (Tasks 5–8); this task is UI composition, verified manually.

- [ ] **Step 1: Write `ChipButtonStyle.swift`**

`GardenHarvest/Theme/ChipButtonStyle.swift`:
```swift
import SwiftUI

struct ChipButtonStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.mono(13, weight: .heavy))
            .foregroundStyle(isSelected ? .white : Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Theme.accent : Theme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
```

- [ ] **Step 2: Write `EntryView.swift`**

`GardenHarvest/Views/Entry/EntryView.swift`:
```swift
import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct EntryView: View {
    let cropName: String
    let onSaved: (String) -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var crops: [Crop]

    @State private var ouncesText: String = ""
    @State private var note: String = ""
    @State private var selectedVariant: String?
    @State private var selectedDateChip: DateChip = .today
    @State private var photoData: Data?
    @State private var photoSource: String?
    @State private var showPhotoDialog = false
    @State private var showPhotosPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    private var crop: Crop? {
        crops.first { $0.name == cropName }
    }

    private var ounces: Double {
        Double(ouncesText) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                topBar
                cropHeader
                ouncesDisplay
                bumpChips
                if let variants = crop?.variants, !variants.isEmpty {
                    variantChips(variants)
                }
                keypad
                dateChips
                photoAndNoteRow
                if photoData != nil {
                    photoPreview
                }
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .confirmationDialog("Add a photo of this pick", isPresented: $showPhotoDialog, titleVisibility: .visible) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photoData = data
                    photoSource = "Library"
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button("‹ Back", action: onBack)
                .font(Theme.Font.body(15, weight: .bold))
                .foregroundStyle(Theme.accent)
            Spacer()
            Text("LOG HARVEST")
                .font(Theme.Font.mono(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
            Spacer()
            Color.clear.frame(width: 44)
        }
    }

    private var cropHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: crop?.colorHex ?? "#999999"))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initials)
                        .font(Theme.Font.mono(12, weight: .bold))
                        .foregroundStyle(.white)
                )
            Text(cropName)
                .font(Theme.Font.heading(24, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private var initials: String {
        String(cropName.filter(\.isLetter).prefix(2)).uppercased()
    }

    private var ouncesDisplay: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(ouncesText.isEmpty ? "0" : ouncesText)
                .font(Theme.Font.heading(64, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text("oz")
                .font(Theme.Font.mono(18, weight: .bold))
                .foregroundStyle(Theme.sub)
        }
    }

    private var bumpChips: some View {
        HStack(spacing: 8) {
            ForEach([("−1", -1.0), ("+0.5", 0.5), ("+1", 1.0), ("+5", 5.0)], id: \.0) { label, delta in
                Button(label) { bump(by: delta) }
                    .buttonStyle(ChipButtonStyle())
            }
        }
    }

    private func variantChips(_ variants: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(variants, id: \.self) { variant in
                Button(variant) {
                    selectedVariant = (selectedVariant == variant) ? nil : variant
                }
                .buttonStyle(ChipButtonStyle(isSelected: selectedVariant == variant))
            }
        }
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 9) {
            ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"], id: \.self) { key in
                Button {
                    handleKey(key)
                } label: {
                    Text(key)
                        .font(Theme.Font.heading(22, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .background(key == "⌫" ? Color.clear : Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var dateChips: some View {
        HStack(spacing: 8) {
            ForEach(DateChip.allCases, id: \.self) { chip in
                Button(chip.label) { selectedDateChip = chip }
                    .buttonStyle(ChipButtonStyle(isSelected: selectedDateChip == chip))
            }
        }
    }

    private var photoAndNoteRow: some View {
        HStack(spacing: 9) {
            Button {
                if photoData == nil {
                    showPhotoDialog = true
                } else {
                    photoData = nil
                    photoSource = nil
                }
            } label: {
                Text(photoData != nil ? "✓ Photo" : "＋ Photo")
                    .font(Theme.Font.body(13.5, weight: .bold))
                    .foregroundStyle(photoData != nil ? .white : Theme.sub)
                    .padding(.horizontal, 15)
                    .frame(height: 44)
            }
            .background(photoData != nil ? Theme.accent2 : Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(photoData != nil ? Theme.accent2 : Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            TextField("Note — e.g. some woody", text: $note)
                .font(Theme.Font.body(13.5))
                .padding(.horizontal, 13)
                .frame(height: 44)
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var photoPreview: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.card)
                .frame(width: 52, height: 52)
                .overlay {
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            VStack(alignment: .leading, spacing: 1) {
                Text("Photo attached")
                    .font(Theme.Font.body(13.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("From \(photoSource ?? "Library")")
                    .font(Theme.Font.mono(11.5))
                    .foregroundStyle(Theme.sub)
            }
            Spacer()
            Button("Remove") {
                photoData = nil
                photoSource = nil
            }
            .font(Theme.Font.body(13, weight: .bold))
            .foregroundStyle(Theme.accent)
        }
        .padding(12)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(ounces > 0 ? "Log \(WeightFormatter.ounces(ounces)) oz \(cropName)" : "Enter a weight")
                .font(Theme.Font.body(16, weight: .heavy))
                .foregroundStyle(ounces > 0 ? .white : Theme.sub)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(ounces > 0 ? Theme.accent : Theme.hairline)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(ounces <= 0)
    }

    private func bump(by delta: Double) {
        let newValue = max(0, ((ounces + delta) * 10).rounded() / 10)
        ouncesText = newValue == 0 ? "" : WeightFormatter.ounces(newValue)
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            ouncesText = String(ouncesText.dropLast())
        } else if key == "." {
            if !ouncesText.contains(".") {
                ouncesText += ouncesText.isEmpty ? "0." : "."
            }
        } else {
            let candidate = ouncesText + key
            if candidate.filter(\.isNumber).count <= 5 {
                ouncesText = candidate
            }
        }
    }

    private func save() {
        guard ounces > 0 else { return }
        let entry = HarvestEntry(
            cropName: cropName,
            ounces: ounces,
            date: selectedDateChip.date(),
            note: note,
            variant: selectedVariant,
            photoData: photoData,
            photoSource: photoSource
        )
        modelContext.insert(entry)
        try? modelContext.save()
        onSaved("🌱 Logged \(WeightFormatter.ounces(ounces)) oz \(cropName)")
    }
}
```

- [ ] **Step 3: Wire `EntryView` into `HomeContainerView`'s `.entry` destination**

Replace `GardenHarvest/Views/Home/HomeContainerView.swift`:
```swift
import SwiftUI

enum HomeRoute: Hashable {
    case entry(cropName: String)
    case add
}

struct HomeContainerView: View {
    @State private var path: [HomeRoute] = []
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSelectCrop: { name in path.append(.entry(cropName: name)) },
                onAddCrop: { path.append(.add) }
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .entry(let cropName):
                    EntryView(
                        cropName: cropName,
                        onSaved: { message in
                            path.removeLast()
                            showToast(message)
                        },
                        onBack: { path.removeLast() }
                    )
                case .add:
                    VStack(spacing: 16) {
                        Text("Add a vegetable")
                        Button("Back") { path.removeLast() }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 96)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: toastMessage)
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }
}
```

- [ ] **Step 4: Build and run to verify the logging flow**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. In the simulator: tap "Raspberries" (a crop with variants) — confirm the "small"/"large" chips appear and toggle; type a weight on the keypad, confirm the big oz display and Save button label update live; tap a bump chip and confirm the oz display updates; type a note; tap Save and confirm it pops back to Home, the total card and that crop's tile total increased, and the toast appears/disappears. Repeat for a non-variant crop (e.g. Strawberries) and confirm no variant chips render.

- [ ] **Step 5: Commit**

```bash
git add GardenHarvest/Theme/ChipButtonStyle.swift GardenHarvest/Views/Entry/EntryView.swift GardenHarvest/Views/Home/HomeContainerView.swift GardenHarvest.xcodeproj
git commit -m "Add EntryView (keypad, chips, photo dialog, save flow)"
```

---

### Task 14: Camera capture — `CameraPicker`

**Files:**
- Create: `GardenHarvest/Views/Entry/CameraPicker.swift`
- Modify: `GardenHarvest/Views/Entry/EntryView.swift`

No unit tests this task — `UIImagePickerController` is not available in the Simulator (camera source), so this is verified manually on a physical device; the Simulator build only confirms it compiles and that the "Choose from Library" path still works.

- [ ] **Step 1: Write `CameraPicker.swift`**

`GardenHarvest/Views/Entry/CameraPicker.swift`:
```swift
import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                onCapture(data)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
```

- [ ] **Step 2: Wire the camera into `EntryView`**

In `GardenHarvest/Views/Entry/EntryView.swift`, add a `.fullScreenCover` modifier right after the existing `.onChange(of: photoPickerItem)` block (still inside the outer `ScrollView`'s modifier chain):
```swift
        .onChange(of: photoPickerItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photoData = data
                    photoSource = "Library"
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                onCapture: { data in
                    photoData = data
                    photoSource = "Camera"
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
```

- [ ] **Step 3: Build to verify it compiles**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. In the simulator, confirm "Choose from Library" still works end-to-end (attaches a photo, shows the preview row, Remove clears it). "Take Photo" will present the camera UI but the Simulator has no camera hardware — full capture must be verified on a physical device later.

- [ ] **Step 4: Commit**

```bash
git add GardenHarvest/Views/Entry/CameraPicker.swift GardenHarvest/Views/Entry/EntryView.swift GardenHarvest.xcodeproj
git commit -m "Add camera capture (UIImagePickerController wrapper)"
```

---

### Task 15: `AddCropView` — new vegetable

**Files:**
- Create: `GardenHarvest/Views/Add/AddCropView.swift`
- Modify: `GardenHarvest/Views/Home/HomeContainerView.swift`

No unit tests this task — UI composition over already-tested `MasterCropList`/`CropColorAssigner`, verified manually.

- [ ] **Step 1: Write `AddCropView.swift`**

`GardenHarvest/Views/Add/AddCropView.swift`:
```swift
import SwiftUI
import SwiftData

struct AddCropView: View {
    let onCommitted: (String) -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var crops: [Crop]
    @State private var name: String = ""
    @State private var addToQuickLog = true
    @FocusState private var isFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var suggestions: [String] {
        guard !trimmedName.isEmpty else { return [] }
        let query = trimmedName.lowercased()
        return Array(MasterCropList.names.filter { $0.lowercased().contains(query) }.prefix(6))
    }

    private func isKnown(_ cropName: String) -> Bool {
        crops.contains { $0.name.lowercased() == cropName.lowercased() }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                topBar
                Text("What did you grow?")
                    .font(Theme.Font.body(13, weight: .semibold))
                    .foregroundStyle(Theme.sub)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Type a vegetable…", text: $name)
                    .font(Theme.Font.heading(17, weight: .bold))
                    .focused($isFocused)
                    .padding(14)
                    .background(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                if !suggestions.isEmpty {
                    suggestionList
                }
                quickLogToggleRow
                commitButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { isFocused = true }
    }

    private var topBar: some View {
        HStack {
            Button("‹ Back", action: onBack)
                .font(Theme.Font.body(15, weight: .bold))
                .foregroundStyle(Theme.accent)
            Spacer()
            Text("NEW VEGETABLE")
                .font(Theme.Font.mono(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
            Spacer()
            Color.clear.frame(width: 44)
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    name = suggestion
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: CropColorAssigner.colorHex(for: suggestion)))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Text(String(suggestion.filter(\.isLetter).prefix(2)).uppercased())
                                    .font(Theme.Font.mono(12, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        Text(suggestion)
                            .font(Theme.Font.body(15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if isKnown(suggestion) {
                            Text("grown before")
                                .font(Theme.Font.mono(10.5, weight: .bold))
                                .foregroundStyle(Theme.accent2)
                        }
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                if suggestion != suggestions.last {
                    Divider()
                }
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
    }

    private var quickLogToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Add to quick log")
                    .font(Theme.Font.body(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Show it on your home screen")
                    .font(Theme.Font.body(11.5))
                    .foregroundStyle(Theme.sub)
            }
            Spacer()
            Toggle("", isOn: $addToQuickLog)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(12)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var commitButton: some View {
        Button {
            commit()
        } label: {
            Text(trimmedName.isEmpty ? "Name your vegetable" : "Add \(trimmedName) & log it")
                .font(Theme.Font.body(16, weight: .heavy))
                .foregroundStyle(trimmedName.isEmpty ? Theme.sub : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(trimmedName.isEmpty ? Theme.hairline : Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(trimmedName.isEmpty)
    }

    private func commit() {
        guard !trimmedName.isEmpty else { return }
        let canonicalName = MasterCropList.names.first { $0.lowercased() == trimmedName.lowercased() } ?? trimmedName
        if !crops.contains(where: { $0.name == canonicalName }) {
            let crop = Crop(
                name: canonicalName,
                colorHex: CropColorAssigner.colorHex(for: canonicalName),
                isQuickLog: addToQuickLog,
                sortIndex: (crops.map(\.sortIndex).max() ?? -1) + 1,
                variants: []
            )
            modelContext.insert(crop)
            try? modelContext.save()
        }
        onCommitted(canonicalName)
    }
}
```

- [ ] **Step 2: Wire `AddCropView` into `HomeContainerView`'s `.add` destination**

Replace `GardenHarvest/Views/Home/HomeContainerView.swift`:
```swift
import SwiftUI

enum HomeRoute: Hashable {
    case entry(cropName: String)
    case add
}

struct HomeContainerView: View {
    @State private var path: [HomeRoute] = []
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSelectCrop: { name in path.append(.entry(cropName: name)) },
                onAddCrop: { path.append(.add) }
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .entry(let cropName):
                    EntryView(
                        cropName: cropName,
                        onSaved: { message in
                            path.removeLast()
                            showToast(message)
                        },
                        onBack: { path.removeLast() }
                    )
                case .add:
                    AddCropView(
                        onCommitted: { cropName in
                            path.removeLast()
                            path.append(.entry(cropName: cropName))
                        },
                        onBack: { path.removeLast() }
                    )
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 96)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: toastMessage)
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }
}
```

- [ ] **Step 3: Build and run to verify the add-vegetable flow**

Run:
```bash
xcodegen generate
xcodebuild -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. In the simulator: tap "+ Add veg", type "kal" and confirm "Kale" appears as a suggestion (no "grown before" tag since it isn't seeded); tap it, confirm the name field fills in; leave "Add to quick log" on; tap "Add Kale & log it"; confirm it lands on the Entry screen for Kale, and back on Home, a new "Kale" tile appears in the quick-log grid with the assigned hash color.

- [ ] **Step 4: Commit**

```bash
git add GardenHarvest/Views/Add/AddCropView.swift GardenHarvest/Views/Home/HomeContainerView.swift GardenHarvest.xcodeproj
git commit -m "Add AddCropView (autocomplete, quick-log toggle, commit flow)"
```

---

### Task 16: Final integration pass

**Files:** none created/modified — verification only.

- [ ] **Step 1: Run the full unit test suite**

Run: `xcodegen generate && xcodebuild test -scheme GardenHarvest -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -40`
Expected: `** TEST SUCCEEDED **` with all of `ColorHexTests`, `ModelPersistenceTests`, `MasterCropListTests`, `WeightFormatterTests`, `CropColorAssignerTests`, `DateChipTests`, `SeedDataServiceTests`, and `SeedIfNeededTests` passing.

- [ ] **Step 2: Manual verification checklist in the simulator**

Boot `iPhone 17 Pro`, install and launch the app fresh (erase the simulator first if it still has state from earlier tasks: `xcrun simctl erase "iPhone 17 Pro"`), and walk through:
- [ ] Home shows a nonzero season total and 8 quick-log tiles with correct colors/totals, plus "+ Add veg".
- [ ] Tapping a variant crop (Raspberries) shows "small"/"large" chips; a non-variant crop (Strawberries) shows none.
- [ ] Keypad entry, bump chips, and date chips all update the displayed oz/state correctly.
- [ ] Attaching a photo via "Choose from Library" shows the preview row; "Remove" clears it.
- [ ] Saving returns to Home, updates the tile/total, and shows the toast, which disappears after ~2.4s.
- [ ] "+ Add veg" → typing a new name → autocomplete suggestions appear → committing lands on Entry for the new crop → back on Home, the new crop's tile appears in the grid.
- [ ] Log and Unwrapped tabs show their "Coming soon" placeholders and the tab bar highlights the active tab.

- [ ] **Step 3: Commit (only if the checklist above required any fixes)**

```bash
git add -A
git commit -m "Final integration fixes for core logging loop"
```
(Skip this step if no changes were needed.)
