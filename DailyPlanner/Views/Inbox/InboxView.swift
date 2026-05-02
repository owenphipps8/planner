// InboxView.swift
// DailyPlanner
//
// Shows "inbox" tasks — ideas and to-dos captured without a specific time slot.

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

    @State private var activeEditor: InboxEditorSheet?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader

            if inboxTasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .sheet(item: $activeEditor) { editor in
            switch editor {
            case .add:
                TaskEditorView(startTime: .now, isInbox: true)
            case .edit(let task):
                TaskEditorView(existingTask: task)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: 14) {
            Text("Tasks")
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
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#6D66FF"), Color(hex: "#32B4FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                    .shadow(color: Color(hex: "#6784D6").opacity(0.38), radius: 14, y: 8)
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
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#5D6785").opacity(0.5))
            Text("Inbox is empty")
                .font(.headline)
                .foregroundStyle(Color(hex: "#2F3851"))
            Text("Capture ideas and to-dos here\nwithout worrying about scheduling them yet.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "#5D6785"))
                .multilineTextAlignment(.center)
            Button("Add a task") {
                activeEditor = .add
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#6D66FF"), Color(hex: "#32B4FF")],
                        startPoint: .leading, endPoint: .trailing
                    ))
            )
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            let pending = inboxTasks.filter { !$0.isCompleted }
            if !pending.isEmpty {
                Section {
                    ForEach(pending) { task in
                        inboxRow(for: task)
                    }
                } header: {
                    Text("\(pending.count) task\(pending.count == 1 ? "" : "s")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .textCase(nil)
                }
            }

            let completed = inboxTasks.filter { $0.isCompleted }
            if !completed.isEmpty {
                Section {
                    ForEach(completed) { task in
                        inboxRow(for: task)
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
    private func inboxRow(for task: PlannerTask) -> some View {
        InboxTaskRow(task: task, onToggle: { toggleComplete(task) }, onEdit: { activeEditor = .edit(task) })
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
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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

private enum InboxEditorSheet: Identifiable {
    case add
    case edit(PlannerTask)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let task):
            return task.id.uuidString
        }
    }
}

// MARK: - Inbox Task Row

struct InboxTaskRow: View {

    let task: PlannerTask
    let onToggle: () -> Void
    let onEdit: () -> Void

    private var taskColor: Color { Color(hex: task.colorHex) }

    var body: some View {
        HStack(spacing: 12) {

            // Tapping the badge/details area opens editor
            Button(action: onEdit) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(taskColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: task.symbolName)
                            .font(.body)
                            .foregroundStyle(taskColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? Color(hex: "#5D6785") : Color(hex: "#1C2B3A"))
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            if let category = task.category {
                                CategoryBadge(category: category, style: .pill)
                            }
                            if !task.notes.isEmpty {
                                Text(task.notes)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#5D6785"))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            // Tapping the circle toggles completion
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? taskColor : Color(hex: "#5D6785").opacity(0.5))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#A8C9FF"), Color(hex: "#D7E3FF"), Color(hex: "#F5DCEB")],
            startPoint: .bottomLeading, endPoint: .topTrailing
        )
        .ignoresSafeArea()
        InboxView()
    }
    .modelContainer(for: [PlannerTask.self, TaskCategory.self], inMemory: true)
}
