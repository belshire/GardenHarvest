import SwiftUI

struct AddVegFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("＋")
                    .font(Theme.Font.body(21, weight: .bold))
                    .padding(.top, -1)
                Text("Add veg")
                    .font(Theme.Font.body(15.5, weight: .heavy))
                    .tracking(0.2)
            }
            .foregroundStyle(.white)
            .padding(.top, 14)
            .padding(.bottom, 14)
            .padding(.leading, 19)
            .padding(.trailing, 22)
            .background(Theme.accent)
            .clipShape(Capsule())
            .shadow(color: Theme.accent.opacity(0.6), radius: 13, y: 10)
            .shadow(color: Color(hex: "#1e3214").opacity(0.2), radius: 4, y: 3)
        }
        .buttonStyle(.plain)
    }
}
