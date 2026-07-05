import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: AppTab

    private let items: [(tab: AppTab, label: String, icon: String)] = [
        (.home, "Home", "house.fill"),
        (.log, "Log", "list.bullet"),
        (.unwrapped, "Unwrapped", "sparkles")
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.tab) { item in
                Button {
                    selectedTab = item.tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19))
                        Text(item.label)
                            .font(Theme.Font.body(10, weight: .bold))
                    }
                    .foregroundStyle(selectedTab == item.tab ? Theme.accent : Theme.sub)
                    .frame(maxWidth: .infinity)
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
