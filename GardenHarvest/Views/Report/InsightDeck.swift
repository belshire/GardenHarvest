import SwiftUI

/// Swipeable deck of season insight cards: crop-tinted backgrounds, the
/// crop's icon plate (sparkle for multi-crop facts), springy scale on page
/// change, and index dots. Replaces the old AIInsightCard placeholder.
struct InsightDeck: View {
    let insights: [Insight]
    /// Resolves a crop's display color, matching the rest of the report.
    let colorHex: (String) -> String

    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            TabView(selection: $page) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    card(insight)
                        .scaleEffect(page == index ? 1 : 0.9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: page)
                        .padding(.horizontal, 2)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 132)
            if insights.count > 1 {
                dots
            }
        }
        .onChange(of: insights.count) { _, _ in page = min(page, max(0, insights.count - 1)) }
    }

    private var header: some View {
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
    }

    private func card(_ insight: Insight) -> some View {
        let tint = insight.cropName.map { Color(hex: colorHex($0)) } ?? Theme.accent
        return HStack(spacing: 14) {
            if let crop = insight.cropName {
                CropIconPlate(
                    cropName: crop,
                    colorHex: colorHex(crop),
                    plateSize: 52,
                    iconSize: 38,
                    discSize: 42
                )
            } else {
                Text("✦")
                    .font(Theme.Font.body(24, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 52, height: 52)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            Text(insight.text)
                .font(Theme.Font.body(14.5, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            ZStack {
                Theme.card
                tint.opacity(0.14)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .animation(.easeInOut(duration: 0.3), value: insight.text)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(insights.indices, id: \.self) { index in
                Circle()
                    .fill(page == index ? Theme.accent : Theme.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
