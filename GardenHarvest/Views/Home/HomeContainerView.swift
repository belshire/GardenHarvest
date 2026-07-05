import SwiftUI

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
                onAddCrop: { path.append(.add) }
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .entry(let cropName):
                    EntryView(
                        cropName: cropName,
                        onSaved: { message in
                            if !path.isEmpty { path.removeLast() }
                            showToast(message)
                        },
                        onBack: { if !path.isEmpty { path.removeLast() } }
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
        .overlay(alignment: .bottom) {
            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 96)
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
