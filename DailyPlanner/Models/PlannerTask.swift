// PlannerTask.swift
// DailyPlanner
//
// The core data model for a single planned task.
// SwiftData will automatically persist this to disk and sync via CloudKit.

import Foundation
import SwiftData

// @Model tells SwiftData to persist this class
@Model
final class PlannerTask {

    // MARK: - Stored Properties

    /// Unique identifier for the task
    var id: UUID

    /// What the user named this task
    var title: String

    /// The exact date and time the task starts
    var startTime: Date

    /// How long the task runs, in minutes (e.g. 30, 60, 90)
    var durationMinutes: Int

    /// A hex color string like "#FF6B6B" used to color the task block
    var colorHex: String

    /// An SF Symbol name like "fork.knife" or "figure.run" shown as the task icon
    var symbolName: String

    /// Optional free-text notes the user can attach to a task
    var notes: String

    /// Whether the user has marked this task done
    var isCompleted: Bool

    /// When true the task lives in the Inbox (no scheduled time slot).
    /// Inbox tasks are hidden from the timeline until the user schedules them.
    var isInbox: Bool

    /// JSON-encoded RecurrenceRule. Nil means the task does not repeat.
    /// We store it as a String because SwiftData does not yet support custom Codable enums natively.
    var recurrenceRuleData: Data?

    /// The category this task belongs to (optional)
    @Relationship(deleteRule: .nullify)
    var category: TaskCategory?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        durationMinutes: Int = 30,
        colorHex: String = "#5E8FFF",
        symbolName: String = "checkmark.circle",
        notes: String = "",
        isCompleted: Bool = false,
        isInbox: Bool = false,
        recurrenceRuleData: Data? = nil,
        category: TaskCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.notes = notes
        self.isCompleted = isCompleted
        self.isInbox = isInbox
        self.recurrenceRuleData = recurrenceRuleData
        self.category = category
    }

    // MARK: - Computed Properties

    /// The time at which this task ends
    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    /// Duration expressed as hours and minutes for display (e.g. "1h 30m")
    var durationLabel: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Decoded recurrence rule, if present
    var recurrenceRule: RecurrenceRule? {
        get {
            guard let data = recurrenceRuleData else { return nil }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            recurrenceRuleData = try? JSONEncoder().encode(newValue)
        }
    }

    /// True if this task overlaps with another task's time range
    func overlaps(with other: PlannerTask) -> Bool {
        startTime < other.endTime && endTime > other.startTime
    }

    /// How far into the day this task starts, expressed as a fraction (0.0 to 1.0)
    /// Used by the timeline to position blocks. 0.0 = midnight, 1.0 = next midnight.
    var dayFraction: Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startTime)
        let secondsIntoDay = startTime.timeIntervalSince(start)
        return secondsIntoDay / (24 * 60 * 60)
    }

    /// Duration expressed as a fraction of a full day
    var durationFraction: Double {
        return Double(durationMinutes) / (24 * 60)
    }
}
