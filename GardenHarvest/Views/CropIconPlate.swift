import SwiftUI

/// Circular plate that shows a crop's vegetable icon on a soft radial-gradient
/// dish, falling back to the colored initials disc when no icon matches.
struct CropIconPlate: View {
    let cropName: String
    let colorHex: String
    /// Outer plate diameter.
    let plateSize: CGFloat
    /// Icon image size inside the plate.
    let iconSize: CGFloat
    /// Fallback initials disc diameter.
    let discSize: CGFloat
    /// Explicit asset to show instead of looking one up from the crop name,
    /// e.g. the cornucopia for the "All crops" filter row.
    var assetOverride: String? = nil

    private static let plateInner = Color.white
    private static let plateOuter = Color(hex: "#eef3e4")

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Self.plateInner, Self.plateOuter],
                        center: UnitPoint(x: 0.5, y: 0.38),
                        startRadius: 0,
                        endRadius: plateSize * 0.62
                    )
                )
                .shadow(color: Color(hex: "#22381c").opacity(0.07), radius: plateSize * 0.07, y: plateSize * 0.03)
            if let assetName = assetOverride ?? CropIconAssigner.assetName(for: cropName) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: Color(hex: "#22381c").opacity(0.22), radius: 3.5, y: 2)
            } else {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: discSize, height: discSize)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: -1.5)
                    .overlay(
                        Text(cropName.cropInitials)
                            .font(Theme.Font.mono(discSize > 44 ? 15 : 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: plateSize, height: plateSize)
    }
}
