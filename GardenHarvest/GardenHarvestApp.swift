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
            SeedStatusView()
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

/// Temporary launch screen used only to visually confirm seeding worked in the simulator.
/// Replaced by RootView in Task 10.
private struct SeedStatusView: View {
    @Query private var crops: [Crop]
    @Query private var entries: [HarvestEntry]

    var body: some View {
        VStack(spacing: 8) {
            Text("Garden Harvest").font(.title)
            Text("\(crops.count) crops seeded")
            Text("\(entries.count) entries seeded")
        }
    }
}
