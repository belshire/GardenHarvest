import AppIntents
import SwiftData

/// Shortcuts entry point for the note import, so a Shortcut can pull the
/// harvest note from Apple Notes ("Find Notes" action) and import it in one
/// tap. Same parser/planner as the in-app import sheet — already-logged
/// entries are skipped, unreadable lines are reported, nothing is guessed.
struct ImportHarvestNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Import Harvest Note"
    static let description = IntentDescription(
        "Imports harvest entries from note text. Entries already logged are skipped."
    )

    @Parameter(title: "Note text", inputOptions: String.IntentInputOptions(multiline: true))
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = AppModelContainer.shared.mainContext
        let entries = (try? context.fetch(FetchDescriptor<HarvestEntry>())) ?? []
        let crops = (try? context.fetch(FetchDescriptor<Crop>())) ?? []
        let plan = NoteImportService.plan(
            parsed: HarvestNoteParser.parse(text),
            fallbackYear: DateProvider.currentYear,
            existingEntries: entries,
            existingCrops: crops
        )
        try NoteImportService.apply(plan, context: context)

        var summary = "Imported \(plan.new.count) \(plan.new.count == 1 ? "entry" : "entries")"
        if plan.duplicateCount > 0 {
            summary += ", skipped \(plan.duplicateCount) already logged"
        }
        if !plan.issues.isEmpty {
            summary += ", couldn't read \(plan.issues.count) \(plan.issues.count == 1 ? "line" : "lines")"
        }
        return .result(dialog: "\(summary).")
    }
}
