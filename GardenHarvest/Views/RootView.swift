import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeContainerView()
                case .log:
                    ComingSoonView(title: "Harvest Log")
                case .unwrapped:
                    ComingSoonView(title: "Unwrapped")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panelBackground.ignoresSafeArea())

            BottomTabBar(selectedTab: $selectedTab)
        }
    }
}
