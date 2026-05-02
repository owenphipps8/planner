// TaskEditorView.swift
// DailyPlanner
//
// A sheet/form used to create a new task or edit an existing one.
// Handles both "new" and "edit" modes via the existingTask parameter.

import SwiftUI
import SwiftData

struct TaskEditorView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Query

    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]

    // MARK: - State (form fields)

    @State private var title: String = ""
    @State private var startTime: Date
    @State private var durationMinutes: Int = 30
    @State private var selectedColor: String = "#5E8FFF"
    @State private var selectedSymbol: String = "checkmark.circle"
    @State private var notes: String = ""
    @State private var selectedCategory: TaskCategory? = nil
    @State private var recurrenceRule: RecurrenceRule? = nil
    @State private var notificationsEnabled: Bool = true
    /// True = task lives in Inbox (no scheduled time slot)
    @State private var isInbox: Bool = false

    // MARK: - Mode

    /// When non-nil, we are editing this existing task
    private let existingTask: PlannerTask?
    private let onSave: (() -> Void)?
    /// When false the view omits its own NavigationStack so it can be
    /// pushed onto a parent NavigationStack (e.g. from CalendarDayTasksSheet).
    private let embedInNavigationStack: Bool

    // MARK: - Initializers

    /// Create mode: start with a pre-set time.
    /// Pass `isInbox: true` to create a task that starts in the Inbox (no scheduled slot).
    init(startTime: Date, isInbox: Bool = false, onSave: (() -> Void)? = nil, embedInNavigationStack: Bool = true) {
        self.existingTask = nil
        self.onSave = onSave
        self.embedInNavigationStack = embedInNavigationStack
        _startTime = State(initialValue: startTime)
        _isInbox = State(initialValue: isInbox)
    }

    /// Edit mode: populate fields from the existing task
    init(existingTask: PlannerTask, onSave: (() -> Void)? = nil, embedInNavigationStack: Bool = true) {
        self.existingTask = existingTask
        self.onSave = onSave
        self.embedInNavigationStack = embedInNavigationStack
        _title = State(initialValue: existingTask.title)
        _startTime = State(initialValue: existingTask.startTime)
        _durationMinutes = State(initialValue: existingTask.durationMinutes)
        _selectedColor = State(initialValue: existingTask.colorHex)
        _selectedSymbol = State(initialValue: existingTask.symbolName)
        _notes = State(initialValue: existingTask.notes)
        _selectedCategory = State(initialValue: existingTask.category)
        _recurrenceRule = State(initialValue: existingTask.recurrenceRule)
        _isInbox = State(initialValue: existingTask.isInbox)
    }

    // MARK: - Validation

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

            // MARK: Title + Icon
            Section {
                HStack {
                    Button {
                        // Symbol picker is shown as a popover (see extension below)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: selectedSymbol)
                                .foregroundStyle(Color(hex: selectedColor))
                                .font(.title3)
                        }
                    }

                    TextField("Task name", text: $title)
                        .font(.title3)
                        .fontWeight(.medium)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }

            // MARK: Time & Duration  (hidden for inbox tasks)
            if !isInbox {
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
            }

            // MARK: Inbox / Schedule Toggle
            Section {
                Toggle(isOn: $isInbox) {
                    Label(
                        isInbox ? "In Inbox (unscheduled)" : "Scheduled on Timeline",
                        systemImage: isInbox ? "tray.full" : "calendar.day.timeline.left"
                    )
                }
                .tint(.accentColor)
            }

            // MARK: Recurrence
            if !isInbox {
                Section("Repeat") {
                    RecurrencePickerRow(recurrenceRule: $recurrenceRule)
                }
            }

            // MARK: Category & Color
            Section("Appearance") {
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(Optional<TaskCategory>.none)
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.symbolName)
                            .tag(Optional(category))
                    }
                }

                ColorSwatchRow(selectedColor: $selectedColor)
            }

            // MARK: Notifications  (not relevant for inbox tasks)
            if !isInbox {
                Section("Notifications") {
                    Toggle("Remind me at start", isOn: $notificationsEnabled)
                }
            }

            // MARK: Notes
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }

            // MARK: Delete (edit mode only)
            if existingTask != nil {
                Section {
                    Button(role: .destructive) {
                        deleteTask()
                    } label: {
                        Label("Delete Task", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .colorScheme(AppTheme.shared.colorScheme)
        .navigationTitle(existingTask == nil ? "New Event" : "Edit Event")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveTask() }
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

    private func saveTask() {
        // The task we will schedule a notification for (set below)
        let taskForNotification: PlannerTask

        if let task = existingTask {
            // Update existing task in-place
            task.title = title
            task.startTime = startTime
            task.durationMinutes = durationMinutes
            task.colorHex = selectedColor
            task.symbolName = selectedSymbol
            task.notes = notes
            task.category = selectedCategory
            task.recurrenceRule = recurrenceRule
            task.isInbox = isInbox
            taskForNotification = task
        } else {
            // Create and persist a new task
            let newTask = PlannerTask(
                title: title,
                startTime: startTime,
                durationMinutes: durationMinutes,
                colorHex: selectedColor,
                symbolName: selectedSymbol,
                notes: notes,
                isInbox: isInbox,
                category: selectedCategory
            )
            newTask.recurrenceRule = recurrenceRule
            modelContext.insert(newTask)
            taskForNotification = newTask
        }

        // Schedule (or reschedule) the start-time notification
        if !isInbox && notificationsEnabled {
            NotificationManager.shared.scheduleNotification(for: taskForNotification)
        } else {
            NotificationManager.shared.removeNotification(for: taskForNotification)
        }

        try? modelContext.save()
        onSave?()
        dismiss()
    }

    private func deleteTask() {
        guard let task = existingTask else { return }
        NotificationManager.shared.removeNotification(for: task)
        modelContext.delete(task)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Duration Picker Row

struct DurationPickerRow: View {
    @Binding var durationMinutes: Int

    private let options: [Int] = [5, 10, 15, 20, 25, 30, 45, 60, 75, 90, 105, 120, 150, 180, 240, 300, 360, 480]

    var body: some View {
        Picker("Duration", selection: $durationMinutes) {
            ForEach(options, id: \.self) { minutes in
                Text(label(for: minutes)).tag(minutes)
            }
        }
    }

    private func label(for minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0              { return "\(hours)h" }
        return "\(mins)m"
    }
}

// MARK: - Recurrence Picker Row

struct RecurrencePickerRow: View {
    @Binding var recurrenceRule: RecurrenceRule?
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text("Frequency")
                    .foregroundStyle(.primary)
                Spacer()
                Text(recurrenceRule?.label ?? "Never")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .sheet(isPresented: $showPicker) {
            RecurrencePickerView(recurrenceRule: $recurrenceRule)
        }
    }
}

// MARK: - Color Swatch Row

struct ColorSwatchRow: View {
    @Binding var selectedColor: String

    private let colors: [String] = [
        "#5E8FFF", "#4CAF82", "#FF6B6B", "#FF9F43",
        "#EE5A85", "#A55EEA", "#00B8D9", "#F9CA24",
        "#778CA3", "#2D3436"
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: selectedColor == hex ? 2.5 : 0)
                    )
                    .overlay(
                        Circle().stroke(Color(hex: hex), lineWidth: selectedColor == hex ? 1 : 0)
                            .padding(-1)
                    )
                    .onTapGesture {
                        selectedColor = hex
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TaskEditorView(startTime: .now)
        .modelContainer(for: [PlannerTask.self, TaskCategory.self], inMemory: true)
}
