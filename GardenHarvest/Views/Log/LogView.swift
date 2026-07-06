import SwiftUI
import SwiftData

/// Multi-year "Almanac" harvest log: year stepper, season summary, crop
/// filter with an across-the-years dossier, and collapsible month sections.
struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [HarvestEntry]
    @Query private var crops: [Crop]

    @State private var logYear = DateProvider.currentYear
    @State private var logCrop: String?
    @State private var expandedMonths: Set<String> = []
    @State private var didExpandLatestMonth = false
    @State private var showCropSheet = false
    @State private var showImportSheet = false
    /// Row whose Edit/Delete actions are revealed (tap toggles, one at a time).
    @State private var revealedEntryID: PersistentIdentifier?
    @State private var entryToEdit: HarvestEntry?
    @State private var entryToDelete: HarvestEntry?

    /// Everything the Log derives from the entry list, computed once per
    /// data/filter change (not on every body evaluation — grouping thousands
    /// of entries inline made scrolling jitter when many rows were visible).
    @State private var derived = DerivedData()

    /// Cached derivations, rebuilt in `rebuildDerivedData()`.
    private struct DerivedData {
        /// Distinct years present in the entries, newest first.
        var years: [Int] = []
        /// Per-year picking count and crop count, unfiltered (summary card).
        var entryCountByYear: [Int: Int] = [:]
        var cropCountByYear: [Int: Int] = [:]
        /// Per-year grand total, unfiltered (filter sheet subtitle).
        var totalByYear: [Int: Double] = [:]
        /// Per-year crop totals sorted descending (filter sheet rows).
        var cropTotalsByYear: [Int: [(name: String, total: Double)]] = [:]
        /// Per-year total and count after the crop filter (summary card,
        /// dossier rows). Matches the unfiltered values when no crop is set.
        var filteredTotalByYear: [Int: Double] = [:]
        var filteredCountByYear: [Int: Int] = [:]
        /// Per-year month groups after the crop filter, newest month first.
        var monthGroupsByYear: [Int: [LogGrouping.MonthGroup]] = [:]
        /// Biggest month total per year, floored at 1 (bar denominators).
        var maxMonthTotalByYear: [Int: Double] = [:]
        /// Crop name → stored color, for O(1) lookups per picking row.
        var colorHexByCrop: [String: String] = [:]
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
        .sheet(isPresented: $showImportSheet) {
            ImportSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $entryToEdit) { entry in
            EntryView(
                cropName: entry.cropName,
                editing: entry,
                onSaved: { _ in entryToEdit = nil },
                onBack: { entryToEdit = nil }
            )
        }
        .confirmationDialog(
            deleteConfirmationTitle,
            isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete entry", role: .destructive) { deleteRevealedEntry() }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        }
        .onAppear {
            rebuildDerivedData()
            expandLatestMonthOnce()
        }
        .onChange(of: allEntries) { rebuildDerivedData() }
        .onChange(of: crops) { rebuildDerivedData() }
        .onChange(of: logCrop) { rebuildDerivedData() }
    }

    // MARK: Derived data

    /// One pass over the entries rebuilds every cached derivation. Runs when
    /// the store or the crop filter changes; body evaluations only read the
    /// cache.
    private func rebuildDerivedData() {
        let calendar = Calendar.current
        var data = DerivedData()
        let byYear = Dictionary(grouping: allEntries) { calendar.component(.year, from: $0.date) }
        data.years = byYear.keys.sorted(by: >)
        for (year, entries) in byYear {
            data.entryCountByYear[year] = entries.count
            data.cropCountByYear[year] = Set(entries.map(\.cropName)).count
            data.totalByYear[year] = entries.reduce(0) { $0 + $1.ounces }
            data.cropTotalsByYear[year] = LogGrouping.totalsByCrop(entries)
                .map { (name: $0.key, total: $0.value) }
                .sorted { $0.total > $1.total }
            let filtered = logCrop.map { crop in entries.filter { $0.cropName == crop } } ?? entries
            data.filteredTotalByYear[year] = filtered.reduce(0) { $0 + $1.ounces }
            data.filteredCountByYear[year] = filtered.count
            let groups = LogGrouping.monthGroups(of: filtered, calendar: calendar)
            data.monthGroupsByYear[year] = groups
            data.maxMonthTotalByYear[year] = max(groups.map(\.total).max() ?? 0, 1)
        }
        data.colorHexByCrop = Dictionary(
            crops.map { ($0.name, $0.colorHex) },
            uniquingKeysWith: { first, _ in first }
        )
        derived = data
    }

    private var years: [Int] { derived.years }

    // MARK: Year stepper

    private var yearStepper: some View {
        YearStepper(years: years, selectedYear: logYear, onSelect: setYear) {
            PageHeaderTitle(eyebrow: "Harvest log", title: String(logYear))
        }
    }

    /// Animated so the year pager slides when the year is changed from the
    /// stepper or the dossier rather than by swiping.
    private func setYear(_ year: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            logYear = year
        }
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
    /// Lazy so month sections (and their expanded rows) are only laid out as
    /// they approach the viewport instead of all at once.
    private func yearPage(for year: Int) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                summaryCard(for: year)
                HStack(spacing: 8) {
                    cropFilterPill
                    importButton
                }
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
        let total = derived.filteredTotalByYear[year] ?? 0
        let subline: String
        if let logCrop {
            let count = derived.filteredCountByYear[year] ?? 0
            subline = "\(count) \(logCrop) pickings in \(String(year))"
        } else {
            let entryCount = derived.entryCountByYear[year] ?? 0
            let cropCount = derived.cropCountByYear[year] ?? 0
            subline = "\(entryCount) pickings · \(cropCount) crops"
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

    /// Square button beside the filter pill opening the note-import sheet.
    private var importButton: some View {
        Button {
            showImportSheet = true
        } label: {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: Crop dossier

    private func dossier(for crop: String, in year: Int) -> some View {
        // With a crop filter active the cached filtered totals are exactly
        // this crop's per-year totals.
        let rows = years.map { year in
            (year: year, total: derived.filteredTotalByYear[year] ?? 0)
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

    @ViewBuilder
    private func monthList(for year: Int) -> some View {
        let groups = derived.monthGroupsByYear[year] ?? []
        let maxTotal = derived.maxMonthTotalByYear[year] ?? 1
        if groups.isEmpty {
            Text(emptyLabel(for: year))
                .font(Theme.Font.body(13))
                .italic()
                .foregroundStyle(Theme.sub)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            ForEach(groups, id: \.month) { group in
                LogMonthSection(
                    group: group,
                    fillFraction: max(0.06, group.total / maxTotal),
                    barFill: filterColor ?? Theme.accent2,
                    isExpanded: expandedMonths.contains(expansionKey(year: year, month: group.month)),
                    revealedEntryID: revealedEntryID,
                    colorHex: colorHex(for:),
                    onToggle: { toggleMonth(group.month, in: year) },
                    onRowTap: { entry in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            revealedEntryID = revealedEntryID == entry.id ? nil : entry.id
                        }
                    },
                    onEdit: { entry in entryToEdit = entry },
                    onDelete: { entry in entryToDelete = entry }
                )
                // Month cards sit 8pt apart but 12pt from the cards above,
                // matching the previous nested-VStack spacing.
                .padding(.top, group.month == groups.first?.month ? 0 : -4)
            }
        }
    }

    private var deleteConfirmationTitle: String {
        guard let entry = entryToDelete else { return "Delete this entry?" }
        return "Delete \(WeightFormatter.ounces(entry.ounces)) oz \(entry.cropName)?"
    }

    private func deleteRevealedEntry() {
        guard let entry = entryToDelete else { return }
        entryToDelete = nil
        withAnimation(.easeInOut(duration: 0.15)) {
            revealedEntryID = nil
            modelContext.delete(entry)
        }
        try? modelContext.save()
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

    /// Opening the Log defaults to the most recent month with entries expanded
    /// (all other months collapsed). Runs once; manual toggles win afterwards.
    private func expandLatestMonthOnce() {
        guard !didExpandLatestMonth else { return }
        didExpandLatestMonth = true
        // No crop filter is active on first appearance, so the cached groups
        // are the unfiltered year. Groups are sorted newest month first, so
        // `.first` is the latest month that has entries. If the current year
        // is empty, fall back to the newest year with data.
        var year = logYear
        if derived.monthGroupsByYear[year]?.isEmpty != false, let newest = derived.years.first {
            year = newest
        }
        if let latest = derived.monthGroupsByYear[year]?.first?.month {
            logYear = year
            expandedMonths.insert(expansionKey(year: year, month: latest))
        }
    }

    // MARK: Crop colors & totals

    private func colorHex(for name: String) -> String {
        derived.colorHexByCrop[name] ?? CropColorAssigner.colorHex(for: name)
    }

    /// Crops present in the active year, sorted by that year's total descending.
    private var yearCropTotals: [(name: String, total: Double)] {
        derived.cropTotalsByYear[logYear] ?? []
    }

    private var yearTotal: Double {
        derived.totalByYear[logYear] ?? 0
    }
}
