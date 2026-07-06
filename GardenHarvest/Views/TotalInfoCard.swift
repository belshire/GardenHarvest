import SwiftUI

/// Colored total bar shared by the Home and Log views: a big serif weight
/// total over a caption line, with an optional trailing accessory (the Log's
/// crop icon plate).
struct TotalInfoCard<Accessory: View>: View {
    let total: Double
    let caption: String
    let background: Color
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(WeightFormatter.poundsAndOunces(total))
                    .font(Theme.Font.heading(34, weight: .heavy))
                Text(caption)
                    .font(Theme.Font.body(12.5, weight: .semibold))
                    .opacity(0.9)
            }
            Spacer(minLength: 0)
            accessory
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

extension TotalInfoCard where Accessory == EmptyView {
    init(total: Double, caption: String, background: Color) {
        self.init(total: total, caption: caption, background: background) { EmptyView() }
    }
}
