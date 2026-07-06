import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isLaunching = true
    @State private var isKeyboardVisible = false

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
                // The keyboard shrinks this ZStack's safe area, which would
                // float the bar on top of the keyboard (ignoresSafeArea on the
                // bar can't escape the already-shrunk parent bounds, and
                // ignoring the keyboard at the ZStack level would break
                // keyboard avoidance for the content). So hide the bar while
                // the keyboard is up instead.
                .opacity(isKeyboardVisible ? 0 : 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { isKeyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { isKeyboardVisible = false }
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
