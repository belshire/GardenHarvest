import Foundation

/// Parses the free-form Apple Note harvest log ("Garden Harvest 2026:",
/// month headings, lines like "Raspberries, small 7.6 oz (6/11)") into
/// structured entries. Pure text — no SwiftData, no store knowledge.
/// Anything it can't parse becomes an issue, never a guess.
enum HarvestNoteParser {
    struct ParsedEntry: Equatable {
        let crop: String
        let ounces: Double
        let month: Int
        /// nil for undated lines under a month heading; the importer
        /// assigns the 15th and flags the entry.
        let day: Int?
        let variant: String?
        let note: String
    }

    struct ParsedNote: Equatable {
        /// From the "Garden Harvest <year>" header, nil when absent.
        let year: Int?
        let entries: [ParsedEntry]
        /// "line — reason" for every line that was skipped.
        let issues: [String]
    }

    private static let monthNames = [
        "january": 1, "february": 2, "march": 3, "april": 4,
        "may": 5, "june": 6, "july": 7, "august": 8,
        "september": 9, "october": 10, "november": 11, "december": 12
    ]

    static func parse(_ text: String) -> ParsedNote {
        var year: Int?
        var entries: [ParsedEntry] = []
        var issues: [String] = []
        var currentMonth: Int?

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if let headerYear = headerYear(in: line) {
                year = headerYear
                continue
            }
            if let month = monthHeading(in: line) {
                currentMonth = month
                continue
            }

            switch parseEntryLine(line, monthContext: currentMonth) {
            case .entries(let lineEntries):
                entries.append(contentsOf: lineEntries)
            case .issue(let reason):
                issues.append("\(line) — \(reason)")
            }
        }
        return ParsedNote(year: year, entries: entries, issues: issues)
    }

    // MARK: Line classification

    /// "Garden Harvest 2026:" (or any header carrying a 4-digit year).
    private static func headerYear(in line: String) -> Int? {
        guard line.range(of: #"(?i)^garden harvest\s+\d{4}\s*:?\s*$"#, options: .regularExpression) != nil,
              let yearRange = line.range(of: #"\d{4}"#, options: .regularExpression)
        else { return nil }
        return Int(line[yearRange])
    }

    /// "June:" / "April: " month section headings.
    private static func monthHeading(in line: String) -> Int? {
        guard let match = line.range(of: #"(?i)^([a-z]+)\s*:\s*$"#, options: .regularExpression) else { return nil }
        let name = line[match]
            .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
            .lowercased()
        return monthNames[name]
    }

    private enum LineResult {
        case entries([ParsedEntry])
        case issue(String)
    }

    /// "Crop[, variant] amount[, more...] [(M/D[-D])]".
    private static func parseEntryLine(_ line: String, monthContext: Int?) -> LineResult {
        var body = line

        // Trailing "(M/D)" or "(M/D-D)" date; ranges use the first day.
        var month = monthContext
        var day: Int?
        if let dateRange = body.range(of: #"\(\s*(\d{1,2})\s*/\s*(\d{1,2})(?:\s*-\s*\d{1,2})?\s*\)\s*$"#, options: .regularExpression) {
            let numbers = body[dateRange]
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
            month = Int(numbers[0])
            day = Int(numbers[1])
            body.removeSubrange(dateRange)
            body = body.trimmingCharacters(in: .whitespaces)
        }

        guard let month else { return .issue("no month heading or (M/D) date") }

        // Everything before the first digit names the crop (and variant);
        // everything from it onward is the amounts section.
        guard let firstDigit = body.rangeOfCharacter(from: .decimalDigits) else {
            return .issue("no amount found")
        }
        let cropSegment = String(body[..<firstDigit.lowerBound])
        let amountsSegment = String(body[firstDigit.lowerBound...])

        let cropParts = cropSegment
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let crop = collapseSpaces(cropParts[0])
        guard !crop.isEmpty else { return .issue("no crop name") }
        let variant = cropParts.count > 1 && !cropParts[1].isEmpty ? cropParts[1] : nil

        // First component is the amount; later bare weights are extra
        // entries, weights with trailing text become the note verbatim.
        var ounces: Double?
        var extraOunces: [Double] = []
        var noteParts: [String] = []
        for (index, rawComponent) in amountsSegment.components(separatedBy: ",").enumerated() {
            let component = rawComponent.trimmingCharacters(in: .whitespaces)
            guard !component.isEmpty else { continue }
            guard let match = component.range(of: #"(?i)^(\d+(?:\.\d+)?)\s*(?:oz\b\.?)?\s*"#, options: .regularExpression) else {
                noteParts.append(component)
                continue
            }
            let number = Double(component[match].components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).first ?? "") ?? 0
            let rest = String(component[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            if index == 0 {
                ounces = number
                if !rest.isEmpty { noteParts.append(rest) }
            } else if rest.isEmpty {
                extraOunces.append(number)
            } else {
                noteParts.append(component)
            }
        }
        guard let ounces else { return .issue("no amount found") }

        let note = noteParts.joined(separator: "; ")
        var result = [ParsedEntry(crop: crop, ounces: ounces, month: month, day: day, variant: variant, note: note)]
        result += extraOunces.map {
            ParsedEntry(crop: crop, ounces: $0, month: month, day: day, variant: variant, note: "")
        }
        return .entries(result)
    }

    private static func collapseSpaces(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
