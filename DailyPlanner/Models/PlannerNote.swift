// PlannerNote.swift
// DailyPlanner
//
// Data model for notes created in the Notes tab.
// Supports rich text, labels, and photos.

import Foundation
import SwiftData

@Model
final class PlannerNote {

    // MARK: - Stored Properties

    /// Unique identifier for the note
    var id: UUID

    /// The title or main content of the note
    var content: String

    /// Optional label/category for organizing notes
    var labelName: String

    /// Hex color for the label
    var colorHex: String

    /// When the note was created
    var createdDate: Date

    /// When the note was last modified
    var modifiedDate: Date

    /// Array of image data (stored as base64 or file URLs)
    var imageURLs: [String]

    /// Whether this note is pinned/starred
    var isPinned: Bool

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        content: String = "",
        labelName: String = "Personal",
        colorHex: String = "#FF6B6B",
        createdDate: Date = .now,
        modifiedDate: Date = .now,
        imageURLs: [String] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.content = content
        self.labelName = labelName
        self.colorHex = colorHex
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.imageURLs = imageURLs
        self.isPinned = isPinned
    }
}
