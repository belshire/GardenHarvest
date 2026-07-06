import SwiftUI
import SwiftData

/// Season harvest report ("unwrapped"): hero total, Season MVP, expandable
/// top-crop bars, the "When it peaked" timeline, an AI-insight placeholder,
/// and the shareable harvest card.
struct ReportView: View {
    @Query private var allEntries: [HarvestEntry]
    @Query private var crops: [Crop]

    @State private var expandedCrop: String?
    @State private var showShareCard = false

    /// The season being viewed; defaults to the current one and is stepped
    /// through `availableYears`. Everything below (rankings, totals, MVP,
    /// timeline, share payload) derives from this, not the wall clock.
    @State private var season = DateProvider.currentYear

    /// Years with entries plus the current year, newest first, so a fresh
    /// January can still step back to last season's report.
    private var availableYears: [Int] {
        ReportStats.availableReportYears(in: allEntries, currentYear: DateProvider.currentYear)
    }

    private var seasonEntries: [HarvestEntry] {
        LogGrouping.entries(in: season, from: allEntries)
    }

    private var rankedCrops: [(name: String, total: Double)] {
        ReportStats.rankedCrops(seasonEntries)
    }

    private var seasonTotal: Double {
        seasonEntries.reduce(0) { $0 + $1.ounces }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                YearStepper(years: availableYears, selectedYear: season, onSelect: setSeason) {
                    PageHeaderTitle(eyebrow: "\(String(season)) season", title: "Harvest report")
                }

                hero

                if let mvp = rankedCrops.first {
                    mvpCard(for: mvp.name)
                }

                if !rankedCrops.isEmpty {
                    sectionLabel("Top crops")
                    topCropList
                }

                if !seasonEntries.isEmpty {
                    sectionLabel("When it peaked")
                    SeasonTimelineChart(buckets: ReportStats.halfMonthBuckets(of: seasonEntries))
                }

                AIInsightCard()

                Button {
                    showShareCard = true
                } label: {
                    Text("Share my harvest card")
                        .font(Theme.Font.body(15, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 128)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showShareCard) {
            HarvestShareOverlay(model: shareCardModel)
                .presentationBackground(Color(hex: "#121a0e").opacity(0.62))
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 6) {
            Text(WeightFormatter.poundsAndOunces(seasonTotal))
                .font(Theme.Font.heading(52, weight: .heavy))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("of homegrown goodness")
                .font(Theme.Font.body(14, weight: .semibold))
                .foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    // MARK: Season MVP

    private func mvpCard(for crop: String) -> some View {
        VStack(spacing: 0) {
            Text("Season MVP")
                .font(Theme.Font.mono(10.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(2)
                .opacity(0.85)
            CropIconPlate(
                cropName: crop,
                colorHex: colorHex(for: crop),
                plateSize: 78,
                iconSize: 58,
                discSize: 62
            )
            .padding(.top, 13)
            .padding(.bottom, 6)
            Text(crop)
                .font(Theme.Font.heading(26, weight: .heavy))
                .padding(.bottom, 2)
            Text(ReportStats.superlativeTitle(for: crop, year: season))
                .font(Theme.Font.body(13.5, weight: .semibold))
                .opacity(0.95)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Theme.accent2)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    // MARK: Top crops

    private var topCropList: some View {
        let top = rankedCrops.prefix(6)
        let maxTotal = max(top.first?.total ?? 0, 1)
        return VStack(alignment: .leading, spacing: 12) {
            ForEach(top, id: \.name) { crop in
                TopCropRow(
                    name: crop.name,
                    valueString: WeightFormatter.poundsAndOunces(crop.total),
                    fillFraction: max(0.06, crop.total / maxTotal),
                    colorHex: colorHex(for: crop.name),
                    isExpanded: expandedCrop == crop.name,
                    timeline: expandedCrop == crop.name
                        ? ReportStats.cropTimeline(for: crop.name, seasonEntries: seasonEntries)
                        : nil,
                    onToggle: { toggleCrop(crop.name) }
                )
            }
        }
    }

    private func setSeason(_ year: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            season = year
            expandedCrop = nil
        }
    }

    private func toggleCrop(_ name: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            expandedCrop = expandedCrop == name ? nil : name
        }
    }

    // MARK: Share card

    private var shareCardModel: HarvestShareCardModel {
        let top = rankedCrops.prefix(3).map { crop in
            HarvestShareCardModel.TopCrop(
                name: crop.name,
                valueString: WeightFormatter.poundsAndOunces(crop.total),
                colorHex: colorHex(for: crop.name)
            )
        }
        return HarvestShareCardModel(
            season: season,
            totalString: WeightFormatter.poundsAndOunces(seasonTotal),
            cropCount: rankedCrops.count,
            mvpName: rankedCrops.first?.name,
            mvpTitle: rankedCrops.first.map { ReportStats.superlativeTitle(for: $0.name, year: season) },
            mvpColorHex: rankedCrops.first.map { colorHex(for: $0.name) },
            topCrops: top,
            peakLabel: ReportStats.peakLabel(of: seasonEntries) ?? "—"
        )
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.body(11, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Theme.sub)
            .padding(.top, 4)
    }

    private func colorHex(for name: String) -> String {
        crops.first { $0.name == name }?.colorHex ?? CropColorAssigner.colorHex(for: name)
    }
}
