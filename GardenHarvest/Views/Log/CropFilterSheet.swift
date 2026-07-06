import SwiftUI

/// Bottom sheet listing "All crops" plus every crop from any year, sorted by
/// all-time total. Selecting a row sets the Log's crop filter.
struct CropFilterSheet: View {
    /// Crops with all-time totals, sorted descending.
    let items: [(name: String, total: Double)]
    let selected: String?
    let colorHex: (String) -> String
    let onSelect: (String?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Filter by crop")
                .font(Theme.Font.mono(12, weight: .heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
                .padding(14)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
            ScrollView {
                LazyVStack(spacing: 0) {
                    row(name: nil, total: nil)
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
                if let name {
                    CropIconPlate(
                        cropName: name,
                        colorHex: colorHex(name),
                        plateSize: 34,
                        iconSize: 27,
                        discSize: 30
                    )
                } else {
                    allCropsDot
                }
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

    private var allCropsDot: some View {
        Circle()
            .fill(LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 30, height: 30)
            .overlay(
                Text("∗")
                    .font(Theme.Font.mono(15, weight: .bold))
                    .foregroundStyle(.white)
            )
            .padding(.horizontal, 2)
    }
}
