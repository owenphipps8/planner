// DayTimelineView.swift
// DailyPlanner
//
// The main timeline view - the heart of the app.
// Shows a vertical, scrollable timeline of the selected day, with task blocks
// overlaid at their scheduled positions.
//
// Layout concept:
//
//   | 06:00 |----------------------------------------------|
//   |       |  [Morning Run - 45m]                         |
//   | 07:00 |----------------------------------------------|
//   |       |                                              |
//   | 08:00 |----------------------------------------------|
//   |       |  [Team Standup - 30m]                        |
//   | 09:00 |----------------------------------------------|
//         ... and so on ...

import SwiftUI
import SwiftData

struct DayTimelineView: View {

    // MARK: - Configuration

    /// Height of one hour on screen (in points). 64pt = 1 hour.
    private let hourHeight: CGFloat = 64

    /// First hour to display (0 = midnight)
    private let startHour: Int = 0

    /// Last hour to display (24 = end of day)
    private let endHour: Int = 24

    /// Width of the left column showing hour labels
    private let rulerWidth: CGFloat = 56

    // MARK: - Inputs

    @Binding var selectedDate: Date

    /// Called when the user taps an empty area of the timeline.
    /// The Date passed in is the approximate time they tapped.
    var onTapEmptySlot: (Date) -> Void

    // MARK: - State

    /// Task currently being edited (shown as a sheet)
    @State private var editingTask: PlannerTask? = nil

    // MARK: - Data

    /// All tasks for the selected day, sorted by start time.
    /// @Query with a dynamic predicate must be rebuilt; we use a computed filter instead.
    @Query(sort: \PlannerTask.startTime) private var allTasks: [PlannerTask]

    private var tasksForSelectedDay: [PlannerTask] {
        let calendar = Calendar.current
        return allTasks.filter {
            !$0.isInbox && calendar.isDate($0.startTime, inSameDayAs: selectedDate)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {

                        // Layer 1: Hour grid lines and labels (background)
                        TimelineRulerView(
                            startHour: startHour,
                            endHour: endHour,
                            hourHeight: hourHeight,
                            rulerWidth: rulerWidth,
                            totalWidth: geometry.size.width
                        )

                        // Layer 2: Task blocks (foreground)
                        ForEach(tasksForSelectedDay) { task in
                            TaskBlockView(task: task, hourHeight: hourHeight)
                                .padding(.leading, rulerWidth + 4)
                                .offset(y: yOffset(for: task))
                                .frame(
                                    width: geometry.size.width - rulerWidth - 8,
                                    height: blockHeight(for: task)
                                )
                                .onTapGesture {
                                    editingTask = task
                                }
                        }

                        // Layer 3: Current time indicator (only for today)
                        if Calendar.current.isDateInToday(selectedDate) {
                            CurrentTimeBar(
                                rulerWidth: rulerWidth,
                                totalWidth: geometry.size.width,
                                yOffset: currentTimeYOffset()
                            )
                            .id("currentTime") // used to scroll to this position
                        }

                        // Layer 4: Invisible tap target over empty areas
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                let tappedTime = time(fromYOffset: location.y)
                                onTapEmptySlot(tappedTime)
                            }
                            .frame(height: totalHeight)
                    }
                    .frame(height: totalHeight)
                }
                .onAppear {
                    // Scroll so the current time (or early morning) is visible
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("currentTime", anchor: .center)
                        }
                    }
                }
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditorView(existingTask: task)
        }
    }

    // MARK: - Layout Calculations

    /// Total height of the scrollable area
    private var totalHeight: CGFloat {
        CGFloat(endHour - startHour) * hourHeight
    }

    /// Y offset (from top) for a task block based on its start time
    private func yOffset(for task: PlannerTask) -> CGFloat {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: task.startTime)
        let secondsIntoDay = task.startTime.timeIntervalSince(startOfDay)
        let hoursIntoDay = secondsIntoDay / 3600
        let offsetHours = hoursIntoDay - Double(startHour)
        return CGFloat(offsetHours) * hourHeight
    }

    /// Height of a task block based on its duration
    private func blockHeight(for task: PlannerTask) -> CGFloat {
        let hours = Double(task.durationMinutes) / 60.0
        // Minimum height so very short tasks are still tappable
        return max(CGFloat(hours) * hourHeight, 28)
    }

    /// Y position of the current time indicator
    private func currentTimeYOffset() -> CGFloat {
        let calendar = Calendar.current
        let now = Date.now
        let startOfDay = calendar.startOfDay(for: now)
        let secondsIntoDay = now.timeIntervalSince(startOfDay)
        let hoursIntoDay = secondsIntoDay / 3600
        let offsetHours = hoursIntoDay - Double(startHour)
        return CGFloat(offsetHours) * hourHeight
    }

    /// Converts a Y coordinate (from a tap gesture) back into a Date
    private func time(fromYOffset y: CGFloat) -> Date {
        let hoursIntoDay = Double(y) / Double(hourHeight) + Double(startHour)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        // Round to nearest 15 minutes
        let totalMinutes = Int(hoursIntoDay * 60)
        let roundedMinutes = (totalMinutes / 15) * 15
        return calendar.date(byAdding: .minute, value: roundedMinutes, to: startOfDay) ?? startOfDay
    }
}

// MARK: - Preview

#Preview {
    DayTimelineView(
        selectedDate: .constant(.now),
        onTapEmptySlot: { _ in }
    )
    .modelContainer(for: [PlannerTask.self, TaskCategory.self], inMemory: true)
}
