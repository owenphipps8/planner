// CalendarEvent.swift
// DailyPlanner
//
// A scheduled calendar event — completely separate from PlannerTask.
// Events appear on the Cal tab and on the Today timeline.

import Foundation
import SwiftData

// MARK: - Calendar Subtask

@Model
final class CalendarSubtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, order: Int = 0) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
    }
}

@Model
final class CalendarEvent {

    // MARK: - Stored Properties

    var id: UUID
    var title: String
    var startTime: Date
    var durationMinutes: Int
    var colorHex: String
    var notes: String

    /// The EKEvent.eventIdentifier for two-way sync. Nil for events created
    /// before two-way sync was added, or if no calendar account is connected.
    var ekEventIdentifier: String?

    @Relationship(deleteRule: .nullify)
    var category: TaskCategory?

    @Relationship(deleteRule: .cascade)
    var subtasks: [CalendarSubtask]

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        durationMinutes: Int = 60,
        colorHex: String = "#5E8FFF",
        notes: String = "",
        ekEventIdentifier: String? = nil,
        category: TaskCategory? = nil,
        subtasks: [CalendarSubtask] = []
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.colorHex = colorHex
        self.notes = notes
        self.ekEventIdentifier = ekEventIdentifier
        self.category = category
        self.subtasks = subtasks
    }

    // MARK: - Computed Properties

    var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    var accentHex: String {
        category?.colorHex ?? colorHex
    }

    var durationLabel: String {
        let hours = durationMinutes / 60
        let mins  = durationMinutes % 60
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0              { return "\(hours)h" }
        return "\(mins)m"
    }
}
