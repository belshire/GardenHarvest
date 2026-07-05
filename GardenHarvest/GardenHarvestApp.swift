import SwiftUI
import SwiftData

@main
struct GardenHarvestApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: HarvestEntry.self, Crop.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    SeedDataService.seedIfNeeded(
                        context: container.mainContext,
                        currentYear: Calendar.current.component(.year, from: .now)
                    )
                }
        }
        .modelContainer(container)
    }
}
