import SwiftUI

/// Circular plate that shows a crop's vegetable icon on a soft radial-gradient
/// dish, a circle-cropped custom photo, or the colored initials disc.
struct CropIconPlate: View {
    let cropName: String
    let colorHex: String
    /// Outer plate diameter.
    let plateSize: CGFloat
    /// Icon image size inside the plate.
    let iconSize: CGFloat
    /// Fallback initials disc diameter.
    let discSize: CGFloat
    /// Explicit asset to show regardless of the crop, e.g. the cornucopia for
    /// the "All crops" filter row. Wins over `resolvedIcon`.
    var assetOverride: String? = nil
    /// Pre-resolved icon from a crop's stored override fields (see
    /// `CropIconResolver`). nil keeps the name-based auto-match, so call
    /// sites without a `Crop` behave exactly as before.
    var resolvedIcon: ResolvedCropIcon? = nil

    private static let plateInner = Color.white
    private static let plateOuter = Color(hex: "#eef3e4")

    var body: some View {
        ZStack {
            switch effectiveIcon {
            case .custom(let data):
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: plateSize, height: plateSize)
                        .clipShape(Circle())
                        .shadow(color: Color(hex: "#22381c").opacity(0.18), radius: plateSize * 0.05, y: plateSize * 0.02)
                } else {
                    dish
                    initialsDisc
                }
            case .asset(let assetName):
                dish
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: Color(hex: "#22381c").opacity(0.22), radius: 3.5, y: 2)
            case .initials:
                dish
                initialsDisc
            }
        }
        .frame(width: plateSize, height: plateSize)
    }

    private var effectiveIcon: ResolvedCropIcon {
        if let assetOverride { return .asset(assetOverride) }
        if let resolvedIcon { return resolvedIcon }
        if let auto = CropIconAssigner.assetName(for: cropName) { return .asset(auto) }
        return .initials
    }

    private var dish: some View {
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
    }

    private var initialsDisc: some View {
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
