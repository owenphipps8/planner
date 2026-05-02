// RemindersView.swift
// DailyPlanner
//
// View for managing reminders integrated from iOS Reminders app.

import SwiftUI
import SwiftData

struct RemindersView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    private let theme = AppTheme.shared

    // MARK: - State

    @State private var activeEditor: ReminderEditorSheet?

    // MARK: - Data

    @Query(
        filter: #Predicate<PlannerTask> { $0.dueDate != nil },
        sort: \PlannerTask.dueDate
    ) private var reminders: [PlannerTask]

    // MARK: - Computed Properties

    private var upcomingReminders: [PlannerTask] {
        reminders.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= Date() && !task.isCompleted
        }
        .sorted { $0.dueDate ?? .now < $1.dueDate ?? .now }
    }

    private var overdueReminders: [PlannerTask] {
        reminders.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !task.isCompleted
        }
        .sorted { $0.dueDate ?? .now < $1.dueDate ?? .now }
    }

    private var completedReminders: [PlannerTask] {
        reminders.filter { $0.isCompleted }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader

            if reminders.isEmpty {
                emptyState
            } else {
                remindersList
            }
        }
        .sheet(item: $activeEditor) { editor in
            switch editor {
            case .add:
                ReminderEditorView(isPresented: .constant(true))
            case .edit(let reminder):
                ReminderEditorView(existingReminder: reminder)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: 14) {
            Text("Alerts")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#2F3851"))
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.8))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)

            Spacer(minLength: 0)

            Button {
                activeEditor = .add
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(theme.buttonGradient))
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                    .shadow(color: theme.buttonShadowColor, radius: 14, y: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "alarm")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#5D6785").opacity(0.5))
            Text("No reminders")
                .font(.headline)
                .foregroundStyle(Color(hex: "#2F3851"))
            Text("Set reminders for important tasks\nand deadlines.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#5D6785"))
                .multilineTextAlignment(.center)
            Button("Create reminder") {
                activeEditor = .add
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Capsule().fill(theme.buttonGradientH))
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Reminders List

    private var remindersList: some View {
        List {
            if !overdueReminders.isEmpty {
                Section {
                    ForEach(overdueReminders) { reminder in
                        reminderRow(for: reminder)
                    }
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Overdue")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(nil)
                }
            }

            if !upcomingReminders.isEmpty {
                Section {
                    ForEach(upcomingReminders) { reminder in
                        reminderRow(for: reminder)
                    }
                } header: {
                    Text("Upcoming")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .textCase(nil)
                }
            }

            if !completedReminders.isEmpty {
                Section {
                    ForEach(completedReminders) { reminder in
                        reminderRow(for: reminder, dimmed: true)
                    }
                } header: {
                    Text("Completed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func reminderRow(for reminder: PlannerTask, dimmed: Bool = false) -> some View {
        ReminderRow(
            reminder: reminder,
            onToggle: { toggleComplete(reminder) },
            onEdit: { activeEditor = .edit(reminder) }
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 8, y: 3)
        )
        .opacity(dimmed ? 0.6 : 1)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteReminder(reminder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func toggleComplete(_ reminder: PlannerTask) {
        withAnimation {
            reminder.isCompleted.toggle()
            try? modelContext.save()
        }
    }

    private func deleteReminder(_ reminder: PlannerTask) {
        NotificationManager.shared.removeNotification(for: reminder)
        modelContext.delete(reminder)
        try? modelContext.save()
    }
}

private enum ReminderEditorSheet: Identifiable {
    case add
    case edit(PlannerTask)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let reminder):
            return reminder.id.uuidString
        }
    }
}

struct ReminderEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var dueDate: Date = .now
    @State private var notes: String = ""
    @State private var selectedColor = "#FF6B6B"
    @State private var selectedSymbol = "alarm"
    @State private var priority: TaskPriority = TaskPriority.medium

    private let existingReminder: PlannerTask?
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self.existingReminder = nil
        self._isPresented = isPresented
    }

    init(existingReminder: PlannerTask) {
        self.existingReminder = existingReminder
        self._isPresented = .constant(false)
        _title = State(initialValue: existingReminder.title)
        _dueDate = State(initialValue: existingReminder.dueDate ?? existingReminder.startTime)
        _notes = State(initialValue: existingReminder.notes)
        _selectedColor = State(initialValue: existingReminder.colorHex)
        _selectedSymbol = State(initialValue: existingReminder.symbolName)
        _priority = State(initialValue: existingReminder.priority)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Title", text: $title)
                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(TaskPriority.low)
                        Text("Medium").tag(TaskPriority.medium)
                        Text("High").tag(TaskPriority.high)
                    }
                }

                Section("Appearance") {
                    TextField("Symbol", text: $selectedSymbol)
                    ColorSwatchRow(selectedColor: $selectedColor)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                if existingReminder != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteReminder()
                        } label: {
                            Label("Delete Reminder", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .colorScheme(AppTheme.shared.colorScheme)
            .background(TodayScreenBackground())
            .navigationTitle(existingReminder == nil ? "New Reminder" : "Edit Reminder")
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismissEditor() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReminder() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func saveReminder() {
        let reminder: PlannerTask

        if let existingReminder {
            existingReminder.title = title
            existingReminder.notes = notes
            existingReminder.startTime = dueDate
            existingReminder.dueDate = dueDate
            existingReminder.colorHex = selectedColor
            existingReminder.symbolName = selectedSymbol.isEmpty ? "alarm" : selectedSymbol
            existingReminder.priority = priority
            existingReminder.isInbox = false
            reminder = existingReminder
        } else {
            let newReminder = PlannerTask(
                title: title,
                startTime: dueDate,
                durationMinutes: 30,
                colorHex: selectedColor,
                symbolName: selectedSymbol.isEmpty ? "alarm" : selectedSymbol,
                notes: notes,
                isCompleted: false,
                isInbox: false,
                category: nil,
                priority: priority,
                subtasks: [],
                dueDate: dueDate
            )
            modelContext.insert(newReminder)
            reminder = newReminder
        }

        NotificationManager.shared.scheduleNotification(for: reminder)
        try? modelContext.save()
        dismissEditor()
    }

    private func deleteReminder() {
        guard let existingReminder else { return }
        NotificationManager.shared.removeNotification(for: existingReminder)
        modelContext.delete(existingReminder)
        try? modelContext.save()
        dismissEditor()
    }

    private func dismissEditor() {
        if existingReminder == nil {
            isPresented = false
        }
        dismiss()
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {

    let reminder: PlannerTask
    let onToggle: () -> Void
    let onEdit: () -> Void

    private var taskColor: Color { Color(hex: reminder.colorHex) }

    private var dueDateLabel: String {
        guard let dueDate = reminder.dueDate else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) { return "Today" }
        if calendar.isDateInTomorrow(dueDate) { return "Tomorrow" }
        return dueDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private var isOverdue: Bool {
        guard let dueDate = reminder.dueDate else { return false }
        return dueDate < Date() && !reminder.isCompleted
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left side: icon + details — taps open editor
            Button(action: onEdit) {
                HStack(spacing: 12) {
                    Image(systemName: reminder.symbolName)
                        .font(.title3)
                        .foregroundStyle(taskColor)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .strikethrough(reminder.isCompleted)
                            .foregroundStyle(reminder.isCompleted ? Color(hex: "#5D6785") : Color(hex: "#1C2B3A"))

                        HStack(spacing: 8) {
                            if isOverdue {
                                Label("Overdue", systemImage: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            } else {
                                Label(dueDateLabel, systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#5D6785"))
                            }

                            if reminder.priority == TaskPriority.high {
                                Label("High", systemImage: reminder.priority.symbolName)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Circle — taps toggle complete
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? taskColor : Color(hex: "#5D6785").opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#A8C9FF"), Color(hex: "#D7E3FF"), Color(hex: "#F5DCEB")],
            startPoint: .bottomLeading, endPoint: .topTrailing
        )
        .ignoresSafeArea()
        RemindersView()
    }
    .modelContainer(for: [PlannerTask.self, TaskCategory.self], inMemory: true)
}
