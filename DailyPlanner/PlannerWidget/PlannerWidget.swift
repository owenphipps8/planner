// PlannerWidget.swift
// PlannerWidget (Widget Extension Target)
//
// A WidgetKit widget that shows the current or upcoming task on the Home Screen.
// Supports small and medium sizes.
//
// SETUP NOTE: This file belongs in the PlannerWidget target, NOT the main app.
// The widget reads tasks from the shared App Group container so it can access the same data.
//
// Replace "group.com.yourname.dailyplanner" with your actual App Group identifier.

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry

/// A snapshot of data that the widget renders at a given point in time.
struct PlannerEntry: TimelineEntry {
    let date: Date
    let currentTask: WidgetTask?
    let upNextTask: WidgetTask?
}

/// A lightweight task struct for the widget (we cannot use SwiftData models directly in widgets)
struct WidgetTask {
    let title: String
    let startTime: Date
    let endTime: Date
    let colorHex: String
    let symbolName: String
    let categoryName: String?
}

// MARK: - Timeline Provider

/// Tells WidgetKit when to refresh the widget and what data to show
struct PlannerTimelineProvider: TimelineProvider {

    // MARK: Placeholder (shown while loading)
    func placeholder(in context: Context) -> PlannerEntry {
        PlannerEntry(
            date: .now,
            currentTask: WidgetTask(
                title: "Team Standup",
                startTime: .now,
                endTime: .now.addingTimeInterval(1800),
                colorHex: "#5E8FFF",
                symbolName: "video.fill",
                categoryName: "Work"
            ),
            upNextTask: nil
        )
    }

    // MARK: Snapshot (shown in widget gallery)
    func getSnapshot(in context: Context, completion: @escaping (PlannerEntry) -> Void) {
        let entry = buildEntry(for: .now)
        completion(entry)
    }

    // MARK: Full Timeline
    func getTimeline(in context: Context, completion: @escaping (Timeline<PlannerEntry>) -> Void) {
        var entries: [PlannerEntry] = []
        let now = Date.now

        // Build an entry for now, and one for each upcoming task start time
        entries.append(buildEntry(for: now))

        let tasks = fetchTasksFromSharedStore()
        let upcoming = tasks
            .filter { $0.startTime > now }
            .sorted { $0.startTime < $1.startTime }
            .prefix(10)

        for task in upcoming {
            entries.append(buildEntry(for: task.startTime))
        }

        // Refresh again in 30 minutes at the latest
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - Data Fetching

    private func fetchTasksFromSharedStore() -> [WidgetTask] {
        // In a real implementation, you would fetch from SwiftData using the shared ModelContainer.
        // For the widget, use UserDefaults(suiteName:) or a shared file to pass data,
        // OR configure a ModelContainer pointing at the shared App Group container:
        //
        // let url = FileManager.default
        //     .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourname.dailyplanner")!
        //     .appendingPathComponent("DailyPlanner.store")
        // let config = ModelConfiguration(url: url)
        // let container = try? ModelContainer(for: PlannerTask.self, configurations: [config])
        //
        // For now, return an empty array as a placeholder.
        return []
    }

    private func buildEntry(for date: Date) -> PlannerEntry {
        let tasks = fetchTasksFromSharedStore()
        let calendar = Calendar.current

        // Current task: one that is happening right now
        let currentTask = tasks.first {
            $0.startTime <= date && $0.endTime > date
        }

        // Up next: the next task that hasn't started yet, on the same day
        let upNextTask = tasks.first {
            $0.startTime > date && calendar.isDate($0.startTime, inSameDayAs: date)
        }

        return PlannerEntry(date: date, currentTask: currentTask, upNextTask: upNextTask)
    }
}

// MARK: - Widget Views

struct PlannerWidgetEntryView: View {
    var entry: PlannerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: Small Widget

struct SmallWidgetView: View {
    let entry: PlannerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let task = entry.currentTask {
                // Currently happening
                Label("Now", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)

                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(task.endTime, style: .timer)
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else if let task = entry.upNextTask {
                // Something coming up
                Label("Up Next", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(task.startTime, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else {
                // Nothing scheduled
                Image(systemName: "sun.max")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("Free time")
                    .font(.headline)
                Text("Nothing scheduled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill, for: .widget)
    }
}

// MARK: Medium Widget

struct MediumWidgetView: View {
    let entry: PlannerEntry

    var body: some View {
        HStack(spacing: 16) {
            // Current task
            VStack(alignment: .leading, spacing: 4) {
                Label("Now", systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)

                if let task = entry.currentTask {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text("Ends \(task.endTime, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Nothing")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Up next
            VStack(alignment: .leading, spacing: 4) {
                Label("Up Next", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let task = entry.upNextTask {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(task.startTime, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("All clear")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill, for: .widget)
    }
}

// MARK: - Widget Configuration

@main
struct PlannerWidget: Widget {
    let kind: String = "PlannerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlannerTimelineProvider()) { entry in
            PlannerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Planner")
        .description("See your current and upcoming tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
