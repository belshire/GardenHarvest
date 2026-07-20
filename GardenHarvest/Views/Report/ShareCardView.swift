import SwiftUI
import UIKit

/// Everything the shareable harvest card needs, snapshotted from the Report
/// so the card can also be rendered offscreen into an image.
struct HarvestShareCardModel {
    struct TopCrop {
        let name: String
        let valueString: String
        let colorHex: String
        let icon: ResolvedCropIcon
    }

    let season: Int
    let totalString: String
    let cropCount: Int
    let mvpName: String?
    let mvpTitle: String?
    let mvpColorHex: String?
    /// The MVP's season total, shown on its merged row.
    let mvpValueString: String?
    let mvpIcon: ResolvedCropIcon?
    /// Ranks 2–5; the MVP row above covers #1.
    let topCrops: [TopCrop]
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
                        discSize: 40,
                        resolvedIcon: model.mvpIcon
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
            switch crop.icon {
            case .custom(let data):
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 23, height: 23)
                        .clipShape(Circle())
                } else {
                    initialsCircle(crop)
                }
            case .asset(let assetName):
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            case .initials:
                initialsCircle(crop)
            }
        }
        .frame(width: 23, height: 23)
    }

    private func initialsCircle(_ crop: HarvestShareCardModel.TopCrop) -> some View {
        Circle()
            .fill(Color(hex: crop.colorHex))
            .overlay(
                Text(crop.name.cropInitials)
                    .font(Theme.Font.mono(9, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

/// Full-screen scrim presenting the harvest card with "Save image" (opens the
/// share sheet with a pre-rendered PNG) and "Close".
///
/// The PNG is rendered and written to a temp file as soon as the overlay
/// appears, so tapping "Save image" only has to present the sheet — the
/// encode never runs at tap time on the main thread. If the tap beats the
/// background encode, the button shows a spinner and the sheet opens the
/// moment the file lands.
struct HarvestShareOverlay: View {
    let model: HarvestShareCardModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    /// Encoded PNG on disk, named for the season so the share sheet shows a
    /// sensible filename.
    @State private var shareURL: URL?
    /// Tap arrived before the PNG finished encoding.
    @State private var waitingForImage = false
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 14) {
            HarvestShareCardView(model: model)
                .shadow(color: .black.opacity(0.42), radius: 32, y: 24)
            HStack(spacing: 10) {
                Button {
                    if shareURL != nil {
                        showShareSheet = true
                    } else {
                        waitingForImage = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        if waitingForImage {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                        Text("Save image")
                            .font(Theme.Font.body(14.5, weight: .heavy))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .disabled(waitingForImage)
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
        .onChange(of: shareURL) { _, url in
            if waitingForImage, url != nil {
                waitingForImage = false
                showShareSheet = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ActivityShareSheet(items: [shareURL])
                    .ignoresSafeArea()
            }
        }
    }

    /// Renders the card offscreen at screen scale (main actor, cheap), then
    /// encodes the PNG and writes the temp file off the main thread.
    private func renderCardImage() {
        let renderer = ImageRenderer(content: HarvestShareCardView(model: model))
        renderer.scale = max(displayScale, 2)
        guard let uiImage = renderer.uiImage else { return }
        let season = model.season
        Task.detached(priority: .userInitiated) {
            guard let data = uiImage.pngData() else { return }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(season)-harvest-report.png")
            do {
                try data.write(to: url)
            } catch {
                return
            }
            await MainActor.run { shareURL = url }
        }
    }
}

/// Bare UIActivityViewController wrapper; presenting it ourselves (instead of
/// ShareLink) lets the button react instantly and show progress.
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
