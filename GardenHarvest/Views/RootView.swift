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
            // Pre-warm the keyboard while the launch screen covers the UI:
            // the first becomeFirstResponder per app run pays for spinning up
            // the keyboard input session (noticeably slow on first tap of the
            // Entry note field). Paying that cost here, hidden behind
            // LaunchView, makes the first real keyboard open fast.
            prewarmKeyboard()
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.5)) {
                isLaunching = false
            }
        }
    }

    /// Briefly makes an offscreen UITextField first responder so UIKit sets
    /// up the keyboard/input session now instead of on the user's first tap.
    private func prewarmKeyboard() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        guard let window = windows.first(where: \.isKeyWindow) ?? windows.first else { return }

        let field = UITextField(frame: .zero)
        window.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
    }
}
