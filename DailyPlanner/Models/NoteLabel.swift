// NoteLabel.swift
// DailyPlanner
//
// Represents a label/category for organizing notes.

import Foundation
import SwiftData

@Model
final class NoteLabel: Identifiable {

    // MARK: - Stored Properties

    var id: UUID
    var name: String
    var colorHex: String
    var order: Int

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#FF6B6B",
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
    }
}
