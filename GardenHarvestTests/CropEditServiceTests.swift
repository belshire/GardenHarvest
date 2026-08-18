import Testing
import SwiftData
import Foundation
@testable import GardenHarvest

struct CropEditServiceTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([HarvestEntry.self, Crop.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [configuration]))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @discardableResult
    private func insertCrop(_ name: String, sortIndex: Int = 0, in context: ModelContext) -> Crop {
        let crop = Crop(name: name, colorHex: "#5a9a3d", sortIndex: sortIndex)
        context.insert(crop)
        return crop
    }

    private func insertEntry(_ cropName: String, _ ounces: Double, _ date: Date, in context: ModelContext) {
        context.insert(HarvestEntry(cropName: cropName, ounces: ounces, date: date))
    }

    private func entries(in context: ModelContext) throws -> [HarvestEntry] {
        try context.fetch(FetchDescriptor<HarvestEntry>())
    }

    private func crops(in context: ModelContext) throws -> [Crop] {
        try context.fetch(FetchDescriptor<Crop>())
    }

    // MARK: rename

    @Test func renameRewritesEveryEntryAcrossSeasons() throws {
        let context = try makeContext()
        let crop = insertCrop("Tomatoes", in: context)
        insertEntry("Tomatoes", 12, date(2024, 7, 3), in: context)
        insertEntry("Tomatoes", 8, date(2025, 8, 14), in: context)
        insertEntry("Peas", 4, date(2025, 6, 1), in: context)
        try context.save()

        let touched = try CropEditService.rename(crop, to: "Sungold", in: context)

        #expect(touched == 2)
        #expect(crop.name == "Sungold")
        let renamed = try entries(in: context).filter { $0.cropName == "Sungold" }
        #expect(renamed.count == 2)
        #expect(try entries(in: context).filter { $0.cropName == "Tomatoes" }.isEmpty)
        #expect(try entries(in: context).filter { $0.cropName == "Peas" }.count == 1)
    }

    @Test func renameTrimsWhitespace() throws {
        let context = try makeContext()
        let crop = insertCrop("Tomatoes", in: context)
        insertEntry("Tomatoes", 12, date(2026, 7, 3), in: context)
        try context.save()

        try CropEditService.rename(crop, to: "  Sungold  ", in: context)

        #expect(crop.name == "Sungold")
        #expect(try entries(in: context).first?.cropName == "Sungold")
    }

    @Test func renameAdoptsMasterCropListCasing() throws {
        let context = try makeContext()
        let crop = insertCrop("Sungold", in: context)
        try context.save()

        // "kale" differs only in case from the canonical master-list entry.
        try CropEditService.rename(crop, to: "kale", in: context)

        #expect(crop.name == "Kale")
    }

    @Test func renamingToTheSameNameTouchesNothing() throws {
        let context = try makeContext()
        let crop = insertCrop("Tomatoes", in: context)
        insertEntry("Tomatoes", 12, date(2026, 7, 3), in: context)
        try context.save()

        let touched = try CropEditService.rename(crop, to: "Tomatoes", in: context)

        #expect(touched == 0)
        #expect(crop.name == "Tomatoes")
    }

    // MARK: merge

    @Test func mergeMovesEntriesAndDeletesTheSource() throws {
        let context = try makeContext()
        let source = insertCrop("Tomatoes", sortIndex: 0, in: context)
        let target = insertCrop("Kale", sortIndex: 1, in: context)
        target.iconAssetName = "VegIcons/kale"
        insertEntry("Tomatoes", 12, date(2024, 7, 3), in: context)
        insertEntry("Tomatoes", 8, date(2025, 8, 14), in: context)
        insertEntry("Kale", 6, date(2026, 5, 2), in: context)
        try context.save()

        let moved = try CropEditService.merge(source, into: target, in: context)

        #expect(moved == 2)
        #expect(try crops(in: context).map(\.name).sorted() == ["Kale"])
        let all = try entries(in: context)
        #expect(all.count == 3)
        #expect(all.allSatisfy { $0.cropName == "Kale" })
        // The target keeps its own icon.
        #expect(target.iconAssetName == "VegIcons/kale")
    }

    @Test func mergeUnionsVariants() throws {
        let context = try makeContext()
        let source = Crop(name: "Tomatoes", colorHex: "#5a9a3d", sortIndex: 0, variants: ["small", "big"])
        let target = Crop(name: "Kale", colorHex: "#5a9a3d", sortIndex: 1, variants: ["big"])
        context.insert(source)
        context.insert(target)
        try context.save()

        try CropEditService.merge(source, into: target, in: context)

        #expect(target.variants == ["big", "small"])
    }

    // MARK: delete

    @Test func deleteRemovesTheCropAndItsEntries() throws {
        let context = try makeContext()
        let crop = insertCrop("Tomatoes", in: context)
        insertCrop("Peas", sortIndex: 1, in: context)
        insertEntry("Tomatoes", 12, date(2024, 7, 3), in: context)
        insertEntry("Tomatoes", 8, date(2025, 8, 14), in: context)
        insertEntry("Peas", 4, date(2025, 6, 1), in: context)
        try context.save()

        let removed = try CropEditService.delete(crop, in: context)

        #expect(removed == 2)
        #expect(try crops(in: context).map(\.name) == ["Peas"])
        #expect(try entries(in: context).map(\.cropName) == ["Peas"])
    }

    // MARK: collision detection

    @Test func collisionDetectionIsCaseInsensitiveAndSkipsTheCropItself() {
        let tomatoes = Crop(name: "Tomatoes", colorHex: "#5a9a3d", sortIndex: 0)
        let kale = Crop(name: "Kale", colorHex: "#5a9a3d", sortIndex: 1)
        let all = [tomatoes, kale]

        #expect(CropEditService.collision(for: "  kALe ", editing: tomatoes, in: all) === kale)
        #expect(CropEditService.collision(for: "Tomatoes", editing: tomatoes, in: all) == nil)
        #expect(CropEditService.collision(for: "Sungold", editing: tomatoes, in: all) == nil)
    }

    @Test func collisionMatchesTheCanonicalCasingOfATypedName() {
        let sungold = Crop(name: "Sungold", colorHex: "#5a9a3d", sortIndex: 0)
        let kale = Crop(name: "Kale", colorHex: "#5a9a3d", sortIndex: 1)

        // "kale" canonicalizes to "Kale", which already exists.
        #expect(CropEditService.collision(for: "kale", editing: sungold, in: [sungold, kale]) === kale)
    }

    // MARK: blast radius

    @Test func blastRadiusCountsEntriesAndDistinctSeasons() {
        let entries = [
            HarvestEntry(cropName: "Tomatoes", ounces: 12, date: date(2024, 7, 3)),
            HarvestEntry(cropName: "Tomatoes", ounces: 8, date: date(2025, 8, 14)),
            HarvestEntry(cropName: "Tomatoes", ounces: 20, date: date(2025, 9, 1)),
            HarvestEntry(cropName: "Peas", ounces: 4, date: date(2026, 6, 1))
        ]

        let radius = CropEditService.blastRadius(of: "Tomatoes", in: entries)

        #expect(radius.entryCount == 3)
        #expect(radius.seasonCount == 2)
        #expect(radius.firstYear == 2024)
        #expect(radius.totalOunces == 40)
    }

    @Test func blastRadiusOfACropWithNoEntriesIsEmpty() {
        let radius = CropEditService.blastRadius(of: "Tomatoes", in: [])

        #expect(radius.entryCount == 0)
        #expect(radius.seasonCount == 0)
        #expect(radius.firstYear == nil)
        #expect(radius.totalOunces == 0)
    }
}
