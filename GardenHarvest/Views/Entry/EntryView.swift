import SwiftUI
import SwiftData

struct EntryView: View {
    let cropName: String
    let onSaved: (String) -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var crops: [Crop]

    @State private var ouncesText: String = ""
    @State private var note: String = ""
    @State private var selectedVariant: String?
    @State private var selectedDateChip: DateChip = .today
    @State private var customDate: Date = .now

    private var crop: Crop? {
        crops.first { $0.name == cropName }
    }

    private var ounces: Double {
        Double(ouncesText) ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                topBar
                cropHeader
                ouncesDisplay
                bumpChips
                if let variants = crop?.variants, !variants.isEmpty {
                    variantChips(variants)
                }
                keypad
                dateChips
                noteRow
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button("‹ Back", action: onBack)
                .font(Theme.Font.body(15, weight: .bold))
                .foregroundStyle(Theme.accent)
            Spacer()
            Text("LOG HARVEST")
                .font(Theme.Font.mono(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.sub)
            Spacer()
            Color.clear.frame(width: 44)
        }
    }

    private var cropHeader: some View {
        HStack(spacing: 12) {
            CropIconPlate(
                cropName: cropName,
                colorHex: crop?.colorHex ?? "#999999",
                plateSize: 46,
                iconSize: 36,
                discSize: 40
            )
            Text(cropName)
                .font(Theme.Font.heading(24, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private var ouncesDisplay: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(ouncesText.isEmpty ? "0" : ouncesText)
                .font(Theme.Font.heading(64, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text("oz")
                .font(Theme.Font.mono(18, weight: .bold))
                .foregroundStyle(Theme.sub)
        }
    }

    private var bumpChips: some View {
        HStack(spacing: 8) {
            ForEach([("−1", -1.0), ("+0.5", 0.5), ("+1", 1.0), ("+5", 5.0)], id: \.0) { label, delta in
                Button(label) { bump(by: delta) }
                    .buttonStyle(ChipButtonStyle())
            }
        }
    }

    private func variantChips(_ variants: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(variants, id: \.self) { variant in
                Button(variant) {
                    selectedVariant = (selectedVariant == variant) ? nil : variant
                }
                .buttonStyle(ChipButtonStyle(isSelected: selectedVariant == variant))
            }
        }
    }

    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 9) {
            ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"], id: \.self) { key in
                Button {
                    handleKey(key)
                } label: {
                    Text(key)
                        .font(Theme.Font.heading(22, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .background(key == "⌫" ? Color.clear : Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var dateChips: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(DateChip.allCases, id: \.self) { chip in
                    Button(chip.label) { selectedDateChip = chip }
                        .buttonStyle(ChipButtonStyle(isSelected: selectedDateChip == chip))
                }
            }
            if selectedDateChip == .custom {
                HStack {
                    Text("Harvest date")
                        .font(Theme.Font.body(13.5, weight: .bold))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    DatePicker("", selection: $customDate, in: ...Date.now, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                .padding(.horizontal, 13)
                .frame(height: 44)
                .background(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var noteRow: some View {
        TextField("Note — e.g. some woody", text: $note)
            .font(Theme.Font.body(13.5))
            .padding(.horizontal, 13)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(ounces > 0 ? "Log \(WeightFormatter.ounces(ounces)) oz \(cropName)" : "Enter a weight")
                .font(Theme.Font.body(16, weight: .heavy))
                .foregroundStyle(ounces > 0 ? .white : Theme.sub)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(ounces > 0 ? Theme.accent : Theme.hairline)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(ounces <= 0)
    }

    private func bump(by delta: Double) {
        let newValue = max(0, ((ounces + delta) * 10).rounded() / 10)
        ouncesText = newValue == 0 ? "" : WeightFormatter.ounces(newValue)
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            ouncesText = String(ouncesText.dropLast())
        } else if key == "." {
            if !ouncesText.contains(".") {
                ouncesText += ouncesText.isEmpty ? "0." : "."
            }
        } else {
            let candidate = ouncesText + key
            if candidate.filter(\.isNumber).count <= 5 {
                ouncesText = candidate
            }
        }
    }

    private func save() {
        guard ounces > 0 else { return }
        let roundedOunces = (ounces * 10).rounded() / 10
        let entry = HarvestEntry(
            cropName: cropName,
            ounces: roundedOunces,
            date: selectedDateChip.date(customDate: customDate),
            note: note,
            variant: selectedVariant
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
            onSaved("🌱 Logged \(WeightFormatter.ounces(roundedOunces)) oz \(cropName)")
        } catch {
            modelContext.delete(entry)
            assertionFailure("Failed to save harvest entry: \(error)")
        }
    }
}
