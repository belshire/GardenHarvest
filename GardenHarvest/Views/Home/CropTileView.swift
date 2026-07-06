import SwiftUI

struct CropTileView: View {
    let crop: Crop
    let totalOunces: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 9) {
                CropIconPlate(
                    cropName: crop.name,
                    colorHex: crop.colorHex,
                    plateSize: 104,
                    iconSize: 82,
                    discSize: 92
                )
                Text(crop.name)
                    .font(Theme.Font.heading(15, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(totalOunces > 0 ? WeightFormatter.poundsAndOunces(totalOunces) : "—")
                    .font(Theme.Font.mono(12))
                    .foregroundStyle(Theme.sub)
            }
            .padding(.top, 20)
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
            .frame(minHeight: 172)
            .frame(maxWidth: .infinity)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: Theme.tileRadius).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.tileRadius))
            .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
    }
}
