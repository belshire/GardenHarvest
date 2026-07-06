import SwiftUI
import SwiftData

/// Multi-year "Almanac" harvest log: year stepper, season summary, crop
/// filter with an across-the-years dossier, and collapsible month sections.
struct LogView: View {
    @Query private var allEntries: [HarvestEntry]
    @Query private var crops: [Crop]

    @State private var logYear = Calendar.current.component(.year, from: .now)
    @State private var logCrop: String?
    @State private var expandedMonths: Set<String> = []
    @State private var didExpandPeakMonth = false
    @State private var showCropSheet = false

    private var years: [Int] { LogGrouping.years(in: allEntries) }

    private var yearEntries: [HarvestEntry] {
        LogGrouping.entries(in: logYear, from: allEntries)
    }

    var body: some View {
        VStack(spacing: 12) {
            yearStepper
                .padding(.horizontal, 20)
                .padding(.top, 8)
            yearPager
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .sheet(isPresented: $showCropSheet) {
            CropFilterSheet(
                items: yearCropTotals,
                allCropsTotal: yearTotal,
                subtitle: "Totals for \(String(logYear)) · sums to \(WeightFormatter.poundsAndOunces(yearTotal))",
                selected: logCrop,
                colorHex: colorHex(for:),
                onSelect: { name in
                    logCrop = name
                    showCropSheet = false
                }
            )
            .presentationDetents([.fraction(0.62), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear(perform: expandPeakMonthOnce)
    }

    // MARK: Year stepper

    private var yearIndex: Int? { years.firstIndex(of: logYear) }
    private var canGoOlder: Bool {
        guard let yearIndex else { return false }
        return yearIndex < years.count - 1
    }
    private var canGoNewer: Bool { (yearIndex ?? 0) > 0 }

    private var yearStepper: some View {
        HStack(spacing: 10) {
            stepButton(glyph: "‹", enabled: canGoOlder) {
                if let yearIndex, canGoOlder { setYear(years[yearIndex + 1]) }
            }
            PageHeaderTitle(eyebrow: "Harvest log", title: String(logYear))
                .frame(maxWidth: .infinity)
            stepButton(glyph: "›", enabled: canGoNewer) {
                if let yearIndex, canGoNewer { setYear(years[yearIndex - 1]) }
            }
        }
        .padding(.top, 2)
    }

    /// Animated so the year pager slides when the year is changed from the
    /// stepper or the dossier rather than by swiping.
    private func setYear(_ year: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            logYear = year
        }
    }

    private func stepButton(glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(enabled ? Theme.accent : Theme.ink.opacity(0.16))
                .padding(.bottom, 2)
                .frame(width: 46, height: 46)
                .background(enabled ? Theme.card : Color.clear)
                .overlay(Circle().stroke(enabled ? Theme.ink.opacity(0.16) : Theme.hairline, lineWidth: 1.5))
                .clipShape(Circle())
                .shadow(color: Color(hex: "#1e3214").opacity(enabled ? 0.08 : 0), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Year pager

    /// Each year is a full page — summary card, filter pill, dossier, and
    /// month list — so swiping the header drags the whole view in and out,
    /// like a navigation-view swipe. Swiping left/right steps to the
    /// newer/older year, mirroring the ‹/› stepper. The crop filter is
    /// untouched by the swipe.
    private var yearPager: some View {
        Group {
            if years.contains(logYear) {
                TabView(selection: $logYear) {
                    // Oldest → newest so a leftward swipe advances to the
                    // newer year, matching the stepper layout.
                    ForEach(years.reversed(), id: \.self) { year in
                        yearPage(for: year).tag(year)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // The page-style TabView pre-renders neighboring pages and
                // won't re-render them while offscreen, so a filter change
                // would leave stale cards sliding in. Rebuild pages on change.
                .id(logCrop)
            } else {
                yearPage(for: logYear)
            }
        }
    }

    /// One year's scrollable content; pages keep independent scroll positions.
    private func yearPage(for year: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                summaryCard(for: year)
                cropFilterPill
                if let logCrop {
                    dossier(for: logCrop, in: year)
                }
                monthList(for: year)
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 128)
        }
    }

    // MARK: Summary card

    /// Unfiltered: the year's grand total on the accent card. Filtered: the
    /// crop's yearly total on a card tinted with the crop's color.
    private func summaryCard(for year: Int) -> some View {
        let entries = LogGrouping.entries(in: year, from: allEntries)
        let counted = logCrop.map { crop in entries.filter { $0.cropName == crop } } ?? entries
        let total = counted.reduce(0) { $0 + $1.ounces }
        let subline: String
        if let logCrop {
            subline = "\(counted.count) \(logCrop) pickings in \(String(year))"
        } else {
            let cropCount = Set(entries.map(\.cropName)).count
            subline = "\(entries.count) pickings · \(cropCount) crops"
        }
        return TotalInfoCard(
            total: total,
            caption: subline,
            background: filterColor ?? Theme.accent
        ) {
            filterIconPlate(plateSize: 54, iconSize: 42, discSize: 46)
        }
    }

    /// The selected crop's color, `nil` when showing all crops.
    private var filterColor: Color? {
        logCrop.map { Color(hex: colorHex(for: $0)) }
    }

    /// Plate for the active filter: the crop's vegetable icon when filtered
    /// (initials disc when that crop has none), the cornucopia when showing
    /// all crops. The solid plate keeps the icon legible on any card color.
    private func filterIconPlate(plateSize: CGFloat, iconSize: CGFloat, discSize: CGFloat) -> some View {
        CropIconPlate(
            cropName: logCrop ?? "All crops",
            colorHex: logCrop.map { colorHex(for: $0) } ?? "#999999",
            plateSize: plateSize,
            iconSize: iconSize,
            discSize: discSize,
            assetOverride: logCrop == nil ? CropIconAssigner.allCropsAssetName : nil
        )
    }

    // MARK: Crop filter pill

    private var cropFilterPill: some View {
        Button {
            showCropSheet = true
        } label: {
            HStack(spacing: 9) {
                filterIconPlate(plateSize: 26, iconSize: 20, discSize: 22)
                Text(logCrop ?? "All crops")
                    .font(Theme.Font.body(14.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: Crop dossier

    private func dossier(for crop: String, in year: Int) -> some View {
        let rows = years.map { year in
            (year: year, total: LogGrouping.entries(in: year, from: allEntries)
                .filter { $0.cropName == crop }
                .reduce(0) { $0 + $1.ounces })
        }
        return VStack(alignment: .leading, spacing: 12) {
            CropDossierCard(
                colorHex: colorHex(for: crop),
                rows: rows,
                activeYear: year,
                onSelectYear: { setYear($0) }
            )
            Text("\(crop) in \(String(year))")
                .font(Theme.Font.mono(11, weight: .heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
        }
    }

    // MARK: Months

    private func monthList(for year: Int) -> some View {
        let entries = LogGrouping.entries(in: year, from: allEntries)
        let filtered = logCrop.map { crop in entries.filter { $0.cropName == crop } } ?? entries
        let groups = LogGrouping.monthGroups(of: filtered)
        let maxTotal = max(groups.map(\.total).max() ?? 0, 1)
        return Group {
            if groups.isEmpty {
                Text(emptyLabel(for: year))
                    .font(Theme.Font.body(13))
                    .italic()
                    .foregroundStyle(Theme.sub)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(groups, id: \.month) { group in
                        LogMonthSection(
                            group: group,
                            fillFraction: max(0.06, group.total / maxTotal),
                            barFill: filterColor ?? Theme.accent2,
                            isExpanded: expandedMonths.contains(expansionKey(year: year, month: group.month)),
                            colorHex: colorHex(for:),
                            onToggle: { toggleMonth(group.month, in: year) }
                        )
                    }
                }
            }
        }
    }

    private func emptyLabel(for year: Int) -> String {
        if let logCrop {
            return "No \(logCrop) logged in \(String(year))"
        }
        return "Nothing logged in \(String(year)) yet"
    }

    private func expansionKey(year: Int, month: Int) -> String { "\(year)-\(month)" }

    private func toggleMonth(_ month: Int, in year: Int) {
        let key = expansionKey(year: year, month: month)
        withAnimation(.easeInOut(duration: 0.15)) {
            if expandedMonths.contains(key) {
                expandedMonths.remove(key)
            } else {
                expandedMonths.insert(key)
            }
        }
    }

    /// Opening the Log defaults to the current season with its peak month expanded.
    private func expandPeakMonthOnce() {
        guard !didExpandPeakMonth else { return }
        didExpandPeakMonth = true
        if let peak = LogGrouping.peakMonth(of: yearEntries) {
            expandedMonths.insert(expansionKey(year: logYear, month: peak))
        }
    }

    // MARK: Crop colors & totals

    private func colorHex(for name: String) -> String {
        crops.first { $0.name == name }?.colorHex ?? CropColorAssigner.colorHex(for: name)
    }

    /// Crops present in the active year, sorted by that year's total descending.
    private var yearCropTotals: [(name: String, total: Double)] {
        LogGrouping.totalsByCrop(yearEntries)
            .map { (name: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    private var yearTotal: Double {
        yearEntries.reduce(0) { $0 + $1.ounces }
    }
}
