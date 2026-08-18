import SwiftUI
import UIKit

/// The Entry and Add screens hide the system navigation bar and draw their own
/// "‹ Back" button, which normally disables UIKit's interactive pop
/// (swipe-back) gesture. Embedding this helper inside the NavigationStack
/// re-attaches the gesture's delegate so swiping from the leading edge still
/// pops pushed screens while the bar is hidden.
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Only when there is something to pop; otherwise the gesture can
            // freeze the navigation controller on the root view.
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

enum HomeRoute: Hashable {
    case entry(cropName: String)
    case add
}

struct HomeContainerView: View {
    @State private var path: [HomeRoute] = []
    @State private var toastMessage: String?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSelectCrop: { name in path.append(.entry(cropName: name)) },
                onToast: showToast
            )
            .background(SwipeBackEnabler())
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .entry(let cropName):
                    EntryView(
                        cropName: cropName,
                        onSaved: { message in
                            if !path.isEmpty { path.removeLast() }
                            showToast(message)
                        },
                        onBack: { if !path.isEmpty { path.removeLast() } },
                        onCropChanged: { result in
                            switch result {
                            case .cancelled:
                                break
                            case .updated(_, let toast):
                                // The route still carries the old name; EntryView
                                // re-points itself so the in-progress entry isn't
                                // torn down, and this screen is popped on Back.
                                showToast(toast)
                            case .deleted(let toast):
                                if !path.isEmpty { path.removeLast() }
                                showToast(toast)
                            }
                        }
                    )
                case .add:
                    AddCropView(
                        onCommitted: { cropName in
                            if !path.isEmpty { path.removeLast() }
                            path.append(.entry(cropName: cropName))
                        },
                        onBack: { if !path.isEmpty { path.removeLast() } }
                    )
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if path.isEmpty {
                AddVegFAB { path.append(.add) }
                    .padding(.trailing, 16)
                    .padding(.bottom, 116)
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 126)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.2), value: toastMessage)
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }
}
