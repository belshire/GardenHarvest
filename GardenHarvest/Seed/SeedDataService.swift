import Foundation
import SwiftData

enum SeedDataService {
    struct BaseEntry {
        let crop: String
        let ounces: Double
        let monthDay: String // "MM-DD"
        let note: String
    }

    struct SeedEntry {
        let crop: String
        let ounces: Double
        let date: Date
        let note: String
    }

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    // Real 2026 harvest data, transcribed from the user's `harvets.txt` and the
    // prototype's `RAW` constant. Format: "MM-DD|Crop|ounces|note".
    static let rawData = """
    03-10|Asparagus|18|
    03-12|Mushrooms|8|
    04-07|Asparagus|31|
    04-13|Asparagus|36|14 oz woody
    04-15|Asparagus|14|
    04-19|Asparagus|12|
    04-21|Asparagus|8|
    04-23|Asparagus|12|
    04-26|Asparagus|8|
    04-28|Asparagus|8|
    04-30|Asparagus|16|
    05-02|Asparagus|6|
    05-04|Asparagus|14.5|
    05-07|Asparagus|6|
    05-09|Asparagus|4|
    05-09|Strawberries|1|
    05-11|Strawberries|1|
    05-12|Asparagus|19.5|
    05-12|Artichoke|11.5|
    05-12|Radishes|6.75|
    05-12|Strawberries|1|
    05-13|Strawberries|0.75|
    05-14|Asparagus|13|
    05-15|Strawberries|3.5|
    05-16|Asparagus|3|
    05-16|Strawberries|2.75|
    05-18|Asparagus|1.5|
    05-18|Strawberries|1|
    05-19|Strawberries|4|
    05-20|Strawberries|1.5|
    05-20|Asparagus|8|
    05-23|Asparagus|12|
    05-23|Strawberries|4.5|
    05-23|Radishes|2.75|
    05-23|Artichoke|10.25|
    05-25|Strawberries|10.75|
    05-27|Asparagus|4|
    05-27|Strawberries|8.5|
    05-30|Asparagus|3|
    05-30|Strawberries|14|
    05-31|Strawberries|10|
    06-01|Strawberries|1.5|
    06-03|Strawberries|3.5|
    06-03|Asparagus|2|
    06-04|Strawberries|1|
    06-04|Blueberries|2|
    06-06|Asparagus|2|
    06-06|Strawberries|3.5|
    06-06|Raspberries|4|
    06-09|Asparagus|1.75|
    06-09|Strawberries|10.75|
    06-09|Raspberries|9.5|
    06-09|Blueberries|3|
    06-09|Artichoke|9|
    06-09|Artichoke|11.5|
    06-11|Raspberries|7.6|small
    06-11|Strawberries|9|
    06-11|Blueberries|1.2|
    06-11|Asparagus|5.2|
    06-11|Raspberries|1|large
    06-11|Boysenberries|2.15|
    06-13|Strawberries|5.5|
    06-13|Blueberries|1.2|
    06-13|Asparagus|1.1|
    06-13|Raspberries|0.6|large
    06-13|Boysenberries|0.75|
    06-14|Raspberries|4.5|small
    06-14|Raspberries|1|large
    06-14|Boysenberries|0.55|
    06-15|Blueberries|5|
    06-15|Raspberries|4.75|small
    06-15|Raspberries|0.75|large
    06-15|Strawberries|5|
    06-16|Boysenberries|1|
    06-16|Raspberries|4|small
    06-16|Raspberries|1.7|large
    06-16|Strawberries|0.7|
    06-17|Blueberries|2|
    06-17|Boysenberries|1.8|
    06-17|Raspberries|6.5|small
    06-17|Raspberries|5.75|large
    06-17|Strawberries|2.2|
    06-18|Peas|6.5|
    06-20|Raspberries|5|
    06-21|Strawberries|3.4|
    06-21|Blueberries|1.1|
    06-21|Raspberries|7.4|small
    06-21|Raspberries|9.8|large
    06-21|Peas|3.9|
    06-21|Artichoke|10.8|
    06-22|Boysenberries|3.4|
    06-23|Strawberries|3.2|
    06-23|Blueberries|2|
    06-23|Raspberries|3.4|small
    06-23|Raspberries|12.4|large
    06-23|Peas|4|
    06-23|Tomatoes Cherry|0.63|
    06-23|Boysenberries|0.5|
    06-25|Blueberries|0.75|
    06-25|Raspberries|3.5|small
    06-25|Raspberries|8.75|large
    06-25|Strawberries|3.4|
    06-25|Boysenberries|1|
    06-27|Blueberries|0.75|
    06-27|Raspberries|1|small
    06-27|Raspberries|12|large
    06-27|Strawberries|7.9|
    06-27|Peas|9.5|
    06-28|Raspberries|4.3|large
    06-28|Strawberries|3.6|
    """

    static func parseBase() -> [BaseEntry] {
        rawData
            .split(separator: "\n")
            .map { line -> BaseEntry in
                let parts = String(line).components(separatedBy: "|")
                let monthDay = parts[0]
                let crop = parts[1]
                let ounces = Double(parts[2]) ?? 0
                let note = parts.count > 3 ? parts[3] : ""
                return BaseEntry(crop: crop, ounces: ounces, monthDay: monthDay, note: note)
            }
    }

    static func date(year: Int, monthDay: String) -> Date? {
        let parts = monthDay.components(separatedBy: "-")
        guard parts.count == 2, let month = Int(parts[0]), let day = Int(parts[1]) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return utcCalendar.date(from: components)
    }

    static func buildSeed(currentYear: Int) -> [SeedEntry] {
        parseBase().compactMap { entry in
            guard let entryDate = date(year: currentYear, monthDay: entry.monthDay) else { return nil }
            return SeedEntry(crop: entry.crop, ounces: entry.ounces, date: entryDate, note: entry.note)
        }
    }

    static let knownCrops: [(name: String, variants: [String])] = [
        ("Asparagus", []),
        ("Strawberries", []),
        ("Raspberries", ["small", "large"]),
        ("Blueberries", []),
        ("Boysenberries", []),
        ("Artichoke", []),
        ("Peas", []),
        ("Radishes", []),
        ("Mushrooms", []),
        ("Tomatoes Cherry", [])
    ]

    static func seedIfNeeded(context: ModelContext, currentYear: Int) {
        let existingCrops = (try? context.fetch(FetchDescriptor<Crop>())) ?? []
        guard existingCrops.isEmpty else { return }

        for (index, crop) in knownCrops.enumerated() {
            let record = Crop(
                name: crop.name,
                colorHex: CropColorAssigner.colorHex(for: crop.name),
                sortIndex: index,
                variants: crop.variants
            )
            context.insert(record)
        }

        for entry in buildSeed(currentYear: currentYear) {
            context.insert(HarvestEntry(cropName: entry.crop, ounces: entry.ounces, date: entry.date, note: entry.note))
        }

        try? context.save()
    }
}
