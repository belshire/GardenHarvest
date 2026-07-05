import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.Font.heading(24, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Coming soon")
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.sub)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.panelBackground.ignoresSafeArea())
    }
}
