import SwiftUI
import PhotosUI

/// Sheet for choosing a crop's icon: auto-match, any VegIcons asset, or a
/// photo-library image (center-cropped by `IconImageProcessor`). Persistence
/// is the caller's job via `onSelect`.
struct IconPickerSheet: View {
    let cropName: String
    let colorHex: String
    let current: IconChoice
    let onSelect: (IconChoice) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var photoItem: PhotosPickerItem?

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    private var filteredSlugs: [String] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return IconCatalog.allSlugs }
        return IconCatalog.allSlugs.filter {
            IconCatalog.displayName(for: $0).lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Choose an icon")
                .font(Theme.Font.heading(19, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .padding(.top, 22)
            searchField
            ScrollView {
                LazyVGrid(columns: Self.columns, spacing: 14) {
                    if search.isEmpty {
                        autoTile
                        uploadTile
                    }
                    ForEach(filteredSlugs, id: \.self) { slug in
                        iconTile(slug)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let processed = IconImageProcessor.squareIconData(from: raw) {
                    onSelect(.custom(processed))
                    dismiss()
                }
                // Load/decode failure: keep the previous selection, stay open.
                photoItem = nil
            }
        }
    }

    private var searchField: some View {
        TextField("Search icons…", text: $search)
            .font(Theme.Font.body(15, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(12)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            .padding(.horizontal, 20)
    }

    /// Shows what auto-match yields for this crop; selecting clears overrides.
    private var autoTile: some View {
        tileButton(isSelected: current == .auto, label: "Auto") {
            onSelect(.auto)
            dismiss()
        } content: {
            CropIconPlate(cropName: cropName, colorHex: colorHex,
                          plateSize: 56, iconSize: 44, discSize: 48)
        }
    }

    private var uploadTile: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 6) {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "photo.badge.plus").foregroundStyle(Theme.accent))
                Text("Photo")
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func iconTile(_ slug: String) -> some View {
        let assetName = IconCatalog.assetName(for: slug)
        return tileButton(
            isSelected: current == .asset(assetName),
            label: IconCatalog.displayName(for: slug)
        ) {
            onSelect(.asset(assetName))
            dismiss()
        } content: {
            CropIconPlate(cropName: cropName, colorHex: colorHex,
                          plateSize: 56, iconSize: 44, discSize: 48,
                          assetOverride: assetName)
        }
    }

    private func tileButton(
        isSelected: Bool,
        label: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> some View
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                content()
                    .overlay(
                        Circle().stroke(isSelected ? Theme.accent : .clear, lineWidth: 3)
                    )
                Text(label)
                    .font(Theme.Font.mono(10, weight: .bold))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.sub)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
