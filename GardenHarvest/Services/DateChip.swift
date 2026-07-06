import Foundation

enum DateChip: CaseIterable {
    case today
    case yesterday
    case custom

    var label: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .custom: return "Custom"
        }
    }

    /// Days to subtract from the reference day for the fixed chips.
    /// `nil` for `.custom`, which uses a user-picked date instead.
    private var dayOffset: Int? {
        switch self {
        case .today: return 0
        case .yesterday: return 1
        case .custom: return nil
        }
    }

    /// Resolves the harvest date for this chip. For `.custom`, the caller-supplied
    /// `customDate` is used (normalized to the start of its day); the fixed chips
    /// subtract their offset from the reference day.
    func date(customDate: Date = .now, from reference: Date = .now, calendar: Calendar = .current) -> Date {
        guard let dayOffset else {
            return calendar.startOfDay(for: customDate)
        }
        let startOfReference = calendar.startOfDay(for: reference)
        return calendar.date(byAdding: .day, value: -dayOffset, to: startOfReference) ?? startOfReference
    }
}
