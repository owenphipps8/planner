// TaskCategory.swift
// DailyPlanner
//
// A named, colored grouping for tasks (e.g. "Work", "Health", "Personal").
// Users can assign a category to any task.

import Foundation
import SwiftData

@Model
final class TaskCategory {

    // MARK: - Stored Properties

    var id: UUID
    var name: String
    var colorHex: String
    var symbolName: String

    /// Tasks that belong to this category.
    /// The inverse relationship is PlannerTask.category.
    @Relationship(deleteRule: .nullify, inverse: \PlannerTask.category)
    var tasks: [PlannerTask]

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#5E8FFF",
        symbolName: String = "folder"
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.tasks = []
    }

    // MARK: - Default Categories

    /// A set of built-in categories to seed for first-time users
    static var defaults: [TaskCategory] {
        [
            TaskCategory(name: "Work",     colorHex: "#5E8FFF", symbolName: "laptopcomputer"),
            TaskCategory(name: "Health",   colorHex: "#4CAF82", symbolName: "heart.fill"),
            TaskCategory(name: "Personal", colorHex: "#FF9F43", symbolName: "person.fill"),
            TaskCategory(name: "Family",   colorHex: "#EE5A85", symbolName: "house.fill"),
            TaskCategory(name: "Learning", colorHex: "#A55EEA", symbolName: "book.fill"),
        ]
    }
}
