import SwiftUI

struct BottomTabBar: View {
    /// Flip to show text labels under the tab icons.
    static let showsLabels = true

    @Binding var selectedTab: AppTab

    private let items: [(tab: AppTab, label: String, icon: String)] = [
        (.home, "Pick", "TabIcons/garden-bed"),
        (.log, "Log", "TabIcons/notebook"),
        (.unwrapped, "Report", "TabIcons/cornucopia")
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.tab) { item in
                let isSelected = selectedTab == item.tab
                Button {
                    selectedTab = item.tab
                } label: {
                    VStack(spacing: 2) {
                        Image(item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 44)
                            .saturation(isSelected ? 1 : 0)
                            .opacity(isSelected ? 1 : 0.6)
                        if Self.showsLabels {
                            Text(item.label)
                                .font(Theme.Font.body(10, weight: .bold))
                                .foregroundStyle(isSelected ? Theme.accent : Theme.sub)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(item.label)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }
}
