import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Crop.sortIndex) private var crops: [Crop]
    @Query private var allEntries: [HarvestEntry]

    let onSelectCrop: (String) -> Void

    private var season: Int { Calendar.current.component(.year, from: .now) }

    private var seasonEntries: [HarvestEntry] {
        allEntries.filter { Calendar.current.component(.year, from: $0.date) == season }
    }

    private var totalsByCrop: [String: Double] {
        Dictionary(grouping: seasonEntries, by: \.cropName).mapValues { $0.reduce(0) { $0 + $1.ounces } }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                totalCard
                grid
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 128)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
    }

    private var header: some View {
        PageHeaderTitle(eyebrow: seasonLabel, title: "What did you pick?")
            .frame(maxWidth: .infinity)
    }

    private var seasonLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(season) season · \(formatter.string(from: .now))"
    }

    private var totalCard: some View {
        TotalInfoCard(
            total: seasonEntries.reduce(0) { $0 + $1.ounces },
            caption: "picked this season across \(totalsByCrop.keys.count) crops",
            background: Theme.accent
        )
    }

    private var grid: some View {
        let totals = totalsByCrop
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
            ForEach(crops) { crop in
                CropTileView(crop: crop, totalOunces: totals[crop.name] ?? 0) {
                    onSelectCrop(crop.name)
                }
            }
        }
    }
}
