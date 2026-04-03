// WatchContentView.swift
// PlannerWatch (watchOS Target)
//
// The main view for the Apple Watch companion app.
// Shows the current task and the next few upcoming tasks.
//
// SETUP NOTE: This file belongs in the PlannerWatch (watchOS) target.
// Data is shared from the iPhone via WatchConnectivity or a shared App Group.
//
// For a beginner-friendly v1, we use UserDefaults (App Group) to pass a JSON summary
// of today's tasks from the iPhone app to the Watch.

import SwiftUI

// MARK: - Watch Task Model

/// A lightweight, Codable task summary for passing to the Watch.
/// We don't use SwiftData models directly on Watch for simplicity.
struct WatchTask: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let startTime: Date
    let endTime: Date
    let colorHex: String
    let symbolName: String
    let isCompleted: Bool

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    var isHappeningNow: Bool {
        let now = Date.now
        return startTime <= now && endTime > now
    }
}

// MARK: - Watch Data Store

/// Reads shared task data from the App Group UserDefaults.
/// The iPhone app writes to this store whenever tasks change.
@Observable
final class WatchDataStore {
    var tasks: [WatchTask] = []
    var lastUpdated: Date? = nil

    private let suiteName = "group.com.yourname.dailyplanner" // replace with your App Group

    init() {
        loadTasks()
    }

    func loadTasks() {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "watchTasks") else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        tasks = (try? decoder.decode([WatchTask].self, from: data)) ?? []
        lastUpdated = defaults.object(forKey: "watchTasksUpdated") as? Date
    }

    var todayTasks: [WatchTask] {
        let calendar = Calendar.current
        return tasks
            .filter { calendar.isDateInToday($0.startTime) }
            .sorted { $0.startTime < $1.startTime }
    }

    var currentTask: WatchTask? {
        todayTasks.first { $0.isHappeningNow }
    }

    var upcomingTasks: [WatchTask] {
        todayTasks.filter { $0.startTime > Date.now && !$0.isHappeningNow }.prefix(3).map { $0 }
    }
}

// MARK: - Main Watch View

struct WatchContentView: View {
    @State private var store = WatchDataStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {

                    // Current task section
                    if let current = store.currentTask {
                        WatchCurrentTaskCard(task: current)
                    } else {
                        WatchFreeTimeCard()
                    }

                    // Upcoming tasks
                    if !store.upcomingTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Up Next")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            ForEach(store.upcomingTasks) { task in
                                WatchUpcomingTaskRow(task: task)
                            }
                        }
                    }

                    // Last updated timestamp
                    if let updated = store.lastUpdated {
                        Text("Updated \(updated, style: .relative) ago")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(Date.now.formatted(.dateTime.weekday(.abbreviated).month().day()))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            store.loadTasks()
        }
    }
}

// MARK: - Current Task Card

struct WatchCurrentTaskCard: View {
    let task: WatchTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: task.symbolName)
                    .foregroundStyle(Color(hex: task.colorHex))
                    .font(.caption)
                Text("NOW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.red)
                Spacer()
                // Countdown to end
                Text(task.endTime, style: .timer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(task.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Progress bar showing how far through the task we are
            WatchProgressBar(task: task)
                .frame(height: 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: task.colorHex).opacity(0.2))
        )
    }
}

// MARK: - Free Time Card

struct WatchFreeTimeCard: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sun.max.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            Text("Free time")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Upcoming Task Row

struct WatchUpcomingTaskRow: View {
    let task: WatchTask

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: task.colorHex))
                .frame(width: 3, height: 36)

            // Task icon
            Image(systemName: task.symbolName)
                .font(.caption)
                .foregroundStyle(Color(hex: task.colorHex))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(task.startTime, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Progress Bar

struct WatchProgressBar: View {
    let task: WatchTask

    private var progress: Double {
        let now = Date.now
        guard task.startTime < task.endTime else { return 0 }
        let total = task.endTime.timeIntervalSince(task.startTime)
        let elapsed = now.timeIntervalSince(task.startTime)
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * progress)
            }
        }
    }
}

// MARK: - Color Hex Extension
// Duplicated here because the Watch target is separate from the main app target.

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Watch App Entry Point

@main
struct PlannerWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
