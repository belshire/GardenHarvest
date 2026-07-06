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
                summaryCard
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
                items: allTimeCropTotals,
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
                if let yearIndex, canGoOlder { logYear = years[yearIndex + 1] }
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
                if let yearIndex, canGoNewer { logYear = years[yearIndex - 1] }
            }
        }
        .padding(.top, 2)
    }

    private func stepButton(glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(enabled ? Theme.ink : Theme.hairline)
                .frame(width: 44, height: 44)
                .background(enabled ? Theme.card : Color.clear)
                .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                .clipShape(Circle())
                .shadow(color: Color(hex: "#1e3214").opacity(enabled ? 0.08 : 0), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Summary card

    private var summaryCard: some View {
        let total = yearEntries.reduce(0) { $0 + $1.ounces }
        let cropCount = Set(yearEntries.map(\.cropName)).count
        return VStack(alignment: .leading, spacing: 4) {
            Text(WeightFormatter.poundsAndOunces(total))
                .font(Theme.Font.heading(30))
            Text("\(yearEntries.count) pickings · \(cropCount) crops")
                .font(Theme.Font.body(12.5, weight: .semibold))
                .opacity(0.92)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
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
                onSelectYear: { logYear = $0 }
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

    /// Every crop that appears in any year, sorted by all-time total descending.
    private var allTimeCropTotals: [(name: String, total: Double)] {
        LogGrouping.totalsByCrop(allEntries)
            .map { (name: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
}
