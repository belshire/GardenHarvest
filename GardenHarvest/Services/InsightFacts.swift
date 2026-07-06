import Foundation

/// A qualitative observation about one season's harvest. Extraction is
/// deterministic so composers (template or AI) only decide wording, never
/// facts. Each case carries the crop(s) involved so the insight card can
/// show the right icon and color.
enum InsightFact: Equatable {
    /// The most-picked crop (by picking count) differs from the heaviest
    /// crop (by total ounces).
    case frequencyWeightSplit(mostPicked: String, heaviest: String)
    /// Longest first-to-last picking span.
    case marathonCrop(crop: String, spanDays: Int)
    /// Crop whose pickings sit latest in the season.
    case lateBloomer(crop: String)
    /// Crop whose pickings sit earliest in the season.
    case earlyBird(crop: String)
    /// The date with the most distinct crops picked.
    case busiestDay(date: Date, crops: [String])
    /// Many pickings, no long dry spells across its span.
    case steadyProducer(crop: String, pickings: Int)
    /// Crop with the most distinct logged variants.
    case varietyCollector(crop: String, variantCount: Int)
    /// A crop picked exactly once, in a season with at least one other crop.
    case oneDayWonder(crop: String)

    /// Crop whose icon/color the card should use; nil → generic sparkle.
    var primaryCrop: String? {
        switch self {
        case .frequencyWeightSplit(let mostPicked, _):
            return mostPicked
        case .marathonCrop(let crop, _), .lateBloomer(let crop), .earlyBird(let crop),
             .steadyProducer(let crop, _), .varietyCollector(let crop, _),
             .oneDayWonder(let crop):
            return crop
        case .busiestDay:
            return nil
        }
    }

    /// Stable identifier for template seeding and cache round-trips.
    var kind: String {
        switch self {
        case .frequencyWeightSplit: return "frequencyWeightSplit"
        case .marathonCrop: return "marathonCrop"
        case .lateBloomer: return "lateBloomer"
        case .earlyBird: return "earlyBird"
        case .busiestDay: return "busiestDay"
        case .steadyProducer: return "steadyProducer"
        case .varietyCollector: return "varietyCollector"
        case .oneDayWonder: return "oneDayWonder"
        }
    }
}

/// Deterministic extraction of qualitative season insights. Each extractor
/// returns nil when its threshold isn't met; ties break alphabetically so
/// results are stable run to run.
enum InsightFacts {
    /// Picking counts per crop (each entry is one picking).
    static func pickingCounts(_ entries: [HarvestEntry]) -> [String: Int] {
        Dictionary(grouping: entries, by: \.cropName).mapValues(\.count)
    }

    static func frequencyWeightSplit(in entries: [HarvestEntry]) -> InsightFact? {
        let counts = pickingCounts(entries)
        guard let mostPicked = counts
            .sorted(by: { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value })
            .first, mostPicked.value >= 2
        else { return nil }
        guard let heaviest = ReportStats.rankedCrops(entries).first,
              heaviest.name != mostPicked.key
        else { return nil }
        return .frequencyWeightSplit(mostPicked: mostPicked.key, heaviest: heaviest.name)
    }

    static func oneDayWonder(in entries: [HarvestEntry]) -> InsightFact? {
        let counts = pickingCounts(entries)
        guard counts.count >= 2,
              let wonder = counts.filter({ $0.value == 1 }).keys.sorted().first
        else { return nil }
        return .oneDayWonder(crop: wonder)
    }

    /// Longest first-to-last picking span among crops with ≥ 2 pickings,
    /// emitted only when it reaches 30 days. Ties break alphabetically.
    static func marathonCrop(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let spans: [(crop: String, days: Int)] = Dictionary(grouping: entries, by: \.cropName)
            .compactMap { crop, cropEntries in
                let days = cropEntries.map { calendar.startOfDay(for: $0.date) }
                guard cropEntries.count >= 2, let first = days.min(), let last = days.max()
                else { return nil }
                let span = calendar.dateComponents([.day], from: first, to: last).day ?? 0
                return (crop, span)
            }
        guard let longest = spans
            .sorted(by: { $0.days == $1.days ? $0.crop < $1.crop : $0.days > $1.days })
            .first, longest.days >= 30
        else { return nil }
        return .marathonCrop(crop: longest.crop, spanDays: longest.days)
    }

    /// The crop (≥ 2 pickings) whose mean picking position across the
    /// season's date span sits latest (≥ 0.75 → late bloomer) or earliest
    /// (≤ 0.25 → early bird). Late bloomer wins when both exist. Needs at
    /// least two crops so the outlier has something to stand out from.
    static func seasonTimingOutlier(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let allDays = entries.map { calendar.startOfDay(for: $0.date) }
        guard Set(entries.map(\.cropName)).count >= 2,
              let seasonStart = allDays.min(), let seasonEnd = allDays.max(),
              seasonStart < seasonEnd
        else { return nil }
        let span = Double(calendar.dateComponents([.day], from: seasonStart, to: seasonEnd).day ?? 1)

        let means: [(crop: String, mean: Double)] = Dictionary(grouping: entries, by: \.cropName)
            .compactMap { crop, cropEntries in
                guard cropEntries.count >= 2 else { return nil }
                let positions = cropEntries.map { entry -> Double in
                    let day = calendar.startOfDay(for: entry.date)
                    let offset = calendar.dateComponents([.day], from: seasonStart, to: day).day ?? 0
                    return Double(offset) / span
                }
                return (crop, positions.reduce(0, +) / Double(positions.count))
            }

        if let late = means
            .filter({ $0.mean >= 0.75 })
            .sorted(by: { $0.mean == $1.mean ? $0.crop < $1.crop : $0.mean > $1.mean })
            .first {
            return .lateBloomer(crop: late.crop)
        }
        if let early = means
            .filter({ $0.mean <= 0.25 })
            .sorted(by: { $0.mean == $1.mean ? $0.crop < $1.crop : $0.mean < $1.mean })
            .first {
            return .earlyBird(crop: early.crop)
        }
        return nil
    }
}
