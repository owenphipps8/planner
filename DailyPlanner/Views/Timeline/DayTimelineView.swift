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

enum TimelinePresentationStyle {
    case classic
    case iosCards
}

struct DayTimelineView: View {

    // MARK: - Configuration

    // MARK: - Inputs

    @Binding var selectedDate: Date
    var style: TimelinePresentationStyle = .classic

    /// Called when the user taps an empty area of the timeline.
    /// The Date passed in is the approximate time they tapped.
    var onTapEmptySlot: (Date) -> Void

    // MARK: - State

    /// Task currently being edited (shown as a sheet)
    @State private var editingTask: PlannerTask? = nil

    private var hourHeight: CGFloat {
        switch style {
        case .classic:
            return 64
        case .iosCards:
            return 48
        }
    }

    private var startHour: Int { 8 }

    private var endHour: Int {
        switch style {
        case .classic:
            return 20
        case .iosCards:
            return 22
        }
    }

    private var rulerWidth: CGFloat {
        switch style {
        case .classic:
            return 56
        case .iosCards:
            return 0
        }
    }

    private func safeTaskBlockWidth(from totalWidth: CGFloat) -> CGFloat {
        let raw = totalWidth - rulerWidth - 8
        return raw.isFinite ? max(raw, 0) : 0
    }

    // MARK: - Data

    @Query(sort: \PlannerTask.startTime)  private var allTasks:  [PlannerTask]
    @Query(sort: \CalendarEvent.startTime) private var allEvents: [CalendarEvent]

    private var tasksForSelectedDay: [PlannerTask] {
        let cal = Calendar.current
        return allTasks.filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    private var eventsForSelectedDay: [CalendarEvent] {
        let cal = Calendar.current
        return allEvents.filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .classic:
                classicTimeline
            case .iosCards:
                iosCardsTimeline
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditorView(existingTask: task)
        }
    }

    private var classicTimeline: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {

                        TimelineRulerView(
                            startHour: startHour,
                            endHour: endHour,
                            hourHeight: hourHeight,
                            rulerWidth: rulerWidth,
                            totalWidth: geometry.size.width
                        )

                        ForEach(tasksForSelectedDay) { task in
                            TaskBlockView(task: task, hourHeight: hourHeight)
                                .padding(.leading, rulerWidth + 4)
                                .offset(y: yOffset(for: task))
                                .frame(
                                    width: safeTaskBlockWidth(from: geometry.size.width),
                                    height: blockHeight(for: task)
                                )
                                .onTapGesture {
                                    editingTask = task
                                }
                        }

                        if Calendar.current.isDateInToday(selectedDate) {
                            CurrentTimeBar(
                                rulerWidth: rulerWidth,
                                totalWidth: geometry.size.width,
                                yOffset: currentTimeYOffset()
                            )
                            .id("currentTime")
                        }

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("currentTime", anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var iosCardsTimeline: some View {
        GeometryReader { geometry in
            let visibleHours: CGFloat = 11
            let cardSpacing: CGFloat = 10
            let availableHeight = max(geometry.size.height - 8, 0)
            let computedHeight = (availableHeight - (visibleHours - 1) * cardSpacing) / visibleHours
            let rowHeight = min(max(computedHeight, 38), 56)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: cardSpacing) {
                    ForEach(startHour..<endHour, id: \.self) { hour in
                        IOSTimelineHourCard(
                            hour: hour,
                            items: timelineItems(for: hour),
                            rowHeight: rowHeight,
                            onTapHour: { onTapEmptySlot(hourDate(for: hour)) }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        let raw = CGFloat(offsetHours) * hourHeight
        return min(max(raw, 0), totalHeight)
    }

    private func timelineItems(for hour: Int) -> [TimelineItem] {
        let cal = Calendar.current
        let tasks = tasksForSelectedDay
            .filter { cal.component(.hour, from: $0.startTime) == hour }
            .map { TimelineItem(id: $0.id, title: $0.title, accentHex: $0.category?.colorHex ?? $0.colorHex, isEvent: false) }
        let events = eventsForSelectedDay
            .filter { cal.component(.hour, from: $0.startTime) == hour }
            .map { TimelineItem(id: $0.id, title: $0.title, accentHex: $0.accentHex, isEvent: true) }
        return (tasks + events).sorted { $0.title < $1.title }
    }

    private func hourDate(for hour: Int) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay) ?? startOfDay
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

// MARK: - Shared timeline item (task or calendar event)

struct TimelineItem: Identifiable {
    let id: UUID
    let title: String
    let accentHex: String
    let isEvent: Bool   // true = calendar event, false = task
}

private struct IOSTimelineHourCard: View {
    let hour: Int
    let items: [TimelineItem]
    let rowHeight: CGFloat
    let onTapHour: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 5)

            HStack(spacing: 12) {
                timePill

                if items.isEmpty {
                    Spacer(minLength: 0)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(items) { item in
                                HStack(spacing: 6) {
                                    Image(systemName: item.isEvent ? "calendar" : "checkmark.circle.fill")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(Color(hex: item.accentHex))

                                    Text(item.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                        .foregroundStyle(Color(hex: "#274A78"))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color(hex: item.accentHex).opacity(0.10))
                                )
                            }
                        }
                        .padding(.trailing, 6)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, max((rowHeight - 34) / 2.2, 5))
        }
        .frame(height: rowHeight)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture(perform: onTapHour)
    }

    private var timePill: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(hourNumberLabel)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#5A6783"))

            Text(periodLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#7B88A2"))
        }
        .frame(width: 62, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "#EEF3FF"))
        )
    }

    private var hourNumberLabel: String {
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h)"
    }

    private var periodLabel: String { hour >= 12 ? "PM" : "AM" }
}

// MARK: - Preview

#Preview {
    DayTimelineView(
        selectedDate: .constant(.now),
        onTapEmptySlot: { _ in }
    )
    .modelContainer(for: [PlannerTask.self, TaskCategory.self, CalendarEvent.self], inMemory: true)
}
