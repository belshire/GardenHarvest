import SwiftUI

/// Placeholder for the upcoming AI insight: dashed card with skeleton lines
/// where the personalized text will eventually go.
struct AIInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 9) {
                Text("✦")
                    .font(Theme.Font.body(14, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 26, height: 26)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("AI Insight")
                    .font(Theme.Font.body(11, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Theme.sub)
            }
            skeletonLine(widthFraction: 0.92)
            skeletonLine(widthFraction: 0.64)
            Text("Personalized insight appears here")
                .font(Theme.Font.mono(11.5))
                .foregroundStyle(Theme.sub.opacity(0.7))
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func skeletonLine(widthFraction: CGFloat) -> some View {
        GeometryReader { geo in
            Capsule()
                .fill(Theme.hairline)
                .frame(width: geo.size.width * widthFraction, height: 9)
        }
        .frame(height: 9)
    }
}
