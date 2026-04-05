// DailyPlannerApp.swift
// DailyPlanner
//
// The entry point for the entire app.
// This is where SwiftData, CloudKit, and cross-cutting services are configured.

import SwiftUI
import SwiftData

@main
struct DailyPlannerApp: App {

    // MARK: - Services

    /// Central business-logic layer, available to all views via @Environment(PlannerViewModel.self)
    @State private var viewModel = PlannerViewModel()

    // MARK: - SwiftData Container

    var sharedModelContainer: ModelContainer = {

        let schema = Schema([
            PlannerTask.self,
            TaskCategory.self,
            CalendarEvent.self,
            PlannerNote.self,
            NoteLabel.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // Uncomment below + add your CloudKit container ID to enable iCloud sync:
            // cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedDefaultCategoriesIfNeeded(container: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - App Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .task {
                    // Request notification permission once, shortly after launch
                    await NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - First Launch Seeding

    private static func seedDefaultCategoriesIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<TaskCategory>()
        let existingCount = (try? context.fetchCount(fetchDescriptor)) ?? 0
        guard existingCount == 0 else { return }
        for category in TaskCategory.defaults {
            context.insert(category)
        }
        try? context.save()
    }
}
