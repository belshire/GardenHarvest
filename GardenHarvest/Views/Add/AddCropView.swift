import SwiftUI
import SwiftData

struct AddCropView: View {
    let onCommitted: (String) -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var crops: [Crop]
    @State private var name: String = ""
    @State private var iconChoice: IconChoice = .auto
    @State private var showIconPicker = false
    @FocusState private var isFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var suggestions: [String] {
        guard !trimmedName.isEmpty else { return [] }
        let query = trimmedName.lowercased()
        return Array(MasterCropList.names.filter { $0.lowercased().contains(query) }.prefix(6))
    }

    private func isKnown(_ cropName: String) -> Bool {
        crops.contains { $0.name.lowercased() == cropName.lowercased() }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                topBar
                header
                iconPreview
                nameField
                if !suggestions.isEmpty {
                    suggestionList
                }
                commitButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            // The tab bar floats over this content (RootView overlays
            // it), so leave room for the button to scroll clear of it —
            // same clearance the Log and Report screens use.
            .padding(.bottom, 128)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { isFocused = true }
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(
                cropName: trimmedName,
                colorHex: CropColorAssigner.colorHex(for: trimmedName),
                current: iconChoice,
                onSelect: { iconChoice = $0 }
            )
        }
    }

    private var topBar: some View {
        HStack {
            Button("‹ Back", action: onBack)
                .font(Theme.Font.body(15, weight: .bold))
                .foregroundStyle(Theme.accent)
            Spacer()
        }
    }

    /// Eyebrow-over-serif page header, matching the Home and Log headers
    /// (see `PageHeaderTitle`).
    private var header: some View {
        PageHeaderTitle(eyebrow: "New vegetable", title: "What did you grow?")
            .frame(maxWidth: .infinity)
    }

    private var nameField: some View {
        TextField("Type a vegetable…", text: $name)
            .font(Theme.Font.heading(17, weight: .bold))
            .foregroundStyle(Theme.ink)
            .focused($isFocused)
            .padding(14)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
    }

    private var matchedIconName: String? {
        trimmedName.isEmpty ? nil : CropIconAssigner.assetName(for: trimmedName)
    }

    private var resolvedPreviewIcon: ResolvedCropIcon? {
        switch iconChoice {
        case .auto: return nil
        case .asset(let name): return .asset(name)
        case .custom(let data): return .custom(data)
        }
    }

    private var iconPreview: some View {
        Button {
            showIconPicker = true
        } label: {
            VStack(spacing: 8) {
                if trimmedName.isEmpty && iconChoice == .auto {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .foregroundStyle(Theme.hairline)
                        .frame(width: 128, height: 128)
                        .overlay(
                            Text("🌱")
                                .font(.system(size: 46))
                                .opacity(0.5)
                        )
                } else {
                    CropIconPlate(
                        cropName: trimmedName,
                        colorHex: CropColorAssigner.colorHex(for: trimmedName),
                        plateSize: 128,
                        iconSize: 98,
                        discSize: 108,
                        resolvedIcon: resolvedPreviewIcon
                    )
                }
                Text(previewCaption)
                    .font(Theme.Font.mono(11.5, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(captionIsAccented ? Theme.accent2 : Theme.sub)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .animation(.easeOut(duration: 0.18), value: iconChoice)
        .animation(.easeOut(duration: 0.18), value: matchedIconName)
    }

    private var captionIsAccented: Bool {
        iconChoice != .auto || matchedIconName != nil
    }

    private var previewCaption: String {
        switch iconChoice {
        case .custom: return "Custom photo · tap to change"
        case .asset: return "Icon picked · tap to change"
        case .auto:
            if matchedIconName != nil { return "Auto-matched · tap to change" }
            if trimmedName.isEmpty { return "Start typing, or tap to pick an icon" }
            return "No icon match · tap to pick one"
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    name = suggestion
                } label: {
                    HStack(spacing: 12) {
                        CropIconPlate(
                            cropName: suggestion,
                            colorHex: CropColorAssigner.colorHex(for: suggestion),
                            plateSize: 40,
                            iconSize: 32,
                            discSize: 34
                        )
                        Text(suggestion)
                            .font(Theme.Font.body(15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if isKnown(suggestion) {
                            Text("grown before")
                                .font(Theme.Font.mono(10.5, weight: .bold))
                                .foregroundStyle(Theme.accent2)
                        }
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                if suggestion != suggestions.last {
                    Divider()
                }
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
    }

    private var commitButton: some View {
        Button {
            commit()
        } label: {
            Text(trimmedName.isEmpty ? "Name your vegetable" : "Add \(trimmedName) & log it")
                .font(Theme.Font.body(16, weight: .heavy))
                .foregroundStyle(trimmedName.isEmpty ? Theme.sub : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(trimmedName.isEmpty ? Theme.hairline : Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: trimmedName.isEmpty ? .clear : Theme.accent.opacity(0.35),
            radius: 10, y: 6
        )
        .disabled(trimmedName.isEmpty)
    }

    private func commit() {
        guard !trimmedName.isEmpty else { return }
        let canonicalName = MasterCropList.names.first { $0.lowercased() == trimmedName.lowercased() } ?? trimmedName
        if let existing = crops.first(where: { $0.name == canonicalName }) {
            // Re-adding a known crop: only a deliberate pick overwrites its icon.
            if iconChoice != .auto {
                existing.iconChoice = iconChoice
                try? modelContext.save()
            }
        } else {
            let crop = Crop(
                name: canonicalName,
                colorHex: CropColorAssigner.colorHex(for: canonicalName),
                sortIndex: (crops.map(\.sortIndex).max() ?? -1) + 1,
                variants: []
            )
            crop.iconChoice = iconChoice
            modelContext.insert(crop)
            try? modelContext.save()
        }
        onCommitted(canonicalName)
    }
}
