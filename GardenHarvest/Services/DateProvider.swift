import Foundation

/// Injection seam for "today". Everything that derives the current season
/// (calendar year) or defaults a date to now reads through here instead of
/// touching the clock directly, so year rollover can be simulated:
/// - Tests set `DateProvider.override` directly (and `reset()` when done).
/// - In the simulator, pass the launch argument `-overrideToday 2027-01-01`
///   (Scheme → Run → Arguments) to freeze "today" without touching the clock.
enum DateProvider {
    /// When set, `now` returns this instead of the real clock.
    static var override: Date?

    /// The current date, honoring the override when one is set.
    static var now: Date { override ?? Date() }

    /// The current calendar year (the app's notion of "season").
    static var currentYear: Int {
        Calendar.current.component(.year, from: now)
    }

    /// Clears any override so `now` reads the real clock again.
    static func reset() {
        override = nil
    }

    /// Reads `-overrideToday yyyy-MM-dd` from the launch arguments and, if
    /// present and parseable, installs it as the override. Called once at
    /// startup.
    static func applyLaunchArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard let flagIndex = arguments.firstIndex(of: "-overrideToday"),
              arguments.indices.contains(flagIndex + 1),
              let date = parse(arguments[flagIndex + 1])
        else { return }
        override = date
    }

    /// Parses a `yyyy-MM-dd` string in the current calendar/timezone.
    static func parse(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
