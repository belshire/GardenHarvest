import SwiftUI
import SwiftData

/// The app's single ModelContainer, shared so App Intents (which run outside
/// the SwiftUI scene) write to the same store as the UI.
enum AppModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: HarvestEntry.self, Crop.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}

@main
struct GardenHarvestApp: App {
    let container: ModelContainer

    init() {
        DateProvider.applyLaunchArguments()
        container = AppModelContainer.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .task {
                    SeedDataService.seedIfNeeded(
                        context: container.mainContext,
                        currentYear: DateProvider.currentYear
                    )
                }
        }
        .modelContainer(container)
    }
}
