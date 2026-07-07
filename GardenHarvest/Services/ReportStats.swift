import Foundation

/// Pure derivations for the season Report (harvest "unwrapped") tab: crop
/// rankings, the Season MVP superlative, per-crop picking timelines, and the
/// half-month buckets behind "When it peaked".
enum ReportStats {
    private static let shortMonths = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private static let fullMonths = ["", "January", "February", "March", "April", "May", "June",
                                     "July", "August", "September", "October", "November", "December"]

    /// Crops ranked by total ounces descending; name breaks ties so the
    /// ordering is stable run to run.
    static func rankedCrops(_ entries: [HarvestEntry]) -> [(name: String, total: Double)] {
        LogGrouping.totalsByCrop(entries)
            .map { (name: $0.key, total: $0.value) }
            .sorted { $0.total == $1.total ? $0.name < $1.name : $0.total > $1.total }
    }

    // MARK: Available report years

    /// Years the Report can browse, newest first: every year with at least
    /// one entry, plus the current year — so a fresh January (no entries yet)
    /// still opens on "this season" and can step back to years with data.
    static func availableReportYears(
        in entries: [HarvestEntry],
        currentYear: Int,
        calendar: Calendar = .current
    ) -> [Int] {
        var years = Set(entries.map { calendar.component(.year, from: $0.date) })
        years.insert(currentYear)
        return years.sorted(by: >)
    }

    // MARK: Season MVP

    static let superlativeTitles: [String: String] = [
        "Raspberries": "Bramble royalty",
        "Strawberries": "Strawberry sovereign of the season",
        "Asparagus": "Spring spear champion",
        "Blueberries": "Blue-ribbon berry",
        "Boysenberries": "The rare-berry connoisseur",
        "Artichoke": "Thistle whisperer",
        "Peas": "Pod squad leader"
    ]

    static func superlativeTitle(for crop: String, year: Int) -> String {
        superlativeTitles[crop] ?? "Most-picked crop of \(String(year))"
    }

    // MARK: When it peaked

    /// One half-month column of the season timeline. Only the early half
    /// carries the month label so each month is labeled once.
    struct HalfMonthBucket {
        let month: Int
        let isEarly: Bool
        let label: String
        let total: Double
    }

    /// Half-month harvest totals spanning the first through last month with
    /// entries. Days 1–15 count as the early half, matching the prototype.
    static func halfMonthBuckets(of entries: [HarvestEntry], calendar: Calendar = .current) -> [HalfMonthBucket] {
        let months = entries.map { calendar.component(.month, from: $0.date) }
        guard let lo = months.min(), let hi = months.max() else { return [] }
        var totals = [Double](repeating: 0, count: (hi - lo + 1) * 2)
        for entry in entries {
            let month = calendar.component(.month, from: entry.date)
            let early = calendar.component(.day, from: entry.date) <= 15
            totals[(month - lo) * 2 + (early ? 0 : 1)] += entry.ounces
        }
        return (lo...hi).flatMap { month in
            [
                HalfMonthBucket(month: month, isEarly: true, label: shortMonths[month],
                                total: totals[(month - lo) * 2]),
                HalfMonthBucket(month: month, isEarly: false, label: "",
                                total: totals[(month - lo) * 2 + 1])
            ]
        }
    }

    /// "Early July" / "Late May" for the biggest half-month, `nil` when
    /// nothing has been logged.
    static func peakLabel(of entries: [HarvestEntry], calendar: Calendar = .current) -> String? {
        let buckets = halfMonthBuckets(of: entries, calendar: calendar)
        guard let peak = buckets.max(by: { $0.total < $1.total }), peak.total > 0 else { return nil }
        return (peak.isEarly ? "Early " : "Late ") + fullMonths[peak.month]
    }

    // MARK: Per-crop picking timeline

    struct CropTimeline {
        struct Point {
            /// Horizontal position across the whole season's span, 0...1.
            let x: Double
            /// Bar height relative to the crop's biggest picking, 0...1.
            let heightFraction: Double
        }

        struct AxisTick {
            let x: Double
            let label: String
        }

        let points: [Point]
        let ticks: [AxisTick]
        /// e.g. "12 pickings · Mar 10 – Jun 28 · biggest 36 oz"
        let statLine: String
    }

    /// Timeline of one crop's pickings placed along the full season's date
    /// span (so different crops' charts share the same time axis), with month
    /// ticks covering the crop's own first-to-last stretch.
    static func cropTimeline(
        for crop: String,
        seasonEntries: [HarvestEntry],
        calendar: Calendar = .current
    ) -> CropTimeline? {
        let seasonDays = seasonEntries.map { calendar.startOfDay(for: $0.date) }
        guard let seasonStart = seasonDays.min(), let seasonEnd = seasonDays.max() else { return nil }
        let span = max(1, calendar.dateComponents([.day], from: seasonStart, to: seasonEnd).day ?? 1)

        let cropEntries = seasonEntries
            .filter { $0.cropName == crop }
            .sorted { $0.date < $1.date }
        guard let first = cropEntries.first, let last = cropEntries.last else { return nil }
        let biggest = cropEntries.map(\.ounces).max() ?? 1

        let points = cropEntries.map { entry in
            let day = calendar.startOfDay(for: entry.date)
            let offset = calendar.dateComponents([.day], from: seasonStart, to: day).day ?? 0
            return CropTimeline.Point(
                x: Double(offset) / Double(span),
                heightFraction: biggest > 0 ? entry.ounces / biggest : 0
            )
        }

        var ticks: [CropTimeline.AxisTick] = []
        let firstMonth = calendar.component(.month, from: first.date)
        let lastMonth = calendar.component(.month, from: last.date)
        let year = calendar.component(.year, from: first.date)
        if firstMonth <= lastMonth {
            for month in firstMonth...lastMonth {
                guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { continue }
                let offset = calendar.dateComponents([.day], from: seasonStart, to: monthStart).day ?? 0
                let x = min(1, max(0, Double(offset) / Double(span)))
                ticks.append(CropTimeline.AxisTick(x: x, label: shortMonths[month]))
            }
        }

        let range = cropEntries.count == 1
            ? monthDayLabel(first.date, calendar: calendar)
            : "\(monthDayLabel(first.date, calendar: calendar)) – \(monthDayLabel(last.date, calendar: calendar))"
        let statLine = "\(cropEntries.count) picking\(cropEntries.count == 1 ? "" : "s")"
            + " · \(range)"
            + " · biggest \(WeightFormatter.ounces(biggest)) oz"

        return CropTimeline(points: points, ticks: ticks, statLine: statLine)
    }

    /// "Jun 28" — fixed English month names, same as the prototype.
    static func monthDayLabel(_ date: Date, calendar: Calendar = .current) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(shortMonths[month]) \(day)"
    }
}
