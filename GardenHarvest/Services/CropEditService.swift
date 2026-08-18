import Foundation
import SwiftData

/// Renames, merges and deletes crops, keeping the log in step.
///
/// `HarvestEntry.cropName` is a loose string copy rather than a relationship
/// and `Crop.name` is `@Attribute(.unique)` (and `Crop.id`), so every edit to a
/// crop's name has to rewrite its entries in the same save — otherwise the log,
/// filters and reports lose the history behind the crop.
enum CropEditService {
    /// What a name/icon change (or a delete) would touch, for the sheet's
    /// blast-radius line and the delete confirmation.
    struct BlastRadius: Equatable {
        let entryCount: Int
        /// Distinct calendar years the crop's entries fall in.
        let seasonCount: Int
        let firstYear: Int?
        let totalOunces: Double

        static let none = BlastRadius(entryCount: 0, seasonCount: 0, firstYear: nil, totalOunces: 0)
    }

    /// Trimmed, with a `MasterCropList` entry winning on casing — the same rule
    /// `AddCropView.commit()` applies, so "kale" and "Kale" stay one crop.
    static func canonicalName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return MasterCropList.names.first { $0.lowercased() == trimmed.lowercased() } ?? trimmed
    }

    /// The other crop `newName` would collide with, or nil when the name is
    /// free. Case-insensitive, and never the crop being edited.
    static func collision(for newName: String, editing crop: Crop, in crops: [Crop]) -> Crop? {
        let candidate = canonicalName(newName).lowercased()
        guard !candidate.isEmpty else { return nil }
        return crops.first { $0.id != crop.id && $0.name.lowercased() == candidate }
    }

    static func blastRadius(of cropName: String, in entries: [HarvestEntry]) -> BlastRadius {
        let mine = entries.filter { $0.cropName == cropName }
        guard !mine.isEmpty else { return .none }
        let calendar = Calendar.current
        let years = Set(mine.map { calendar.component(.year, from: $0.date) })
        return BlastRadius(
            entryCount: mine.count,
            seasonCount: years.count,
            firstYear: years.min(),
            totalOunces: mine.reduce(0) { $0 + $1.ounces }
        )
    }

    /// Renames the crop and rewrites every `HarvestEntry.cropName` for it,
    /// across all seasons, in one save. Returns the number of entries touched.
    @discardableResult
    static func rename(_ crop: Crop, to newName: String, in context: ModelContext) throws -> Int {
        let canonical = canonicalName(newName)
        guard !canonical.isEmpty, canonical != crop.name else { return 0 }

        let oldName = crop.name
        let touched = try matchingEntries(oldName, in: context)
        crop.name = canonical
        for entry in touched {
            entry.cropName = canonical
        }
        try context.save()
        return touched.count
    }

    /// Moves all of `source`'s entries onto `target` and deletes `source`.
    /// `target` keeps its own icon, color and sort position; only variants are
    /// unioned, since those are per-crop vocabulary worth preserving.
    /// Returns the number of entries moved.
    @discardableResult
    static func merge(_ source: Crop, into target: Crop, in context: ModelContext) throws -> Int {
        guard source.id != target.id else { return 0 }

        let moving = try matchingEntries(source.name, in: context)
        for entry in moving {
            entry.cropName = target.name
        }
        target.variants.append(contentsOf: source.variants.filter { !target.variants.contains($0) })
        context.delete(source)
        try context.save()
        return moving.count
    }

    /// Deletes the crop and every entry naming it. Returns the entries removed.
    @discardableResult
    static func delete(_ crop: Crop, in context: ModelContext) throws -> Int {
        let doomed = try matchingEntries(crop.name, in: context)
        for entry in doomed {
            context.delete(entry)
        }
        context.delete(crop)
        try context.save()
        return doomed.count
    }

    /// Entries are written from the canonical crop name, so an exact match is
    /// the right join here.
    private static func matchingEntries(_ cropName: String, in context: ModelContext) throws -> [HarvestEntry] {
        try context.fetch(
            FetchDescriptor<HarvestEntry>(predicate: #Predicate { $0.cropName == cropName })
        )
    }
}
