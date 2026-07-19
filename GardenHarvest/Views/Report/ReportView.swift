import SwiftUI
import SwiftData

/// Season harvest report ("unwrapped"): hero total, Season MVP, expandable
/// top-crop bars, the "When it peaked" timeline, the Fun Facts deck, the
/// AI story of the season, and the shareable harvest card.
struct ReportView: View {
    @Query private var allEntries: [HarvestEntry]
    @Query private var crops: [Crop]

    @State private var expandedCrop: String?
    @State private var showShareCard = false

    /// The season being viewed; defaults to the current one and is stepped
    /// through `availableYears`. Everything below (rankings, totals, MVP,
    /// timeline, share payload) derives from this, not the wall clock.
    @State private var season = DateProvider.currentYear

    /// Insight cards for the current season: instant template wording,
    /// upgraded in place by the on-device model when available. Regenerated
    /// whenever the season's entries change (see insightKey).
    @State private var insights: [Insight] = []

    /// The on-device model's "story of the season"; nil (section hidden)
    /// until generated, and only ever set on Apple Intelligence devices.
    @State private var story: String?

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

                if !insights.isEmpty {
                    InsightDeck(insights: insights, colorHex: colorHex(for:), resolveIcon: { CropIconResolver.resolve(name: $0, in: crops) })
                        .id(season)
                }

                if let story {
                    sectionLabel("The story of the season")
                    storyCard(story)
                }

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
        .task(id: insightKey) { await refreshInsights() }
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
                discSize: 62,
                resolvedIcon: CropIconResolver.resolve(name: crop, in: crops)
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

    /// Changes whenever the viewed season or its data changes, driving
    /// .task(id:) so insights regenerate mid-season as new harvests land.
    private var insightKey: String {
        "\(season)|\(InsightStore.fingerprint(of: seasonEntries))"
    }

    @MainActor
    private func refreshInsights() async {
        let entries = seasonEntries
        let facts = InsightFacts.topFacts(in: entries)
        guard !facts.isEmpty else {
            insights = []
            story = nil
            return
        }
        let fingerprint = InsightStore.fingerprint(of: entries)

        if let cached = InsightStore.load(season: season), cached.fingerprint == fingerprint {
            insights = cached.insights
            story = cached.story
            if story != nil { return }
        } else {
            insights = TemplateComposer().compose(facts: facts, season: season)
            story = nil
            InsightStore.save(
                .init(fingerprint: fingerprint, insights: insights, story: nil),
                season: season
            )
        }

        if #available(iOS 26.0, *), FoundationModelComposer.isAvailable {
            let notes = InsightFacts.storyNotes(in: entries)
            // The fingerprint re-check guards against BOTH staleness kinds while
            // the story generated: entries changed within this season, or the
            // user stepped to another season (seasonEntries re-derives from the
            // current one). Don't narrow it to a season-only comparison.
            guard let text = await FoundationModelComposer.storyText(facts: facts, notes: notes, season: season),
                  fingerprint == InsightStore.fingerprint(of: seasonEntries)
            else { return }
            withAnimation(.easeInOut(duration: 0.3)) { story = text }
            InsightStore.save(
                .init(fingerprint: fingerprint, insights: insights, story: text),
                season: season
            )
        }
    }

    // MARK: Share card

    private var shareCardModel: HarvestShareCardModel {
        let runnersUp = rankedCrops.dropFirst().prefix(4).map { crop in
            HarvestShareCardModel.TopCrop(
                name: crop.name,
                valueString: WeightFormatter.poundsAndOunces(crop.total),
                colorHex: colorHex(for: crop.name),
                icon: CropIconResolver.resolve(name: crop.name, in: crops)
            )
        }
        return HarvestShareCardModel(
            season: season,
            totalString: WeightFormatter.poundsAndOunces(seasonTotal),
            cropCount: rankedCrops.count,
            mvpName: rankedCrops.first?.name,
            mvpTitle: rankedCrops.first.map { ReportStats.superlativeTitle(for: $0.name, year: season) },
            mvpColorHex: rankedCrops.first.map { colorHex(for: $0.name) },
            mvpValueString: rankedCrops.first.map { WeightFormatter.poundsAndOunces($0.total) },
            mvpIcon: rankedCrops.first.map { CropIconResolver.resolve(name: $0.name, in: crops) },
            topCrops: runnersUp,
            peakLabel: ReportStats.peakLabel(of: seasonEntries) ?? "—"
        )
    }

    // MARK: Story of the season

    /// The on-device model's narrative recap, shown only once generated.
    private func storyCard(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.body(14.5))
            .foregroundStyle(Theme.ink)
            .lineSpacing(3.5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
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
