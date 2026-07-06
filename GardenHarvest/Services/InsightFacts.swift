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
    /// A crop picked exactly once all season (only when others were picked more).
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
}
