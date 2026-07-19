import SwiftUI

/// Swipeable deck of season fun-fact cards: crop-tinted backgrounds, the
/// crop's icon plate (sparkle for multi-crop facts), springy scale on page
/// change, and index dots. The carousel wraps around: sentinel copies of the
/// first and last cards sit beyond each end, and landing on one snaps
/// without animation to its real twin.
struct InsightDeck: View {
    let insights: [Insight]
    /// Resolves a crop's display color, matching the rest of the report.
    let colorHex: (String) -> String
    let resolveIcon: (String) -> ResolvedCropIcon

    /// Tag into `pages`: real cards are 1...count, 0 and count+1 are the
    /// wraparound sentinels.
    @State private var page = 1

    private var pages: [(tag: Int, insight: Insight)] {
        let real = insights.enumerated().map { (tag: $0.offset + 1, insight: $0.element) }
        guard let first = insights.first, let last = insights.last, insights.count > 1 else {
            return real
        }
        return [(tag: 0, insight: last)] + real + [(tag: insights.count + 1, insight: first)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            TabView(selection: $page) {
                ForEach(pages, id: \.tag) { entry in
                    card(entry.insight)
                        .scaleEffect(page == entry.tag ? 1 : 0.9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: page)
                        .padding(.horizontal, 2)
                        .tag(entry.tag)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 132)
            if insights.count > 1 {
                dots
            }
        }
        .onChange(of: page) { _, newPage in
            guard insights.count > 1 else { return }
            if newPage == 0 {
                snap(to: insights.count)
            } else if newPage == insights.count + 1 {
                snap(to: 1)
            }
        }
        .onChange(of: insights.count) { _, count in page = min(page, max(1, count)) }
    }

    /// Jumps from a sentinel page to its real twin with animations disabled
    /// so the wraparound reads as one continuous swipe.
    private func snap(to tag: Int) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { page = tag }
    }

    /// Dot index for the current page, mapping both sentinels onto the real
    /// cards they mirror.
    private var currentIndex: Int {
        guard !insights.isEmpty else { return 0 }
        return ((page - 1) % insights.count + insights.count) % insights.count
    }

    private var header: some View {
        Text("Fun Facts")
            .font(Theme.Font.body(11, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Theme.sub)
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
                    discSize: 42,
                    resolvedIcon: resolveIcon(crop)
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
                    .fill(currentIndex == index ? Theme.accent : Theme.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
