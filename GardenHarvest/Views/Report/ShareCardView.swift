import SwiftUI

/// Everything the shareable harvest card needs, snapshotted from the Report
/// so the card can also be rendered offscreen into an image.
struct HarvestShareCardModel {
    struct TopCrop {
        let name: String
        let valueString: String
        let colorHex: String
    }

    let season: Int
    let totalString: String
    let cropCount: Int
    let mvpName: String?
    let mvpTitle: String?
    let mvpColorHex: String?
    /// The MVP's season total, shown on its merged row.
    let mvpValueString: String?
    /// Ranks 2–5; the MVP row above covers #1.
    let topCrops: [TopCrop]
    /// The season's top-priority fun fact in template wording, nil for
    /// seasons too sparse to trigger any extractor.
    let funFact: String?
    let peakLabel: String
}

/// The harvest card itself — shown in the share overlay and rendered by
/// `ImageRenderer` for "Save image", so it must not depend on any environment
/// the renderer lacks.
struct HarvestShareCardView: View {
    let model: HarvestShareCardModel

    static let cardWidth: CGFloat = 318

    private static let background = Color(hex: "#fffdf6")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(String(model.season)) Harvest Report")
                .font(Theme.Font.mono(10, weight: .bold))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            Text(model.totalString)
                .font(Theme.Font.heading(46, weight: .heavy))
                .foregroundStyle(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            Text("homegrown across \(model.cropCount) crops")
                .font(Theme.Font.body(12.5, weight: .semibold))
                .foregroundStyle(Theme.sub)
                .frame(maxWidth: .infinity)
                .padding(.top, 5)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .padding(.top, 18)
                .padding(.bottom, 15)

            if let mvpName = model.mvpName {
                sectionLabel("Top crops")
                HStack(spacing: 13) {
                    CropIconPlate(
                        cropName: mvpName,
                        colorHex: model.mvpColorHex ?? "#999999",
                        plateSize: 50,
                        iconSize: 36,
                        discSize: 40
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(mvpName)
                            .font(Theme.Font.heading(21, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        if let mvpTitle = model.mvpTitle {
                            Text(mvpTitle)
                                .font(Theme.Font.body(11.5, weight: .semibold))
                                .foregroundStyle(Theme.sub)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let mvpValueString = model.mvpValueString {
                        Text(mvpValueString)
                            .font(Theme.Font.mono(12.5, weight: .heavy))
                            .foregroundStyle(Theme.accent2)
                    }
                }
                .padding(.top, 9)
                .padding(.bottom, model.topCrops.isEmpty ? 0 : 7)
            }

            if !model.topCrops.isEmpty {
                ForEach(Array(model.topCrops.enumerated()), id: \.offset) { index, crop in
                    HStack(spacing: 10) {
                        Text("#\(index + 2)")
                            .font(Theme.Font.mono(11.5, weight: .bold))
                            .foregroundStyle(Theme.sub)
                            .frame(width: 18, alignment: .leading)
                        cropIcon(crop)
                        Text(crop.name)
                            .font(Theme.Font.body(13.5, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(crop.valueString)
                            .font(Theme.Font.mono(12, weight: .bold))
                            .foregroundStyle(Theme.sub)
                    }
                    .padding(.vertical, 6)
                }
            }

            if let funFact = model.funFact {
                sectionLabel("Fun fact")
                    .padding(.top, 11)
                Text(funFact)
                    .font(Theme.Font.body(12, weight: .semibold))
                    .italic()
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 5)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Peak harvest")
                    .font(Theme.Font.mono(9.5, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .foregroundStyle(Theme.sub)
                Spacer()
                Text(model.peakLabel)
                    .font(Theme.Font.heading(17, weight: .bold))
                    .foregroundStyle(Theme.accent2)
            }
            .padding(.top, 15)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
            .padding(.top, 16)

            Text("◆ GardenLog")
                .font(Theme.Font.mono(9.5))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(Theme.sub.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.top, 19)
        }
        .padding(.top, 26)
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
        .frame(width: Self.cardWidth)
        .background(Self.background)
        .overlay(alignment: .top) {
            LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .leading, endPoint: .trailing)
                .frame(height: 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.mono(9.5, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(Theme.sub)
    }

    private func cropIcon(_ crop: HarvestShareCardModel.TopCrop) -> some View {
        Group {
            if let assetName = CropIconAssigner.assetName(for: crop.name) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Circle()
                    .fill(Color(hex: crop.colorHex))
                    .overlay(
                        Text(crop.name.cropInitials)
                            .font(Theme.Font.mono(9, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: 23, height: 23)
    }
}

/// Full-screen scrim presenting the harvest card with "Save image" (renders
/// the card to a PNG and opens the share sheet) and "Close".
struct HarvestShareOverlay: View {
    let model: HarvestShareCardModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var cardImage: Image?

    var body: some View {
        VStack(spacing: 14) {
            HarvestShareCardView(model: model)
                .shadow(color: .black.opacity(0.42), radius: 32, y: 24)
            HStack(spacing: 10) {
                if let cardImage {
                    ShareLink(
                        item: cardImage,
                        preview: SharePreview("\(String(model.season)) Harvest Report", image: cardImage)
                    ) {
                        actionLabel("Save image")
                    }
                    .buttonStyle(.plain)
                } else {
                    actionLabel("Save image").opacity(0.6)
                }
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(Theme.Font.body(14.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
            }
            .frame(width: HarvestShareCardView.cardWidth)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .onAppear(perform: renderCardImage)
    }

    private func actionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.body(14.5, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    /// Renders the card offscreen at screen scale so the shared PNG matches
    /// what's presented.
    private func renderCardImage() {
        let renderer = ImageRenderer(content: HarvestShareCardView(model: model))
        renderer.scale = max(displayScale, 2)
        if let uiImage = renderer.uiImage {
            cardImage = Image(uiImage: uiImage)
        }
    }
}
