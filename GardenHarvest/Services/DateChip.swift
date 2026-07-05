import Foundation

enum DateChip: Int, CaseIterable {
    case today = 0
    case yesterday = 1
    case twoDaysAgo = 2

    var label: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .twoDaysAgo: return "2 days ago"
        }
    }

    func date(from reference: Date = .now, calendar: Calendar = .current) -> Date {
        let startOfReference = calendar.startOfDay(for: reference)
        return calendar.date(byAdding: .day, value: -rawValue, to: startOfReference) ?? startOfReference
    }
}
