import SwiftUI
import SwiftData

/// What the editor did, handed back so the presenter can dismiss, re-point a
/// selection that was keyed by the old name, and raise the toast.
enum CropEditResult {
    case cancelled
    /// The crop's name after the edit — the merge target's name when merged.
    case updated(cropName: String, toast: String)
    case deleted(toast: String)
}

/// Copy shared by the editor and the Pick context menu, which both land on the
/// same delete confirmation.
enum CropEditCopy {
    static func pickings(_ count: Int) -> String {
        "\(count) picking\(count == 1 ? "" : "s")"
    }

    static func seasons(_ count: Int) -> String {
        "\(count) season\(count == 1 ? "" : "s")"
    }

    static func deleteTitle(_ cropName: String) -> String {
        "Delete \(cropName)?"
    }

    static func deleteBody(_ radius: CropEditService.BlastRadius) -> String {
        guard radius.entryCount > 0 else {
            return "It has no logged pickings yet. This can’t be undone."
        }
        return "\(pickings(radius.entryCount)) across \(seasons(radius.seasonCount)) — "
            + "\(WeightFormatter.poundsAndOunces(radius.totalOunces)) — are deleted with it. "
            + "Season totals and past reports will change. This can’t be undone."
    }

    static func deleteToast(cropName: String, entryCount: Int) -> String {
        "Deleted \(cropName) and its \(entryCount) entries"
    }

    static let deleteConfirm = "Delete crop & entries"
    static let deleteCancel = "Keep it"
}

/// Renames a crop, changes its icon, merges it into a crop of the same name, or
/// deletes it — reachable from the Pick context menu and the Log harvest header.
///
/// Nothing is written until Save: the icon preview and the typed name are draft
/// state, so backing out leaves the crop untouched.
struct CropEditSheet: View {
    let crop: Crop
    let onComplete: (CropEditResult) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var crops: [Crop]
    @Query private var allEntries: [HarvestEntry]

    @State private var draftName: String
    @State private var draftIcon: IconChoice
    @State private var isIconPickerOpen = false
    @State private var pendingMerge: Crop?
    @State private var pendingDelete = false
    @FocusState private var nameFocused: Bool

    init(crop: Crop, onComplete: @escaping (CropEditResult) -> Void) {
        self.crop = crop
        self.onComplete = onComplete
        _draftName = State(initialValue: crop.name)
        _draftIcon = State(initialValue: crop.iconChoice)
    }

    private var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The crop `trimmedName` would collide with — the merge target.
    private var collision: Crop? {
        CropEditService.collision(for: draftName, editing: crop, in: crops)
    }

    private var radius: CropEditService.BlastRadius {
        CropEditService.blastRadius(of: crop.name, in: allEntries)
    }

    var body: some View {
        VStack(spacing: 14) {
            headerRow
            ScrollView {
                VStack(spacing: 14) {
                    iconSection
                    nameSection
                    if let collision {
                        conflictNote(collision)
                    }
                    blastRadiusNote
                    Divider()
                        .overlay(Theme.hairline)
                        .padding(.top, 2)
                    deleteButton
                }
                .padding(.bottom, 22)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Theme.card.ignoresSafeArea())
        .animation(.easeOut(duration: 0.18), value: collision?.id)
        .sheet(isPresented: $isIconPickerOpen) {
            IconPickerSheet(
                cropName: trimmedName.isEmpty ? crop.name : trimmedName,
                colorHex: crop.colorHex,
                current: draftIcon,
                onSelect: { draftIcon = $0 }
            )
        }
        // `presenting:` hands the target to the action closure, so the merge
        // doesn't depend on the binding still holding it once the alert
        // starts dismissing.
        .alert(
            pendingMerge.map { "Merge into \($0.name)?" } ?? "",
            isPresented: Binding(get: { pendingMerge != nil }, set: { if !$0 { pendingMerge = nil } }),
            presenting: pendingMerge
        ) { target in
            Button("Merge the two crops") { commitMerge(into: target) }
            Button("Pick a different name", role: .cancel) { nameFocused = true }
        } message: { target in
            Text(
                "You already grow \(target.name). Merging moves \(radius.entryCount) \(crop.name) "
                + "entries into it and keeps \(target.name)’s icon. The two crops become one everywhere."
            )
        }
        .alert(CropEditCopy.deleteTitle(crop.name), isPresented: $pendingDelete) {
            Button(CropEditCopy.deleteConfirm, role: .destructive) { commitDelete() }
            Button(CropEditCopy.deleteCancel, role: .cancel) {}
        } message: {
            Text(CropEditCopy.deleteBody(radius))
        }
    }

    // MARK: Sections

    private var headerRow: some View {
        HStack(spacing: 10) {
            Button("Cancel") { onComplete(.cancelled) }
                .font(Theme.Font.body(14.5, weight: .bold))
                .foregroundStyle(Theme.sub)
            Spacer()
            Text("Edit crop")
                .font(Theme.Font.mono(10.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(Theme.sub)
            Spacer()
            Button {
                nameFocused = false
                save()
            } label: {
                Text("Save")
                    .font(Theme.Font.body(14, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 9)
                    .background(trimmedName.isEmpty ? Theme.hairline : Theme.accent)
                    .clipShape(Capsule())
                    .shadow(
                        color: trimmedName.isEmpty ? .clear : Theme.accent.opacity(0.45),
                        radius: 8, y: 5
                    )
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
        }
    }

    private var previewIcon: ResolvedCropIcon? {
        switch draftIcon {
        case .auto: return nil
        case .asset(let name): return .asset(name)
        case .custom(let data): return .custom(data)
        }
    }

    private var iconSection: some View {
        VStack(spacing: 7) {
            Button {
                nameFocused = false
                isIconPickerOpen = true
            } label: {
                CropIconPlate(
                    cropName: trimmedName.isEmpty ? crop.name : trimmedName,
                    colorHex: crop.colorHex,
                    plateSize: 116,
                    iconSize: 88,
                    discSize: 98,
                    resolvedIcon: previewIcon
                )
            }
            .buttonStyle(.plain)
            Button("Change icon ›") {
                nameFocused = false
                isIconPickerOpen = true
            }
            .font(Theme.Font.mono(11, weight: .bold))
            .tracking(0.4)
            .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .animation(.easeOut(duration: 0.18), value: draftIcon)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Crop name")
                .font(Theme.Font.mono(10, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Theme.sub)
            TextField("Crop name", text: $draftName)
                .font(Theme.Font.heading(19, weight: .bold))
                .foregroundStyle(Theme.ink)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { save() }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func conflictNote(_ target: Crop) -> some View {
        Text(
            "You already grow \(target.name). Saving merges these two crops — "
            + "\(radius.entryCount) entries move into \(target.name) and it keeps its icon."
        )
        .font(Theme.Font.body(13, weight: .semibold))
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Theme.accent.opacity(0.09))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.accent.opacity(0.28), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .transition(.opacity)
    }

    private var blastRadiusText: String {
        guard radius.entryCount > 0 else { return "No log entries yet — nothing else to update." }
        return "Applies to \(radius.entryCount) log entries across "
            + "\(CropEditCopy.seasons(radius.seasonCount)), plus filters and reports."
    }

    private var blastRadiusNote: some View {
        Text(blastRadiusText)
            .font(Theme.Font.mono(11, weight: .bold))
            .lineSpacing(2)
            .foregroundStyle(Theme.sub)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(Color(hex: "#f4f8ed"))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var deleteButton: some View {
        Button {
            nameFocused = false
            pendingDelete = true
        } label: {
            Text(radius.entryCount > 0 ? "Delete crop & its \(radius.entryCount) entries" : "Delete crop")
                .font(Theme.Font.body(13.5, weight: .bold))
                .foregroundStyle(Theme.destructive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: Commit

    private func save() {
        guard !trimmedName.isEmpty else { return }
        if let collision {
            pendingMerge = collision
            return
        }

        let oldName = crop.name
        let canonical = CropEditService.canonicalName(draftName)
        let renamed = canonical != oldName
        let reIcon = draftIcon != crop.iconChoice
        guard renamed || reIcon else {
            onComplete(.cancelled)
            return
        }

        // Count before the rename rewrites the entries out from under it.
        let entryCount = radius.entryCount
        do {
            if reIcon { crop.iconChoice = draftIcon }
            if renamed {
                try CropEditService.rename(crop, to: canonical, in: modelContext)
            } else {
                try modelContext.save()
            }
        } catch {
            assertionFailure("Failed to save crop edit: \(error)")
            onComplete(.cancelled)
            return
        }

        let toast = renamed
            ? "\(oldName) → \(canonical) · \(entryCount) log entries updated"
            : "New icon for \(canonical) · \(entryCount) entries updated"
        onComplete(.updated(cropName: canonical, toast: toast))
    }

    private func commitMerge(into target: Crop) {
        let sourceName = crop.name
        let targetName = target.name
        do {
            let moved = try CropEditService.merge(crop, into: target, in: modelContext)
            onComplete(.updated(
                cropName: targetName,
                toast: "Merged \(sourceName) into \(targetName) · \(moved) entries moved"
            ))
        } catch {
            assertionFailure("Failed to merge crops: \(error)")
            onComplete(.cancelled)
        }
    }

    private func commitDelete() {
        let name = crop.name
        do {
            let removed = try CropEditService.delete(crop, in: modelContext)
            onComplete(.deleted(toast: CropEditCopy.deleteToast(cropName: name, entryCount: removed)))
        } catch {
            assertionFailure("Failed to delete crop: \(error)")
            onComplete(.cancelled)
        }
    }
}
