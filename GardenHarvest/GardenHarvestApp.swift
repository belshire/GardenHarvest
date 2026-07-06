import SwiftUI
import SwiftData

@main
struct GardenHarvestApp: App {
    let container: ModelContainer

    init() {
        DateProvider.applyLaunchArguments()
        do {
            container = try ModelContainer(for: HarvestEntry.self, Crop.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
