import SwiftUI

/// Bottom sheet listing "All crops" plus every crop in the active year,
/// sorted by that year's total. Selecting a row sets the Log's crop filter.
struct CropFilterSheet: View {
    /// The active year's crops with their year totals, sorted descending.
    let items: [(name: String, total: Double)]
    /// The active year's grand total, shown on the "All crops" row.
    let allCropsTotal: Double
    /// e.g. "Totals for 2026 · sums to 40 lb 2.4 oz"
    let subtitle: String
    let selected: String?
    let colorHex: (String) -> String
    let resolveIcon: (String) -> ResolvedCropIcon
    let onSelect: (String?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                Text("Filter by crop")
                    .font(Theme.Font.mono(12, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Theme.sub)
                Text(subtitle)
                    .font(Theme.Font.mono(11, weight: .semibold))
                    .foregroundStyle(Theme.sub)
                    .opacity(0.75)
            }
            .padding(.top, 12)
            .padding(.horizontal, 14)
            .padding(.bottom, 11)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    row(name: nil, total: allCropsTotal)
                    ForEach(items, id: \.name) { item in
                        row(name: item.name, total: item.total)
                    }
                }
            }
        }
        .background(Theme.card)
    }

    private func row(name: String?, total: Double?) -> some View {
        let isActive = selected == name
        return Button {
            onSelect(name)
        } label: {
            HStack(spacing: 12) {
                CropIconPlate(
                    cropName: name ?? "All crops",
                    colorHex: name.map(colorHex) ?? "#999999",
                    plateSize: 34,
                    iconSize: 27,
                    discSize: 30,
                    assetOverride: name == nil ? CropIconAssigner.allCropsAssetName : nil,
                    resolvedIcon: name.map(resolveIcon)
                )
                Text(name ?? "All crops")
                    .font(Theme.Font.body(15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if let total {
                    Text(WeightFormatter.poundsAndOunces(total))
                        .font(Theme.Font.mono(12.5, weight: .bold))
                        .foregroundStyle(Theme.sub)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(isActive ? Theme.accent.opacity(0.08) : Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
