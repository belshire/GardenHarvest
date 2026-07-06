import Foundation

/// Pure derivations for the multi-year harvest Log: year lists, month/day
/// groupings, and per-crop totals.
enum LogGrouping {
    struct MonthGroup {
        let month: Int
        let total: Double
        let days: [DayGroup]
    }

    struct DayGroup {
        let date: Date
        let entries: [HarvestEntry]
    }

    /// Distinct years present in the entries, newest first.
    static func years(in entries: [HarvestEntry], calendar: Calendar = .current) -> [Int] {
        Set(entries.map { calendar.component(.year, from: $0.date) }).sorted(by: >)
    }

    static func entries(in year: Int, from entries: [HarvestEntry], calendar: Calendar = .current) -> [HarvestEntry] {
        entries.filter { calendar.component(.year, from: $0.date) == year }
    }

    /// Groups one year's entries by month (newest first) and day (newest first
    /// within each month).
    static func monthGroups(of entries: [HarvestEntry], calendar: Calendar = .current) -> [MonthGroup] {
        let byMonth = Dictionary(grouping: entries) { calendar.component(.month, from: $0.date) }
        return byMonth.keys.sorted(by: >).map { month in
            let monthEntries = byMonth[month] ?? []
            let byDay = Dictionary(grouping: monthEntries) { calendar.startOfDay(for: $0.date) }
            let days = byDay.keys.sorted(by: >).map { day in
                DayGroup(date: day, entries: byDay[day] ?? [])
            }
            let total = monthEntries.reduce(0) { $0 + $1.ounces }
            return MonthGroup(month: month, total: total, days: days)
        }
    }

    static func totalsByCrop(_ entries: [HarvestEntry]) -> [String: Double] {
        Dictionary(grouping: entries, by: \.cropName).mapValues { $0.reduce(0) { $0 + $1.ounces } }
    }

    /// Month (1–12) with the highest harvested total, `nil` when empty.
    static func peakMonth(of entries: [HarvestEntry], calendar: Calendar = .current) -> Int? {
        monthGroups(of: entries, calendar: calendar).max { $0.total < $1.total }?.month
    }
}
