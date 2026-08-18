import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Crop.sortIndex) private var crops: [Crop]
    @Query private var allEntries: [HarvestEntry]

    /// Drag-to-reorder mode. Entered only from a tile's context menu, so a
    /// long press no longer drops straight into dragging.
    @State private var isRearranging = false
    @State private var draggingCrop: Crop?
    @State private var editingCrop: Crop?
    @State private var cropPendingDelete: Crop?

    let onSelectCrop: (String) -> Void
    let onToast: (String) -> Void

    private var season: Int { DateProvider.currentYear }

    private var seasonEntries: [HarvestEntry] {
        LogGrouping.entries(in: season, from: allEntries)
    }

    private var totalsByCrop: [String: Double] {
        Dictionary(grouping: seasonEntries, by: \.cropName).mapValues { $0.reduce(0) { $0 + $1.ounces } }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                if isRearranging {
                    rearrangeBar
                } else {
                    totalCard
                }
                grid
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // Enough clearance for the Add Crop FAB (116pt offset + ~56pt
            // capsule) so it never covers the last tile row.
            .padding(.bottom, 200)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .onDrop(of: [.text], delegate: CropReorderCatchAllDelegate(
            draggingCrop: $draggingCrop,
            saveOrder: persistOrder
        ))
        .sheet(item: $editingCrop) { crop in
            CropEditSheet(crop: crop) { result in
                editingCrop = nil
                switch result {
                case .cancelled:
                    break
                case .updated(_, let toast), .deleted(let toast):
                    onToast(toast)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // `presenting:` hands the crop to the action closure, so the delete
        // doesn't depend on the binding still holding it once the alert
        // starts dismissing.
        .alert(
            cropPendingDelete.map { CropEditCopy.deleteTitle($0.name) } ?? "",
            isPresented: Binding(
                get: { cropPendingDelete != nil },
                set: { if !$0 { cropPendingDelete = nil } }
            ),
            presenting: cropPendingDelete
        ) { crop in
            Button(CropEditCopy.deleteConfirm, role: .destructive) { delete(crop) }
            Button(CropEditCopy.deleteCancel, role: .cancel) {}
        } message: { crop in
            Text(CropEditCopy.deleteBody(CropEditService.blastRadius(of: crop.name, in: allEntries)))
        }
    }

    private var header: some View {
        PageHeaderTitle(
            eyebrow: seasonLabel,
            title: isRearranging ? "Rearrange your crops" : "What did you pick?"
        )
        .frame(maxWidth: .infinity)
    }

    /// Replaces the season total while rearranging: what the mode is, and the
    /// only way out of it.
    private var rearrangeBar: some View {
        HStack(spacing: 10) {
            Text("Drag tiles to rearrange")
                .font(Theme.Font.mono(11.5, weight: .bold))
                .foregroundStyle(Theme.sub)
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isRearranging = false
                    draggingCrop = nil
                }
            } label: {
                Text("Done")
                    .font(Theme.Font.body(13.5, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private var seasonLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(season) season · \(formatter.string(from: DateProvider.now))"
    }

    private var totalCard: some View {
        TotalInfoCard(
            total: seasonEntries.reduce(0) { $0 + $1.ounces },
            caption: "picked this season across \(totalsByCrop.keys.count) crops",
            background: Theme.accent
        )
    }

    private var grid: some View {
        let totals = totalsByCrop
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
            ForEach(Array(crops.enumerated()), id: \.element.id) { index, crop in
                tile(for: crop, at: index, totalOunces: totals[crop.name] ?? 0)
            }
        }
    }

    @ViewBuilder
    private func tile(for crop: Crop, at index: Int, totalOunces: Double) -> some View {
        let isDragging = isRearranging && draggingCrop?.id == crop.id
        // Tapping a tile while rearranging does nothing — the drag is the
        // gesture that matters there, and a stray tap used to open the picker.
        let base = CropTileView(crop: crop, totalOunces: totalOunces) {
            guard !isRearranging else { return }
            onSelectCrop(crop.name)
        }
        .modifier(TileWiggleModifier(
            isActive: isRearranging,
            clockwise: index.isMultiple(of: 2),
            phase: Double(index % 3) * 0.045
        ))
        .opacity(isDragging ? 0.5 : 1)
        .scaleEffect(isDragging ? 0.95 : 1)

        if isRearranging {
            base
                .onDrag {
                    withAnimation(.easeOut(duration: 0.22)) {
                        draggingCrop = crop
                    }
                    // The system releases the provider when the drag session
                    // ends, wherever the tile was dropped — including gaps and
                    // non-tile areas where no drop delegate fires. Clearing
                    // here (instantly, no fade) means the tile is already
                    // opaque when the system's drag preview lands on it.
                    let provider = DragSessionItemProvider(object: crop.name as NSString)
                    provider.onSessionEnd = { draggingCrop = nil }
                    return provider
                }
                .onDrop(of: [.text], delegate: CropReorderDropDelegate(
                    item: crop,
                    crops: crops,
                    draggingCrop: $draggingCrop,
                    saveOrder: persistOrder
                ))
        } else {
            // The system's lift-and-blur preview stands in for the prototype's
            // hand-drawn scrim; it also supplies the open haptic.
            base.contextMenu {
                Button {
                    editingCrop = crop
                } label: {
                    Label("Edit name & icon", systemImage: "pencil")
                }
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isRearranging = true
                    }
                } label: {
                    Label("Rearrange crops", systemImage: "arrow.up.arrow.down")
                }
                Button(role: .destructive) {
                    cropPendingDelete = crop
                } label: {
                    Label("Delete crop", systemImage: "trash")
                }
            } preview: {
                CropTileView(crop: crop, totalOunces: totalOunces) {}
                    .frame(width: 168)
            }
        }
    }

    private func delete(_ crop: Crop) {
        let name = crop.name
        do {
            let removed = try CropEditService.delete(crop, in: modelContext)
            onToast(CropEditCopy.deleteToast(cropName: name, entryCount: removed))
        } catch {
            assertionFailure("Failed to delete crop: \(error)")
        }
    }

    private func persistOrder() {
        try? modelContext.save()
    }
}

/// iOS home-screen style wiggle for edit mode. Lives in its own modifier so
/// the repeat-forever rotation is (re)started from `onAppear`/`onChange` —
/// the edit/non-edit branches in `tile(for:)` give the tile a new identity
/// when edit mode toggles, which would otherwise drop an in-flight animation
/// and leave the tile frozen at a static skew.
private struct TileWiggleModifier: ViewModifier {
    let isActive: Bool
    /// Alternates the swing direction per tile so neighbors are out of sync.
    let clockwise: Bool
    /// Small per-tile delay so the grid doesn't wiggle in lockstep.
    let phase: Double

    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onAppear {
                if isActive { startWiggle() }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    startWiggle()
                } else {
                    withAnimation(.easeOut(duration: 0.18)) { angle = 0 }
                }
            }
    }

    private func startWiggle() {
        let swing = 1.3
        angle = clockwise ? -swing : swing
        withAnimation(.easeInOut(duration: 0.13).repeatForever(autoreverses: true).delay(phase)) {
            angle = clockwise ? swing : -swing
        }
    }
}

/// Reorders crops as a dragged tile passes over its siblings, rewriting
/// `sortIndex` so the `@Query` (sorted by `sortIndex`) animates the move.
private struct CropReorderDropDelegate: DropDelegate {
    let item: Crop
    let crops: [Crop]
    @Binding var draggingCrop: Crop?
    let saveOrder: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingCrop,
              dragging.id != item.id,
              let from = crops.firstIndex(where: { $0.id == dragging.id }),
              let to = crops.firstIndex(where: { $0.id == item.id })
        else { return }

        var reordered = crops
        reordered.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        withAnimation(.easeInOut(duration: 0.2)) {
            for (index, crop) in reordered.enumerated() where crop.sortIndex != index {
                crop.sortIndex = index
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingCrop = nil
        saveOrder()
        return true
    }
}

/// Accepts drops anywhere in the Pick screen outside the tiles, so releasing
/// a tile over a grid gap, the header, or the totals card completes the drop
/// in place instead of playing the system's cancel fly-back animation.
private struct CropReorderCatchAllDelegate: DropDelegate {
    @Binding var draggingCrop: Crop?
    let saveOrder: () -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingCrop = nil
        saveOrder()
        return true
    }
}

/// `CropReorderDropDelegate.performDrop` only runs when the tile is released
/// over another tile; every other release cancels the session silently, which
/// used to leave `draggingCrop` set and the tile stuck semi-transparent. The
/// system releases this provider when the drag session tears down, wherever
/// it ended, so `deinit` is a reliable session-end hook.
private final class DragSessionItemProvider: NSItemProvider {
    var onSessionEnd: (() -> Void)?

    deinit {
        if let onSessionEnd {
            DispatchQueue.main.async(execute: onSessionEnd)
        }
    }
}
