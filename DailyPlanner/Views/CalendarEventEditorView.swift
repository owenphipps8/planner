// CalendarEventEditorView.swift
// DailyPlanner
//
// Create or edit a CalendarEvent, including inline subtasks.

import SwiftUI
import SwiftData

struct CalendarEventEditorView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Data

    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]

    // MARK: - Form State

    @State private var title: String = ""
    @State private var startTime: Date
    @State private var durationMinutes: Int = 60
    @State private var selectedColor: String = "#5E8FFF"
    @State private var notes: String = ""
    @State private var selectedCategory: TaskCategory? = nil

    // Subtask state — local draft list synced to model on save
    @State private var subtaskDrafts: [SubtaskDraft] = []
    @State private var newSubtaskTitle: String = ""
    @FocusState private var newSubtaskFocused: Bool

    // MARK: - Mode

    private let existingEvent: CalendarEvent?
    private let embedInNavigationStack: Bool

    // MARK: - Inits

    init(startTime: Date, embedInNavigationStack: Bool = true) {
        self.existingEvent = nil
        self.embedInNavigationStack = embedInNavigationStack
        _startTime = State(initialValue: startTime)
    }

    init(existingEvent: CalendarEvent, embedInNavigationStack: Bool = true) {
        self.existingEvent = existingEvent
        self.embedInNavigationStack = embedInNavigationStack
        _title           = State(initialValue: existingEvent.title)
        _startTime       = State(initialValue: existingEvent.startTime)
        _durationMinutes = State(initialValue: existingEvent.durationMinutes)
        _selectedColor   = State(initialValue: existingEvent.colorHex)
        _notes           = State(initialValue: existingEvent.notes)
        _selectedCategory = State(initialValue: existingEvent.category)
        _subtaskDrafts   = State(initialValue:
            existingEvent.subtasks
                .sorted { $0.order < $1.order }
                .map { SubtaskDraft(id: $0.id, title: $0.title, isCompleted: $0.isCompleted) }
        )
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                formContent
                    .background(TodayScreenBackground())
                    #if os(iOS)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    #endif
            }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        Form {
            // Title
            Section {
                TextField("Event title", text: $title)
                    .font(.title3)
                    .fontWeight(.medium)
            }

            // Time
            Section("Time") {
                DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                DurationPickerRow(durationMinutes: $durationMinutes)
                HStack {
                    Text("Ends at").foregroundStyle(.secondary)
                    Spacer()
                    Text(endTime, style: .time).foregroundStyle(.secondary)
                }
            }

            // Subtasks
            Section {
                // Existing drafts
                ForEach($subtaskDrafts) { $draft in
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { draft.isCompleted.toggle() }
                        } label: {
                            Image(systemName: draft.isCompleted ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundStyle(draft.isCompleted ? Color(hex: selectedColor) : Color(hex: "#BBBDC6"))
                        }
                        .buttonStyle(.plain)

                        TextField("Subtask", text: $draft.title)
                            .font(.body)
                            .strikethrough(draft.isCompleted)
                            .foregroundStyle(draft.isCompleted ? .secondary : .primary)

                        Button {
                            withAnimation {
                                subtaskDrafts.removeAll { $0.id == draft.id }
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "#BBBDC6"))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }

                // Add new subtask row
                HStack(spacing: 12) {
                    Image(systemName: "square")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "#BBBDC6"))

                    TextField("Add subtask", text: $newSubtaskTitle)
                        .focused($newSubtaskFocused)
                        .onSubmit { commitNewSubtask() }

                    if !newSubtaskTitle.isEmpty {
                        Button {
                            commitNewSubtask()
                        } label: {
                            Image(systemName: "return")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            } header: {
                Text("Subtasks")
            }

            // Category & Color
            Section("Category & Color") {
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(Optional<TaskCategory>.none)
                    ForEach(categories) { cat in
                        Label(cat.name, systemImage: cat.symbolName)
                            .tag(Optional(cat))
                    }
                }
                ColorSwatchRow(selectedColor: $selectedColor)
            }

            // Notes
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }

            // Delete
            if existingEvent != nil {
                Section {
                    Button(role: .destructive, action: deleteEvent) {
                        Label("Delete Event", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .colorScheme(AppTheme.shared.colorScheme)
        .navigationTitle(existingEvent == nil ? "New Event" : "Edit Event")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: saveEvent)
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Helpers

    private var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    private func commitNewSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            subtaskDrafts.append(SubtaskDraft(title: trimmed))
        }
        newSubtaskTitle = ""
        newSubtaskFocused = true
    }

    // MARK: - Actions

    private func saveEvent() {
        // Commit any in-progress subtask
        commitNewSubtask()

        let calendarManager = CalendarImportManager.shared
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes) * 60)

        let event: CalendarEvent
        if let existing = existingEvent {
            existing.title           = title
            existing.startTime       = startTime
            existing.durationMinutes = durationMinutes
            existing.colorHex        = selectedColor
            existing.notes           = notes
            existing.category        = selectedCategory

            // Push update to EKCalendar if linked
            if let ekId = existing.ekEventIdentifier {
                calendarManager.updateEKEvent(
                    identifier: ekId,
                    title:      title,
                    startTime:  startTime,
                    endTime:    endTime,
                    notes:      notes
                )
            } else {
                // First time editing an unlinked event — create it in EK now
                existing.ekEventIdentifier = calendarManager.createEKEvent(
                    title:     title,
                    startTime: startTime,
                    endTime:   endTime,
                    notes:     notes
                )
            }
            event = existing
        } else {
            let newEvent = CalendarEvent(
                title:           title,
                startTime:       startTime,
                durationMinutes: durationMinutes,
                colorHex:        selectedColor,
                notes:           notes,
                category:        selectedCategory
            )
            // Write to EK calendar and store the identifier
            newEvent.ekEventIdentifier = calendarManager.createEKEvent(
                title:     title,
                startTime: startTime,
                endTime:   endTime,
                notes:     notes
            )
            modelContext.insert(newEvent)
            event = newEvent
        }

        // Sync subtasks: delete removed ones, update existing, insert new
        let existingSubtasks = event.subtasks
        let draftIds = Set(subtaskDrafts.map { $0.id })

        for sub in existingSubtasks where !draftIds.contains(sub.id) {
            modelContext.delete(sub)
        }

        for (index, draft) in subtaskDrafts.enumerated() {
            if let existing = existingSubtasks.first(where: { $0.id == draft.id }) {
                existing.title = draft.title
                existing.isCompleted = draft.isCompleted
                existing.order = index
            } else {
                let sub = CalendarSubtask(title: draft.title, isCompleted: draft.isCompleted, order: index)
                modelContext.insert(sub)
                event.subtasks.append(sub)
            }
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteEvent() {
        guard let event = existingEvent else { return }
        // Remove from EK calendar if linked
        if let ekId = event.ekEventIdentifier {
            CalendarImportManager.shared.deleteEKEvent(identifier: ekId)
        }
        modelContext.delete(event)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Local draft model (not persisted until Save)

private struct SubtaskDraft: Identifiable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
}
