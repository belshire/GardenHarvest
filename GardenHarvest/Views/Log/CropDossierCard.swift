import SwiftUI

/// "Across the years" card shown when a crop filter is active: one tappable
/// row per year with a bar sized against the crop's best year.
struct CropDossierCard: View {
    let colorHex: String
    /// Per-year totals for the selected crop, newest year first.
    let rows: [(year: Int, total: Double)]
    let activeYear: Int
    let onSelectYear: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Across the years")
                .font(Theme.Font.mono(11, weight: .heavy))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
            ForEach(rows, id: \.year) { row in
                yearRow(row)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
    }

    private func yearRow(_ row: (year: Int, total: Double)) -> some View {
        let maxTotal = max(rows.map(\.total).max() ?? 0, 1)
        let isActive = row.year == activeYear
        return Button {
            onSelectYear(row.year)
        } label: {
            HStack(spacing: 10) {
                Text(String(row.year))
                    .font(Theme.Font.mono(14, weight: isActive ? .heavy : .bold))
                    .foregroundStyle(isActive ? Theme.accent : Theme.ink)
                    .frame(width: 44, alignment: .leading)
                CapsuleBar(fraction: max(0.04, row.total / maxTotal), fill: Color(hex: colorHex))
                    .frame(height: 14)
                Text(row.total > 0 ? WeightFormatter.poundsAndOunces(row.total) : "—")
                    .font(Theme.Font.mono(12.5, weight: .heavy))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(minWidth: 76, alignment: .trailing)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 9)
            .background(isActive ? Theme.accent.opacity(0.10) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
