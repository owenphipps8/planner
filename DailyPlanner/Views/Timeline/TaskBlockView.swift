// TaskBlockView.swift
// DailyPlanner
//
// A single task block rendered on the timeline.
// Shows the task's color, icon, title, and duration.
// Adapts its layout based on available height.

import SwiftUI

struct TaskBlockView: View {

    let task: PlannerTask
    let hourHeight: CGFloat

    // MARK: - Computed

    /// Block height in points (caller provides this via .frame modifier, but we need it for layout logic)
    private var blockHeightPoints: CGFloat {
        max(CGFloat(task.durationMinutes) / 60.0 * hourHeight, 28)
    }

    /// Is the block tall enough to show subtitle info?
    private var isTall: Bool { blockHeightPoints >= 52 }
    private var isMedium: Bool { blockHeightPoints >= 36 }

    private var taskColor: Color { Color(hex: task.colorHex) }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {

            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(taskColor)
                .frame(width: 3)

            // Icon
            if isMedium {
                Image(systemName: task.symbolName)
                    .font(.caption)
                    .foregroundStyle(taskColor)
                    .frame(width: 14)
            }

            // Text content
            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(isTall ? .subheadline : .caption)
                    .fontWeight(.medium)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(isTall ? 2 : 1)

                if isTall {
                    Text(timeRangeLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            // Completion checkmark
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(taskColor)
                    .padding(.trailing, 6)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(taskColor.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(taskColor.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Helpers

    /// "9:00 - 9:45 AM" style label
    private var timeRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let start = formatter.string(from: task.startTime)
        let end = formatter.string(from: task.endTime)

        let amPmFormatter = DateFormatter()
        amPmFormatter.dateFormat = "a"
        let amPm = amPmFormatter.string(from: task.endTime)

        return "\(start) - \(end) \(amPm) · \(task.durationLabel)"
    }
}

// MARK: - Preview

#Preview {
    let task = PlannerTask(
        title: "Morning Run",
        startTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now)!,
        durationMinutes: 45,
        colorHex: "#4CAF82",
        symbolName: "figure.run"
    )

    TaskBlockView(task: task, hourHeight: 64)
        .frame(width: 300, height: 48)
        .padding()
}
