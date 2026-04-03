// PlannerViewModel.swift
// DailyPlanner
//
// Central business-logic layer for DailyPlanner.
//
// Responsibilities:
//   - Expanding recurring tasks into concrete occurrences for a date range
//   - Syncing today's tasks to the Apple Watch via a shared App Group
//   - Computing daily progress statistics
//   - Watch-ready task encoding (via WatchTaskDTO)
//
// Usage:
//   Inject as @State in DailyPlannerApp, then read via @Environment.
//
//   @main struct DailyPlannerApp: App {
//       @State private var viewModel = PlannerViewModel()
//       var body: some Scene {
//           WindowGroup { ContentView() }
//               .environment(viewModel)
//               .modelContainer(sharedModelContainer)
//       }
//   }
//
//   struct MyView: View {
//       @Environment(PlannerViewModel.self) private var viewModel
//   }

import Foundation
import SwiftData
import Observation

@Observable
final class PlannerViewModel {

    // MARK: - Configuration

    /// Replace with your actual App Group identifier in Signing & Capabilities.
    private let watchSuiteName = "group.com.yourname.dailyplanner"

    // MARK: - Watch Sync

    /// Encodes today's scheduled (non-inbox) tasks and writes them to the
    /// shared App Group UserDefaults so the Watch app can read them.
    func syncToWatch(tasks: [PlannerTask]) {
        guard let defaults = UserDefaults(suiteName: watchSuiteName) else { return }

        let calendar = Calendar.current
        let todayTasks = tasks
            .filter { calendar.isDateInToday($0.startTime) && !$0.isInbox }
            .sorted { $0.startTime < $1.startTime }

        let dtos = todayTasks.map { WatchTaskDTO(from: $0) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(dtos) {
            defaults.set(data, forKey: "watchTasks")
            defaults.set(Date.now, forKey: "watchTasksUpdated")
        }
    }

    // MARK: - Recurrence Expansion

    /// Given a task that recurs, returns all the start-time Dates within
    /// the provided closed date range.
    ///
    /// - Parameters:
    ///   - task: A task with a non-nil recurrenceRule.
    ///   - dateRange: The date interval to search.
    /// - Returns: An array of start Dates (never exceeding 400 results).
    func expandedOccurrences(
        for task: PlannerTask,
        in dateRange: ClosedRange<Date>
    ) -> [Date] {
        guard let rule = task.recurrenceRule else { return [] }

        var results: [Date] = []
        var current = task.startTime
        var iterations = 0
        let cap = 400

        while current <= dateRange.upperBound, iterations < cap {
            if current >= dateRange.lowerBound {
                results.append(current)
            }
            guard let next = rule.nextOccurrence(after: current, baseDate: task.startTime) else {
                break
            }
            current = next
            iterations += 1
        }

        return results
    }

    // MARK: - Daily Statistics

    /// Number of completed tasks on the given date.
    func completedCount(tasks: [PlannerTask], for date: Date = .now) -> Int {
        let calendar = Calendar.current
        return tasks.filter {
            !$0.isInbox &&
            $0.isCompleted &&
            calendar.isDate($0.startTime, inSameDayAs: date)
        }.count
    }

    /// Total number of scheduled (non-inbox) tasks on the given date.
    func scheduledCount(tasks: [PlannerTask], for date: Date = .now) -> Int {
        let calendar = Calendar.current
        return tasks.filter {
            !$0.isInbox &&
            calendar.isDate($0.startTime, inSameDayAs: date)
        }.count
    }

    /// Completion ratio (0.0 – 1.0) for the given date.
    func completionRatio(tasks: [PlannerTask], for date: Date = .now) -> Double {
        let total = scheduledCount(tasks: tasks, for: date)
        guard total > 0 else { return 0 }
        return Double(completedCount(tasks: tasks, for: date)) / Double(total)
    }

    // MARK: - Conflict Detection

    /// Returns any tasks in `all` that overlap with the specified time range on the same day.
    func conflicts(
        in all: [PlannerTask],
        startTime: Date,
        durationMinutes: Int,
        excludingTaskID: UUID? = nil
    ) -> [PlannerTask] {
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes) * 60)
        return all.filter { task in
            guard task.id != excludingTaskID, !task.isInbox else { return false }
            return task.startTime < endTime && task.endTime > startTime
        }
    }
}

// MARK: - Watch Task DTO (private encoding helper)

/// A lightweight, Codable representation of a task for Watch / widget data passing.
/// We cannot share SwiftData models directly across app group containers in a lightweight way,
/// so we encode a minimal snapshot instead.
private struct WatchTaskDTO: Codable {
    let id: UUID
    let title: String
    let startTime: Date
    let endTime: Date
    let colorHex: String
    let symbolName: String
    let isCompleted: Bool

    init(from task: PlannerTask) {
        id = task.id
        title = task.title
        startTime = task.startTime
        endTime = task.endTime
        colorHex = task.colorHex
        symbolName = task.symbolName
        isCompleted = task.isCompleted
    }
}
