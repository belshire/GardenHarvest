import Foundation
import SwiftData

/// Plans and applies a harvest-note import. `plan` is pure — it takes
/// snapshots of the store and returns exactly what would change — so the
/// preview shows the truth and `apply` just executes it.
enum NoteImportService {
    struct PlannedEntry: Equatable {
        let crop: String
        let ounces: Double
        let date: Date
        let variant: String?
        let note: String
        /// The note line had no (M/D) date; the 15th was assumed.
        let dayAssumed: Bool
    }

    struct ImportPlan: Equatable {
        let new: [PlannedEntry]
        let duplicateCount: Int
        /// Crops the note mentions that don't exist yet, in first-seen order.
        let newCropNames: [String]
        /// Variants to append to existing (or newly created) crops.
        let newVariants: [String: [String]]
        /// Carried through from the parser for the preview.
        let issues: [String]
    }

    /// Case-insensitive, trailing-"s"-insensitive key so "Artichokes"
    /// matches the store's "Artichoke".
    static func cropKey(_ name: String) -> String {
        var key = name.lowercased()
        if key.hasSuffix("s") { key = String(key.dropLast()) }
        return key
    }

    static func plan(
        parsed: HarvestNoteParser.ParsedNote,
        fallbackYear: Int,
        existingEntries: [HarvestEntry],
        existingCrops: [Crop],
        calendar: Calendar = .current
    ) -> ImportPlan {
        let year = parsed.year ?? fallbackYear

        // Canonical crop names and known variants, note names folded in as
        // they appear so later lines match earlier new crops.
        var canonicalNames: [String: String] = [:]
        var knownVariants: [String: Set<String>] = [:]
        for crop in existingCrops {
            canonicalNames[cropKey(crop.name)] = crop.name
            knownVariants[crop.name] = Set(crop.variants)
        }

        // Dedup pool: each existing entry can absorb one incoming duplicate.
        // Only the imported year participates — the store holds other
        // seasons, and a 2025 entry must never absorb a 2026 note line.
        struct PoolEntry {
            let cropKey: String
            let month: Int
            let day: Int
            let ounces: Double
            let variant: String?
            var used = false
        }
        var pool = existingEntries
            .filter { calendar.component(.year, from: $0.date) == year }
            .map { entry in
                PoolEntry(
                    cropKey: cropKey(entry.cropName),
                    month: calendar.component(.month, from: entry.date),
                    day: calendar.component(.day, from: entry.date),
                    ounces: entry.ounces,
                    variant: entry.variant
                )
            }

        var new: [PlannedEntry] = []
        var duplicateCount = 0
        var newCropNames: [String] = []
        var newVariants: [String: [String]] = [:]

        for entry in parsed.entries {
            let key = cropKey(entry.crop)
            let canonical = canonicalNames[key] ?? entry.crop
            if canonicalNames[key] == nil {
                canonicalNames[key] = entry.crop
                newCropNames.append(entry.crop)
            }

            if let variant = entry.variant,
               !(knownVariants[canonical]?.contains(variant) ?? false) {
                knownVariants[canonical, default: []].insert(variant)
                newVariants[canonical, default: []].append(variant)
            }

            // Duplicate check: exact day when dated, same month when not.
            let matchIndex = pool.firstIndex { candidate in
                guard !candidate.used,
                      candidate.cropKey == key,
                      abs(candidate.ounces - entry.ounces) < 0.001,
                      candidate.variant == entry.variant,
                      candidate.month == entry.month
                else { return false }
                guard let day = entry.day else { return true }
                return candidate.day == day
            }
            if let matchIndex {
                pool[matchIndex].used = true
                duplicateCount += 1
                continue
            }

            var components = DateComponents()
            components.year = year
            components.month = entry.month
            components.day = entry.day ?? 15
            guard let date = calendar.date(from: components) else { continue }
            new.append(PlannedEntry(
                crop: canonical,
                ounces: entry.ounces,
                date: date,
                variant: entry.variant,
                note: entry.note,
                dayAssumed: entry.day == nil
            ))
        }

        return ImportPlan(
            new: new,
            duplicateCount: duplicateCount,
            newCropNames: newCropNames,
            newVariants: newVariants,
            issues: parsed.issues
        )
    }

    /// Inserts the planned entries, creates missing crops (color via the
    /// assigner, sort order appended), appends new variants, and saves once.
    static func apply(_ plan: ImportPlan, context: ModelContext) throws {
        let crops = (try? context.fetch(FetchDescriptor<Crop>())) ?? []
        var nextSortIndex = (crops.map(\.sortIndex).max() ?? -1) + 1
        var cropsByName = Dictionary(uniqueKeysWithValues: crops.map { ($0.name, $0) })

        for name in plan.newCropNames {
            let crop = Crop(
                name: name,
                colorHex: CropColorAssigner.colorHex(for: name),
                sortIndex: nextSortIndex,
                variants: plan.newVariants[name] ?? []
            )
            context.insert(crop)
            cropsByName[name] = crop
            nextSortIndex += 1
        }
        for (cropName, variants) in plan.newVariants where !plan.newCropNames.contains(cropName) {
            guard let crop = cropsByName[cropName] else { continue }
            crop.variants.append(contentsOf: variants.filter { !crop.variants.contains($0) })
        }

        for entry in plan.new {
            context.insert(HarvestEntry(
                cropName: entry.crop,
                ounces: entry.ounces,
                date: entry.date,
                note: entry.note,
                variant: entry.variant
            ))
        }
        try context.save()
    }
}
