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
                    LogView()
                case .unwrapped:
                    ReportView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.panelBackground.ignoresSafeArea())

            BottomTabBar(selectedTab: $selectedTab)
        }
    }
}
