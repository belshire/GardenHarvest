import SwiftUI

/// Centered top-bar text block shared by the Home and Log headers: an accent
/// eyebrow line over a heavy serif page title.
struct PageHeaderTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(eyebrow)
                .font(Theme.Font.mono(13.5, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.Font.heading(27, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
        .multilineTextAlignment(.center)
    }
}
