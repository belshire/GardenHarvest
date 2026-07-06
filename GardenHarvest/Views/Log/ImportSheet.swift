import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Bulk import of harvest entries from the free-form Apple Note format:
/// paste the note (or pick a .txt file), review the live preview — new
/// entries, skipped duplicates, new crops, flagged lines — then commit.
struct ImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [HarvestEntry]
    @Query private var crops: [Crop]

    @State private var text = ""
    @State private var fallbackYear = DateProvider.currentYear
    @State private var showFilePicker = false
    @State private var fileError: String?
    @State private var showImportError = false
    @State private var importedCount: Int?

    private var parsed: HarvestNoteParser.ParsedNote {
        HarvestNoteParser.parse(text)
    }

    private var plan: NoteImportService.ImportPlan {
        NoteImportService.plan(
            parsed: parsed,
            fallbackYear: fallbackYear,
            existingEntries: allEntries,
            existingCrops: crops
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Import harvest note")
                    .font(Theme.Font.heading(24, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Paste the note — headings like “June:” and lines like “Raspberries, small 7.6 oz (6/11)” — or choose a .txt file. Entries already logged are skipped.")
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.sub)

                pasteBox
                filePickerButton

                if parsed.year == nil, !parsed.entries.isEmpty {
                    yearPicker
                }
                if !text.isEmpty {
                    previewCard
                }

                importButton
            }
            .padding(20)
        }
        .background(Theme.panelBackground.ignoresSafeArea())
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText, .text],
            onCompletion: handlePickedFile
        )
        .alert("Import failed — nothing was changed.", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: Input

    private var pasteBox: some View {
        TextEditor(text: $text)
            .font(Theme.Font.mono(12.5))
            .foregroundStyle(Theme.ink)
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(height: 170)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Garden Harvest 2026:\n\nJune:\nStrawberries, 3.5 oz (6/3)\n…")
                        .font(Theme.Font.mono(12.5))
                        .foregroundStyle(Theme.sub.opacity(0.55))
                        .padding(.top, 18)
                        .padding(.leading, 15)
                        .allowsHitTesting(false)
                }
            }

    }

    private var filePickerButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                showFilePicker = true
            } label: {
                Label("Choose a .txt file", systemImage: "doc.badge.plus")
                    .font(Theme.Font.body(13.5, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            if let fileError {
                Text(fileError)
                    .font(Theme.Font.body(12))
                    .foregroundStyle(.red)
            }
        }
    }

    private func handlePickedFile(_ result: Result<URL, Error>) {
        fileError = nil
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let contents = try? String(contentsOf: url, encoding: .utf8) {
            text = contents
        } else {
            fileError = "Couldn't read that file as text."
        }
    }

    /// Shown only when the note has no "Garden Harvest <year>" header.
    private var yearPicker: some View {
        HStack {
            Text("Season")
                .font(Theme.Font.body(13.5, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Picker("Season", selection: $fallbackYear) {
                ForEach(((DateProvider.currentYear - 10)...DateProvider.currentYear).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .tint(Theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            previewRow(
                "plus.circle.fill",
                Theme.accent2,
                "\(plan.new.count) new \(plan.new.count == 1 ? "entry" : "entries")"
            )
            if plan.duplicateCount > 0 {
                previewRow(
                    "arrow.triangle.2.circlepath",
                    Theme.sub,
                    "\(plan.duplicateCount) already logged — skipped"
                )
            }
            if !plan.newCropNames.isEmpty {
                previewRow(
                    "leaf.fill",
                    Theme.accent,
                    "New crops: \(plan.newCropNames.joined(separator: ", "))"
                )
            }
            let assumed = plan.new.filter(\.dayAssumed).count
            if assumed > 0 {
                previewRow(
                    "calendar.badge.exclamationmark",
                    Theme.sub,
                    "\(assumed) undated \(assumed == 1 ? "line" : "lines") assigned the 15th"
                )
            }
            if !plan.issues.isEmpty {
                previewRow(
                    "exclamationmark.triangle.fill",
                    Color(hex: "#c47f17"),
                    "\(plan.issues.count) \(plan.issues.count == 1 ? "line" : "lines") couldn't be read:"
                )
                ForEach(plan.issues, id: \.self) { issue in
                    Text(issue)
                        .font(Theme.Font.mono(11))
                        .foregroundStyle(Theme.sub)
                        .padding(.leading, 26)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func previewRow(_ icon: String, _ color: Color, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 17)
            Text(label)
                .font(Theme.Font.body(13, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: Commit

    private var importButton: some View {
        Button(action: runImport) {
            Text(importedCount.map { "Imported \($0) ✓" } ?? "Import")
                .font(Theme.Font.body(15, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(importedCount == nil ? Theme.accent : Theme.accent2)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(plan.new.isEmpty || importedCount != nil)
        .opacity(plan.new.isEmpty && importedCount == nil ? 0.5 : 1)
    }

    private func runImport() {
        let plan = plan
        do {
            try NoteImportService.apply(plan, context: modelContext)
            importedCount = plan.new.count
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                dismiss()
            }
        } catch {
            showImportError = true
        }
    }
}
