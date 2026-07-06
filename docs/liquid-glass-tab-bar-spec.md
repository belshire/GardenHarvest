# Liquid Glass Tab Bar — Spec & Plan

**Status:** Proposal (no implementation yet)
**Date:** 2026-07-06
**Scope:** Modernize the bottom tab bar with iOS 26 Liquid Glass styling while keeping the app's colored illustrated tab icons.

---

## 1. Current state

The app does **not** use SwiftUI's native `TabView`. It has a fully custom bar:

- `GardenHarvest/Views/AppTab.swift` — `enum AppTab { case home, log, unwrapped }`.
- `GardenHarvest/Views/BottomTabBar.swift` — an `HStack` of buttons. Each tab shows a **full-color illustrated asset** (`TabIcons/garden-bed`, `TabIcons/notebook`, `TabIcons/cornucopia`, 56×44pt, sourced from `vegetable-icons/`) plus a 10pt bold rounded label ("Pick", "Log", "Report"). Selection state is expressed by `saturation(0/1)` + `opacity(0.6/1)` on the icon and `Theme.accent` vs `Theme.sub` on the label. Background is `.ultraThinMaterial` with a 1px `Theme.hairline` top rule; fixed padding (`top 8 / bottom 20 / horizontal 12`).
- `GardenHarvest/Views/RootView.swift` — a `ZStack(alignment: .bottom)`: a `switch selectedTab` picks `HomeContainerView` / `LogView` / `ReportView`, with `BottomTabBar` overlaid at the bottom. The bar is faded out while the keyboard is visible (workaround for safe-area shrinking), and a launch overlay + keyboard pre-warm live here too.
- **Deployment target:** iOS **17.0** (`IPHONEOS_DEPLOYMENT_TARGET = 17.0` in `GardenHarvest.xcodeproj/project.pbxproj`; `project.yml` is reference-only — the pbxproj is managed by hand, never run xcodegen).

The desaturate-when-unselected treatment of the illustrated icons is a distinctive part of the app's personality. Any modernization should preserve it.

## 2. What iOS 26 gives us (verified facts)

- **Native `TabView` gets Liquid Glass automatically** when the app is compiled with the iOS 26 SDK (Xcode 26). No code change is needed for the visual; on devices running iOS ≤ 18 the same binary shows the old tab bar style. ([Donny Wals — Exploring tab bars on iOS 26](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/))
- **`.tabBarMinimizeBehavior(.onScrollDown)`** shrinks the native bar into a compact floating capsule as content scrolls, giving content more room. ([Create with Swift](https://www.createwithswift.com/making-the-tab-bar-collapse-while-scrolling/))
- **`tabViewBottomAccessory`** floats a view above the native bar (shown on all tabs), and a `Tab(role: .search)` yields the floating search pill. ([Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/), [Apple WWDC25 session 323](https://developer.apple.com/videos/play/wwdc2025/323/))
- **`.glassEffect(_:in:)` and `GlassEffectContainer`** apply the Liquid Glass material to *custom* views — shapeable, tintable, optionally `.interactive()`. These APIs are **iOS 26+ only** and must be gated with `if #available(iOS 26, *)`; the accepted fallback on older OSes is `.ultraThinMaterial` (optionally with a gradient/stroke to fake the look). ([Swift with Majid — Glassifying tabs](https://swiftwithmajid.com/2025/06/24/glassifying-tabs-in-swiftui/), [ioscompatibility.com/modifiers/glass-effect](https://ioscompatibility.com/modifiers/glass-effect), [Netanel Shoshan — Backporting Liquid Glass](https://netanel.io/blog/backporting-liquid-glass/))
- **Tab bar icons are template/monochrome by default.** UIKit/SwiftUI tab bars use only the alpha channel of the item image and tint it; full color requires `renderingMode(.original)` / `withRenderingMode(.alwaysOriginal)`, which has historically worked but is explicitly *against* the HIG (glyphs are expected to be monochrome, and the iOS 26 glass bar re-tints items for legibility against varying content behind the glass). Behavior of `.original`-rendered multicolor images inside the iOS 26 Liquid Glass bar is **not documented or guaranteed** — community reports show items being forced through the system's monochrome/tint pipeline, and even where full color survives, the fixed native item size (~25–30pt glyph) is far smaller than our 56×44 illustrations, and our saturation-based selection treatment is impossible. ([Apple HIG — Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars), [Apple Dev Forums thread 698198](https://developer.apple.com/forums/thread/698198))

## 3. Option A — Adopt native `TabView`

Replace `RootView`'s `ZStack` + `BottomTabBar` with `TabView(selection:)` using the iOS 18 `Tab` builder syntax; simply rebuilding with the iOS 26 SDK then yields the system Liquid Glass bar.

**Gains**

- The exact system Liquid Glass bar: refraction, scroll-edge behavior, automatic dark mode, Dynamic Type/larger-accessibility layouts, VoiceOver traits — all free and always matching future OS releases.
- `.tabBarMinimizeBehavior(.onScrollDown)` minimize-to-capsule, `tabViewBottomAccessory`, optional `.search` tab role.
- Deletes the keyboard-hiding workaround in `RootView` (system bar handles the keyboard correctly) and lazy tab loading/state preservation for free.

**Losses / risks**

- **The illustrated colored icons almost certainly stop being what they are today.** Realistic outcomes:
  - Provide SF Symbol or template glyphs → clean native look, but the garden illustrations are gone from the bar (the app's most distinctive chrome).
  - Try `Image("TabIcons/…").renderingMode(.original)` → undocumented in the glass bar; may render tinted anyway, may break in a point release; even if it works, icons are constrained to system item size (~25–30pt) and lose the saturation/selection treatment. HIG-non-compliant.
- Lose exact control of bar height, 56×44 icon size, label font (`Theme.Font.body(10, .bold)`), and the desaturation selection effect.
- On iOS 17/18 devices the same code shows the *old* system tab bar — arguably a downgrade from the current custom bar on those OSes.
- Requires building with Xcode 26 / iOS 26 SDK (also true for Option B).

## 4. Option B — Keep the custom bar, glass the chrome (recommended)

Keep `BottomTabBar` exactly as it is functionally — same icons, sizes, labels, desaturation selection — and replace its background treatment with real Liquid Glass on iOS 26, falling back to the current material on older OSes.

Sketch (illustrative only):

```swift
// BottomTabBar.body, background section
.padding(...)                       // as today
.modifier(TabBarGlass())            // replaces .background(.ultraThinMaterial) + hairline

struct TabBarGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(),
                             in: .capsule)          // or .rect(cornerRadius: Theme.cardRadius)
                .padding(.horizontal, 16)           // float the capsule off the edges
                .padding(.bottom, 8)
        } else {
            content
                .background(.ultraThinMaterial)     // current look, unchanged
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
        }
    }
}
```

Design decisions to make during implementation:

- **Floating capsule vs full-width slab.** The iOS 26 system bar is a floating capsule inset from the screen edges; adopting that shape reads as "modern" instantly. Requires letting content scroll under the bar (it already does — the bar is an overlay in `RootView`'s `ZStack`) and possibly adding bottom `contentMargins` to the three tab views so last rows aren't hidden (the Add Crop FAB clearance work from commit c4a7d5c is precedent).
- Optionally wrap bar + the Add Crop FAB in a `GlassEffectContainer` later so the two glass elements blend/morph correctly when near each other (iOS 26 only, purely additive).
- Optional stretch: hand-rolled minimize-on-scroll (shrink to icon-only capsule via a scroll-offset preference). Not in initial scope.

**Gains**

- Colored illustrated icons, sizes, fonts, and the saturation selection effect are preserved **exactly**.
- Real system Liquid Glass material on iOS 26 — not an imitation — with graceful `.ultraThinMaterial` fallback that is literally today's look on iOS 17/18.
- Small, low-risk diff confined to `BottomTabBar.swift` (+ minor `RootView`/content-inset tweaks). Keyboard workaround and launch flow untouched.

**Losses / risks**

- No free minimize-on-scroll, bottom accessory, or search-tab role; any of those would be hand-built.
- We keep owning accessibility and future-proofing of the bar (as we do today).
- If Apple evolves the tab bar idiom further, we track it manually.

## 5. Comparison

| | A: Native TabView | B: Custom bar + `.glassEffect` |
|---|---|---|
| Liquid Glass material | System bar, automatic | Real `.glassEffect`, applied by us |
| Colored illustrated icons | At risk — likely tinted/monochrome, size-constrained, undocumented behavior | Preserved exactly |
| Desaturation selection effect | Impossible | Preserved |
| Minimize on scroll | Free (`.tabBarMinimizeBehavior`) | Manual (out of scope initially) |
| Bottom accessory / search role | Free | Manual |
| Accessibility | System-provided | Ours (labels already present) |
| iOS 17/18 appearance | Old system tab bar (visual downgrade) | Identical to today |
| Effort | Medium + design rework of icons | Small |
| Risk | Medium-high (icon identity) | Low |

## 6. Deployment target implications

- Keep `IPHONEOS_DEPLOYMENT_TARGET = 17.0`. `glassEffect`/`GlassEffectContainer` are gated at runtime with `if #available(iOS 26, *)`; no target bump needed.
- Must build with **Xcode 26 / iOS 26 SDK**. Note: once built with the iOS 26 SDK, *other* system chrome (alerts, sheets, switches) also adopts Liquid Glass on iOS 26 devices regardless of which option we pick — worth a quick visual pass of the app. (`UIDesignRequiresCompatibility` Info.plist key exists as a temporary opt-out but is deprecated and not recommended.)
- Edit `project.pbxproj` by hand if new files are added — **never run xcodegen** (wipes signing).

## 7. Recommendation

**Option B.** The illustrated colored tab icons with the desaturation selection effect are the app's signature chrome; Option A trades them for system convenience and relies on undocumented behavior to keep any color at all. Option B delivers the genuine iOS 26 glass material (the visible "modern" payoff) for a fraction of the risk, keeps iOS 17/18 users on exactly today's design, and leaves the door open to Option A later if the icon set is ever redesigned as glyphs.

### Implementation plan (Option B)

1. **Prereq:** confirm the project builds under Xcode 26 / iOS 26 SDK; do a smoke pass of system-chrome changes. *(0.5 day, one-time)*
2. **`BottomTabBar.swift`:** extract the background treatment into a `TabBarGlass` ViewModifier as sketched above; `#available(iOS 26, *)` → `.glassEffect(.regular.interactive(), in: .capsule)` with edge insets, else current `.ultraThinMaterial` + hairline unchanged. Decide capsule vs slab against design mocks. *(0.5 day)*
3. **`RootView.swift` / tab content views:** if going floating-capsule, verify bottom `contentMargins`/safe-area padding so list bottoms and the Add Crop FAB clear the bar on all three tabs. *(0.5 day)*
4. **QA:** iOS 26 simulator + device (light/dark, Reduce Transparency, keyboard show/hide path) and iOS 17/18 simulator (pixel-identical to today). *(0.5 day)*
5. **Later, optional:** `GlassEffectContainer` around bar + FAB; hand-rolled minimize-on-scroll.

**Total initial effort: ~2 days.** Files touched: `GardenHarvest/Views/BottomTabBar.swift`, possibly `GardenHarvest/Views/RootView.swift` and the three tab root views; no new files required (no pbxproj edits) unless `TabBarGlass` gets its own file.

## Sources

- [Donny Wals — Exploring tab bars on iOS 26 with Liquid Glass](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [Donny Wals — Designing custom UI with Liquid Glass on iOS 26](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/)
- [Swift with Majid — Glassifying tabs in SwiftUI](https://swiftwithmajid.com/2025/06/24/glassifying-tabs-in-swiftui/)
- [Create with Swift — Making the tab bar collapse while scrolling](https://www.createwithswift.com/making-the-tab-bar-collapse-while-scrolling/)
- [Apple — WWDC25 session 323: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Apple HIG — Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Apple Developer Forums — Tab bar items load as colored](https://developer.apple.com/forums/thread/698198)
- [ioscompatibility.com — glassEffect modifier availability](https://ioscompatibility.com/modifiers/glass-effect)
- [Netanel Shoshan — Backporting Liquid Glass to older iOS](https://netanel.io/blog/backporting-liquid-glass/)
