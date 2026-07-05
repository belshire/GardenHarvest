import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.Font.body(13.5, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Theme.ink)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
    }
}
