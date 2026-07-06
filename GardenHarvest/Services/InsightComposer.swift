import Foundation

/// One composed insight card: the sentence, the fact kind it came from, and
/// the crop whose icon/color the card shows (nil → generic sparkle card).
struct Insight: Codable, Equatable {
    let kind: String
    let text: String
    let cropName: String?
}

/// Turns extracted facts into card sentences. Two implementations: templates
/// (always available, instant) and the on-device Apple Intelligence model.
protocol InsightComposer {
    func compose(facts: [InsightFact], season: Int) -> [Insight]
}

/// Hand-written whimsical wording, seeded by season + fact kind so the pick
/// is stable across views but varies year to year.
struct TemplateComposer: InsightComposer {
    func compose(facts: [InsightFact], season: Int) -> [Insight] {
        facts.map { fact in
            Insight(kind: fact.kind, text: text(for: fact, season: season),
                    cropName: fact.primaryCrop)
        }
    }

    private func text(for fact: InsightFact, season: Int) -> String {
        let variants = templates(for: fact)
        return variants[abs(season &* 7 &+ fact.kind.count) % variants.count]
    }

    private func templates(for fact: InsightFact) -> [String] {
        switch fact {
        case .frequencyWeightSplit(let mostPicked, let heaviest):
            return [
                "Most trips to the garden ended with \(mostPicked.lowercased()) in hand — but it was the \(heaviest.lowercased()) quietly tipping the scales.",
                "\(mostPicked) won on sheer number of pickings; \(heaviest.lowercased()) won the weigh-in."
            ]
        case .marathonCrop(let crop, _):
            return [
                "The long-haul award goes to \(crop.lowercased()) — first to show up, still going at the finish.",
                "\(crop) just kept giving, stretching across more of the season than anything else."
            ]
        case .lateBloomer(let crop):
            return [
                "\(crop) took the scenic route, saving their best for the tail end of the season.",
                "While the rest of the garden wound down, \(crop.lowercased()) were just warming up."
            ]
        case .earlyBird(let crop):
            return [
                "\(crop) beat everyone out of the gate this season.",
                "The season opened with \(crop.lowercased()) leading the charge."
            ]
        case .busiestDay(let date, let crops):
            let label = ReportStats.monthDayLabel(date)
            return [
                "\(label) was peak garden chaos — \(crops.count) different crops in one glorious haul.",
                "Circle \(label) on the calendar: \(crops.count) crops picked in a single day."
            ]
        case .steadyProducer(let crop, _):
            return [
                "No drama, no dry spells: \(crop.lowercased()) were your steadiest producer.",
                "\(crop) showed up again and again — the most dependable member of the patch."
            ]
        case .varietyCollector(let crop, let variantCount):
            return [
                "You didn't just grow \(crop.lowercased()) — you collected them, \(variantCount) varieties strong.",
                "\(crop) came in \(variantCount) different varieties this season. A true connoisseur move."
            ]
        case .oneDayWonder(let crop):
            return [
                "\(crop) made exactly one appearance — blink and you missed it.",
                "A single, glorious picking of \(crop.lowercased()). Some legends only need one day."
            ]
        }
    }
}
