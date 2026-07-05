import SwiftUI

struct CropTileView: View {
    let crop: Crop
    let totalOunces: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: crop.colorHex))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(crop.name.cropInitials)
                            .font(Theme.Font.mono(15, weight: .bold))
                            .foregroundStyle(.white)
                    )
                Text(crop.name)
                    .font(Theme.Font.body(12.5, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(totalOunces > 0 ? WeightFormatter.poundsAndOunces(totalOunces) : "—")
                    .font(Theme.Font.mono(11))
                    .foregroundStyle(Theme.sub)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .frame(minHeight: 104)
            .frame(maxWidth: .infinity)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: Theme.tileRadius).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.tileRadius))
        }
        .buttonStyle(.plain)
    }
}
