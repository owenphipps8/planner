// CalendarEventEditorView.swift
// DailyPlanner
//
// Create or edit a CalendarEvent. Designed to be pushed onto a
// NavigationStack (embedInNavigationStack: false) or presented as
// a standalone sheet (embedInNavigationStack: true, the default).

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
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        if embedInNavigationStack {
            NavigationStack { formContent }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        Form {

            Section {
                TextField("Event title", text: $title)
                    .font(.title3)
                    .fontWeight(.medium)
            }

            Section("Time") {
                DatePicker("Start", selection: $startTime, displayedComponents: [.date, .hourAndMinute])

                DurationPickerRow(durationMinutes: $durationMinutes)

                HStack {
                    Text("Ends at")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(endTime, style: .time)
                        .foregroundStyle(.secondary)
                }
            }

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

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }

            if existingEvent != nil {
                Section {
                    Button(role: .destructive, action: deleteEvent) {
                        Label("Delete Event", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(existingEvent == nil ? "New Event" : "Edit Event")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Computed

    private var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    // MARK: - Actions

    private func saveEvent() {
        if let event = existingEvent {
            event.title           = title
            event.startTime       = startTime
            event.durationMinutes = durationMinutes
            event.colorHex        = selectedColor
            event.notes           = notes
            event.category        = selectedCategory
        } else {
            let event = CalendarEvent(
                title:           title,
                startTime:       startTime,
                durationMinutes: durationMinutes,
                colorHex:        selectedColor,
                notes:           notes,
                category:        selectedCategory
            )
            modelContext.insert(event)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteEvent() {
        guard let event = existingEvent else { return }
        modelContext.delete(event)
        try? modelContext.save()
        dismiss()
    }
}
