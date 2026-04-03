// InboxView.swift
// DailyPlanner
//
// Shows "inbox" tasks — ideas and to-dos captured without a specific time slot.
// Users can:
//   • Add quick tasks to the inbox
//   • Tap a task to edit it (and optionally schedule it onto the timeline)
//   • Swipe right to mark complete / incomplete
//   • Swipe left to delete
//
// An inbox task has PlannerTask.isInbox == true.
// Moving it to the timeline means setting isInbox = false and choosing a start time.

import SwiftUI
import SwiftData

struct InboxView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Data

    @Query(
        filter: #Predicate<PlannerTask> { $0.isInbox == true },
        sort: \PlannerTask.startTime,
        order: .forward
    ) private var inboxTasks: [PlannerTask]

    // MARK: - State

    @State private var isAddingTask = false
    @State private var editingTask: PlannerTask? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if inboxTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add inbox task")
                }
            }
            .sheet(isPresented: $isAddingTask) {
                TaskEditorView(startTime: .now, isInbox: true)
            }
            .sheet(item: $editingTask) { task in
                TaskEditorView(existingTask: task)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Inbox is empty", systemImage: "tray")
        } description: {
            Text("Capture ideas and to-dos here\nwithout worrying about scheduling them yet.")
        } actions: {
            Button("Add a task") {
                isAddingTask = true
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            // Pending section
            let pending = inboxTasks.filter { !$0.isCompleted }
            if !pending.isEmpty {
                Section {
                    ForEach(pending) { task in
                        inboxRow(for: task)
                    }
                } header: {
                    Text("\(pending.count) task\(pending.count == 1 ? "" : "s")")
                }
            }

            // Completed section
            let completed = inboxTasks.filter { $0.isCompleted }
            if !completed.isEmpty {
                Section("Completed") {
                    ForEach(completed) { task in
                        inboxRow(for: task)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func inboxRow(for task: PlannerTask) -> some View {
        InboxTaskRow(task: task)
            .contentShape(Rectangle())
            .onTapGesture { editingTask = task }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    toggleComplete(task)
                } label: {
                    Label(
                        task.isCompleted ? "Undo" : "Done",
                        systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                    )
                }
                .tint(task.isCompleted ? .orange : .green)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteTask(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: - Actions

    private func toggleComplete(_ task: PlannerTask) {
        withAnimation {
            task.isCompleted.toggle()
            try? modelContext.save()
        }
    }

    private func deleteTask(_ task: PlannerTask) {
        NotificationManager.shared.removeNotification(for: task)
        modelContext.delete(task)
        try? modelContext.save()
    }
}

// MARK: - Inbox Task Row

struct InboxTaskRow: View {

    let task: PlannerTask

    private var taskColor: Color { Color(hex: task.colorHex) }

    var body: some View {
        HStack(spacing: 12) {

            // Color/icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(taskColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: task.symbolName)
                    .font(.body)
                    .foregroundStyle(taskColor)
            }

            // Task details
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let category = task.category {
                        CategoryBadge(category: category, style: .pill)
                    }

                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            // Completion indicator
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.isCompleted ? taskColor : .tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    InboxView()
        .modelContainer(for: [PlannerTask.self, TaskCategory.self], inMemory: true)
}
