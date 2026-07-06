import SwiftUI

/// "When it peaked": half-month harvest totals as bottom-aligned columns.
/// The biggest bucket is highlighted in the accent color.
struct SeasonTimelineChart: View {
    let buckets: [ReportStats.HalfMonthBucket]

    private let maxBarHeight: CGFloat = 76

    var body: some View {
        let maxTotal = max(buckets.map(\.total).max() ?? 0, 1)
        let peakIndex = buckets.firstIndex { $0.total == maxTotal }
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                VStack(spacing: 5) {
                    Spacer(minLength: 0)
                    UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                        .fill(index == peakIndex ? Theme.accent : Theme.accent2)
                        .frame(height: max(3, bucket.total / maxTotal * maxBarHeight))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 3)
                    Text(bucket.label)
                        .font(Theme.Font.mono(9))
                        .foregroundStyle(Theme.sub)
                        .frame(height: 12)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 2)
    }
}
