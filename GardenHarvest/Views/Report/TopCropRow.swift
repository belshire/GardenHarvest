import SwiftUI

/// One ranked crop on the Report: icon, name, proportional bar, total, and a
/// chevron that expands an inline timeline of every picking across the season.
struct TopCropRow: View {
    let name: String
    let valueString: String
    /// Filled portion of the bar relative to the top crop, 0...1.
    let fillFraction: Double
    let colorHex: String
    let isExpanded: Bool
    /// Present only while expanded.
    let timeline: ReportStats.CropTimeline?
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    rowIcon
                    Text(name)
                        .font(Theme.Font.body(12.5, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .frame(width: 88, alignment: .leading)
                    CapsuleBar(fraction: fillFraction, fill: Color(hex: colorHex))
                        .frame(height: 12)
                    Text(valueString)
                        .font(Theme.Font.mono(12, weight: .heavy))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 64, alignment: .trailing)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 12)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded, let timeline {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeline.statLine)
                        .font(Theme.Font.mono(11))
                        .foregroundStyle(Theme.sub)
                    PickingTimelineChart(timeline: timeline, color: Color(hex: colorHex))
                        .frame(height: 74)
                }
                .padding(.leading, 32)
                .padding(.trailing, 2)
            }
        }
    }

    /// Vegetable icon when one matches, otherwise a small initials disc so
    /// iconless crops keep the same alignment.
    private var rowIcon: some View {
        Group {
            if let assetName = CropIconAssigner.assetName(for: name) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color(hex: "#22381c").opacity(0.18), radius: 2, y: 1)
            } else {
                Circle()
                    .fill(Color(hex: colorHex))
                    .overlay(
                        Text(name.cropInitials)
                            .font(Theme.Font.mono(9, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: 22, height: 22)
    }
}

/// Mini bar chart of a crop's individual pickings placed along the season's
/// date span, with a hairline axis and month labels underneath.
struct PickingTimelineChart: View {
    let timeline: ReportStats.CropTimeline
    let color: Color

    private let axisHeight: CGFloat = 19
    private let maxBarHeight: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let axisY = geo.size.height - axisHeight
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: width, height: 1)
                    .offset(y: axisY)
                ForEach(Array(timeline.points.enumerated()), id: \.offset) { _, point in
                    let height = max(4, point.heightFraction * maxBarHeight)
                    UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3)
                        .fill(color.opacity(0.92))
                        .frame(width: 6, height: height)
                        .offset(x: width * point.x - 3, y: axisY - height)
                }
                ForEach(Array(timeline.ticks.enumerated()), id: \.offset) { _, tick in
                    Text(tick.label)
                        .font(Theme.Font.mono(9))
                        .foregroundStyle(Theme.sub)
                        .fixedSize()
                        .frame(width: 40)
                        .offset(x: width * tick.x - 20, y: geo.size.height - 12)
                }
            }
        }
    }
}
