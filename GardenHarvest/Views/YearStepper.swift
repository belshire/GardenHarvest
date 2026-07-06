import SwiftUI

/// ‹ / › circular step buttons flanking arbitrary header content (usually a
/// `PageHeaderTitle`), stepping through a newest-first list of years. Shared
/// by the Log and Report tabs so year navigation looks and behaves the same.
struct YearStepper<Center: View>: View {
    /// Distinct years to step through, newest first.
    let years: [Int]
    let selectedYear: Int
    let onSelect: (Int) -> Void
    @ViewBuilder let center: () -> Center

    private var yearIndex: Int? { years.firstIndex(of: selectedYear) }

    private var canGoOlder: Bool {
        guard let yearIndex else { return false }
        return yearIndex < years.count - 1
    }

    private var canGoNewer: Bool { (yearIndex ?? 0) > 0 }

    var body: some View {
        HStack(spacing: 10) {
            stepButton(glyph: "‹", enabled: canGoOlder) {
                if let yearIndex, canGoOlder { onSelect(years[yearIndex + 1]) }
            }
            center()
                .frame(maxWidth: .infinity)
            stepButton(glyph: "›", enabled: canGoNewer) {
                if let yearIndex, canGoNewer { onSelect(years[yearIndex - 1]) }
            }
        }
        .padding(.top, 2)
    }

    private func stepButton(glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(enabled ? Theme.accent : Theme.ink.opacity(0.16))
                .padding(.bottom, 2)
                .frame(width: 46, height: 46)
                .background(enabled ? Theme.card : Color.clear)
                .overlay(Circle().stroke(enabled ? Theme.ink.opacity(0.16) : Theme.hairline, lineWidth: 1.5))
                .clipShape(Circle())
                .shadow(color: Color(hex: "#1e3214").opacity(enabled ? 0.08 : 0), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
