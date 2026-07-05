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
        let totals = totalsByCrop
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 11), count: 3), spacing: 11) {
            ForEach(quickCrops) { crop in
                CropTileView(crop: crop, totalOunces: totals[crop.name] ?? 0) {
                    onSelectCrop(crop.name)
                }
            }
            AddCropTileView(action: onAddCrop)
        }
    }
}
