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

    private var filteredEntries: [HarvestEntry] {
        guard let logCrop else { return yearEntries }
        return yearEntries.filter { $0.cropName == logCrop }
    }

    private var monthGroups: [LogGrouping.MonthGroup] {
        LogGrouping.monthGroups(of: filteredEntries)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                yearStepper
                summaryPager
                cropFilterPill
                if let logCrop {
                    dossier(for: logCrop)
                }
                monthList
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 128)
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
            VStack(spacing: 2) {
                Text("Harvest log")
                    .font(Theme.Font.mono(10.5, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(Theme.accent)
                Text(String(logYear))
                    .font(Theme.Font.heading(32))
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            stepButton(glyph: "›", enabled: canGoNewer) {
                if let yearIndex, canGoNewer { setYear(years[yearIndex - 1]) }
            }
        }
        .padding(.top, 2)
    }

    /// Animated so the summary pager slides when the year is changed from the
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

    // MARK: Summary card

    /// Summary card paged horizontally: swiping left/right steps to the
    /// newer/older year, mirroring the ‹/› stepper. The crop filter and the
    /// rest of the screen follow `logYear` and are untouched by the swipe.
    private var summaryPager: some View {
        Group {
            if years.contains(logYear) {
                summaryCard(for: logYear)
                    .hidden()
                    .overlay(
                        TabView(selection: $logYear) {
                            // Oldest → newest so a leftward swipe advances to
                            // the newer year, matching the stepper layout.
                            ForEach(years.reversed(), id: \.self) { year in
                                summaryCard(for: year).tag(year)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    )
            } else {
                summaryCard(for: logYear)
            }
        }
    }

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
        return VStack(alignment: .leading, spacing: 4) {
            Text(WeightFormatter.poundsAndOunces(total))
                .font(Theme.Font.heading(30))
            Text(subline)
                .font(Theme.Font.body(12.5, weight: .semibold))
                .opacity(0.92)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(filterColor ?? Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .animation(.easeInOut(duration: 0.2), value: logCrop)
    }

    /// The selected crop's color, `nil` when showing all crops.
    private var filterColor: Color? {
        logCrop.map { Color(hex: colorHex(for: $0)) }
    }

    // MARK: Crop filter pill

    private var cropFilterPill: some View {
        Button {
            showCropSheet = true
        } label: {
            HStack(spacing: 9) {
                if let logCrop {
                    Circle()
                        .fill(Color(hex: colorHex(for: logCrop)))
                        .frame(width: 14, height: 14)
                } else {
                    Circle()
                        .fill(allCropsGradient)
                        .frame(width: 14, height: 14)
                }
                Text(logCrop ?? "All crops")
                    .font(Theme.Font.body(14.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var allCropsGradient: LinearGradient {
        LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Crop dossier

    private func dossier(for crop: String) -> some View {
        let rows = years.map { year in
            (year: year, total: LogGrouping.entries(in: year, from: allEntries)
                .filter { $0.cropName == crop }
                .reduce(0) { $0 + $1.ounces })
        }
        return VStack(alignment: .leading, spacing: 12) {
            CropDossierCard(
                colorHex: colorHex(for: crop),
                rows: rows,
                activeYear: logYear,
                onSelectYear: { setYear($0) }
            )
            Text("\(crop) in \(String(logYear))")
                .font(Theme.Font.mono(11, weight: .heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
        }
    }

    // MARK: Months

    private var monthList: some View {
        let groups = monthGroups
        let maxTotal = max(groups.map(\.total).max() ?? 0, 1)
        return Group {
            if groups.isEmpty {
                Text(emptyLabel)
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
                            isExpanded: expandedMonths.contains(expansionKey(month: group.month)),
                            colorHex: colorHex(for:),
                            onToggle: { toggleMonth(group.month) }
                        )
                    }
                }
            }
        }
    }

    private var emptyLabel: String {
        if let logCrop {
            return "No \(logCrop) logged in \(String(logYear))"
        }
        return "Nothing logged in \(String(logYear)) yet"
    }

    private func expansionKey(month: Int) -> String { "\(logYear)-\(month)" }

    private func toggleMonth(_ month: Int) {
        let key = expansionKey(month: month)
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
            expandedMonths.insert(expansionKey(month: peak))
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
