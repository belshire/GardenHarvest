import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Crop.sortIndex) private var crops: [Crop]
    @Query private var allEntries: [HarvestEntry]

    @State private var isEditing = false
    @State private var draggingCrop: Crop?

    let onSelectCrop: (String) -> Void

    private var season: Int { Calendar.current.component(.year, from: .now) }

    private var seasonEntries: [HarvestEntry] {
        allEntries.filter { Calendar.current.component(.year, from: $0.date) == season }
    }

    private var totalsByCrop: [String: Double] {
        Dictionary(grouping: seasonEntries, by: \.cropName).mapValues { $0.reduce(0) { $0 + $1.ounces } }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                totalCard
                grid
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            // Enough clearance for the Add Crop FAB (116pt offset + ~56pt
            // capsule) so it never covers the last tile row.
            .padding(.bottom, 200)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
    }

    private var header: some View {
        PageHeaderTitle(eyebrow: seasonLabel, title: "What did you pick?")
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                if isEditing {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isEditing = false
                            draggingCrop = nil
                        }
                    } label: {
                        Text("Done")
                            .font(Theme.Font.body(14, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Theme.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
    }

    private var seasonLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(season) season · \(formatter.string(from: .now))"
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
        let base = CropTileView(crop: crop, totalOunces: totalOunces) {
            if !isEditing {
                onSelectCrop(crop.name)
            }
        }
        .rotationEffect(.degrees(isEditing ? (index.isMultiple(of: 2) ? 1.2 : -1.2) : 0))
        .animation(
            isEditing
                ? .easeInOut(duration: 0.14).repeatForever(autoreverses: true)
                : .easeOut(duration: 0.15),
            value: isEditing
        )

        if isEditing {
            base
                .opacity(draggingCrop?.id == crop.id ? 0.4 : 1)
                .onDrag {
                    draggingCrop = crop
                    return NSItemProvider(object: crop.name as NSString)
                }
                .onDrop(of: [.text], delegate: CropReorderDropDelegate(
                    item: crop,
                    crops: crops,
                    draggingCrop: $draggingCrop,
                    saveOrder: persistOrder
                ))
        } else {
            base
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            isEditing = true
                        }
                    }
                )
        }
    }

    private func persistOrder() {
        try? modelContext.save()
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
