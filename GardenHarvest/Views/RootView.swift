import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isLaunching = true

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
        .overlay {
            if isLaunching {
                LaunchView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.5)) {
                isLaunching = false
            }
        }
    }
}
