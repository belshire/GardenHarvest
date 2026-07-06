import SwiftUI
import SwiftData

struct AddCropView: View {
    let onCommitted: (String) -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var crops: [Crop]
    @State private var name: String = ""
    @State private var addToQuickLog = true
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
                Text("What did you grow?")
                    .font(Theme.Font.body(13, weight: .semibold))
                    .foregroundStyle(Theme.sub)
                    .frame(maxWidth: .infinity, alignment: .leading)
                iconPreview
                TextField("Type a vegetable…", text: $name)
                    .font(Theme.Font.heading(17, weight: .bold))
                    .focused($isFocused)
                    .padding(14)
                    .background(Theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent, lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                if !suggestions.isEmpty {
                    suggestionList
                }
                quickLogToggleRow
                commitButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { isFocused = true }
    }

    private var topBar: some View {
        HStack {
            Button("‹ Back", action: onBack)
                .font(Theme.Font.body(15, weight: .bold))
                .foregroundStyle(Theme.accent)
            Spacer()
            Text("NEW VEGETABLE")
                .font(Theme.Font.mono(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
            Spacer()
            Color.clear.frame(width: 44)
        }
    }

    private var matchedIconName: String? {
        trimmedName.isEmpty ? nil : CropIconAssigner.assetName(for: trimmedName)
    }

    private var iconPreview: some View {
        VStack(spacing: 8) {
            if trimmedName.isEmpty {
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
                    discSize: 108
                )
            }
            Text(previewCaption)
                .font(Theme.Font.mono(11.5, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(matchedIconName != nil ? Theme.accent2 : Theme.sub)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .animation(.easeOut(duration: 0.18), value: matchedIconName)
    }

    private var previewCaption: String {
        if matchedIconName != nil { return "Auto-matched icon" }
        if trimmedName.isEmpty { return "Start typing to auto-pick an icon" }
        return "No icon match — we'll use initials"
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
    }

    private var quickLogToggleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Add to quick log")
                    .font(Theme.Font.body(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Show it on your home screen")
                    .font(Theme.Font.body(11.5))
                    .foregroundStyle(Theme.sub)
            }
            Spacer()
            Toggle("", isOn: $addToQuickLog)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(12)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .disabled(trimmedName.isEmpty)
    }

    private func commit() {
        guard !trimmedName.isEmpty else { return }
        let canonicalName = MasterCropList.names.first { $0.lowercased() == trimmedName.lowercased() } ?? trimmedName
        if !crops.contains(where: { $0.name == canonicalName }) {
            let crop = Crop(
                name: canonicalName,
                colorHex: CropColorAssigner.colorHex(for: canonicalName),
                isQuickLog: addToQuickLog,
                sortIndex: (crops.map(\.sortIndex).max() ?? -1) + 1,
                variants: []
            )
            modelContext.insert(crop)
            try? modelContext.save()
        }
        onCommitted(canonicalName)
    }
}
