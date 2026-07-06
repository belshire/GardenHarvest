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

    /// The single date with the most distinct crops picked (≥ 3). Ties break
    /// toward the earliest date so results are stable.
    static func busiestDay(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let byDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .mapValues { Set($0.map(\.cropName)) }
        guard let busiest = byDay
            .sorted(by: { $0.value.count == $1.value.count ? $0.key < $1.key : $0.value.count > $1.value.count })
            .first, busiest.value.count >= 3
        else { return nil }
        return .busiestDay(date: busiest.key, crops: busiest.value.sorted())
    }

    /// Crop with ≥ 5 pickings across ≥ 28 days whose longest gap between
    /// consecutive pickings is at most 35% of its span — i.e. it kept
    /// producing with no long dry spells. Best (smallest max-gap ratio) wins.
    static func steadyProducer(in entries: [HarvestEntry], calendar: Calendar = .current) -> InsightFact? {
        let candidates: [(crop: String, pickings: Int, ratio: Double)] =
            Dictionary(grouping: entries, by: \.cropName).compactMap { crop, cropEntries in
                guard cropEntries.count >= 5 else { return nil }
                let days = cropEntries.map { calendar.startOfDay(for: $0.date) }.sorted()
                let span = calendar.dateComponents([.day], from: days.first!, to: days.last!).day ?? 0
                guard span >= 28 else { return nil }
                let maxGap = zip(days, days.dropFirst())
                    .map { calendar.dateComponents([.day], from: $0, to: $1).day ?? 0 }
                    .max() ?? 0
                return (crop, cropEntries.count, Double(maxGap) / Double(span))
            }
        guard let best = candidates
            .sorted(by: { $0.ratio == $1.ratio ? $0.crop < $1.crop : $0.ratio < $1.ratio })
            .first, best.ratio <= 0.35
        else { return nil }
        return .steadyProducer(crop: best.crop, pickings: best.pickings)
    }

    /// Crop with the most distinct non-empty logged variants (≥ 2).
    static func varietyCollector(in entries: [HarvestEntry]) -> InsightFact? {
        let variantCounts = Dictionary(grouping: entries, by: \.cropName)
            .mapValues { cropEntries in
                Set(cropEntries.compactMap { $0.variant }.filter { !$0.isEmpty }).count
            }
        guard let collector = variantCounts
            .sorted(by: { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value })
            .first, collector.value >= 2
        else { return nil }
        return .varietyCollector(crop: collector.key, variantCount: collector.value)
    }

    /// The season's insight cards: every triggered extractor in
    /// interestingness priority order, capped at five.
    static func topFacts(in entries: [HarvestEntry], calendar: Calendar = .current) -> [InsightFact] {
        let extracted: [InsightFact?] = [
            frequencyWeightSplit(in: entries),
            marathonCrop(in: entries, calendar: calendar),
            seasonTimingOutlier(in: entries, calendar: calendar),
            busiestDay(in: entries, calendar: calendar),
            steadyProducer(in: entries, calendar: calendar),
            varietyCollector(in: entries),
            oneDayWonder(in: entries)
        ]
        return Array(extracted.compactMap { $0 }.prefix(5))
    }
}

extension InsightFact {
    /// Plain-English statement of the fact, fed verbatim to the on-device
    /// model so it rewords exactly this and nothing more.
    var promptLine: String {
        switch self {
        case .frequencyWeightSplit(let mostPicked, let heaviest):
            return "The gardener picked \(mostPicked) as often as any other crop, but no crop weighed more in total than \(heaviest)."
        case .marathonCrop(let crop, let spanDays):
            return "\(crop) had the longest harvest run, spanning about \(spanDays) days from first picking to last."
        case .lateBloomer(let crop):
            return "\(crop) produced mostly at the very end of the season, later than every other crop."
        case .earlyBird(let crop):
            return "\(crop) produced at the very start of the season, earlier than every other crop."
        case .busiestDay(let date, let crops):
            return "The busiest day was \(ReportStats.monthDayLabel(date)), when \(crops.count) different crops were picked: \(crops.joined(separator: ", "))."
        case .steadyProducer(let crop, let pickings):
            return "\(crop) was the steadiest producer, with \(pickings) pickings spread evenly with no long dry spells."
        case .varietyCollector(let crop, let variantCount):
            return "The gardener grew \(variantCount) different varieties of \(crop)."
        case .oneDayWonder(let crop):
            return "\(crop) was picked exactly once all season."
        }
    }
}
