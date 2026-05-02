// DayTimelineView.swift
// DailyPlanner

import SwiftUI
import SwiftData

enum TimelinePresentationStyle {
    case classic
    case iosCards
}

struct DayTimelineView: View {

    @Binding var selectedDate: Date
    var style: TimelinePresentationStyle = .classic
    var onTapEmptySlot: (Date) -> Void

    @State private var editingTask:   PlannerTask?    = nil
    @State private var editingEvent:  CalendarEvent?  = nil
    @State private var detailItem:    TimelineItem?   = nil

    private var hourHeight: CGFloat { style == .classic ? 64 : 48 }
    private var startHour: Int { 0 }
    private var endHour: Int   { 24 }
    private var rulerWidth: CGFloat { style == .classic ? 56 : 0 }

    private func safeTaskBlockWidth(from w: CGFloat) -> CGFloat {
        max(w - rulerWidth - 8, 0)
    }

    @Query(sort: \PlannerTask.startTime)    private var allTasks:  [PlannerTask]
    @Query(sort: \CalendarEvent.startTime) private var allEvents: [CalendarEvent]

    private var tasksForSelectedDay: [PlannerTask] {
        let cal = Calendar.current
        return allTasks.filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    private var eventsForSelectedDay: [CalendarEvent] {
        let cal = Calendar.current
        return allEvents.filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    var body: some View {
        Group {
            switch style {
            case .classic:   classicTimeline
            case .iosCards:  iosCardsTimeline
            }
        }
        .sheet(item: $editingTask)  { TaskEditorView(existingTask: $0) }
        .sheet(item: $editingEvent) { CalendarEventEditorView(existingEvent: $0) }
        .sheet(item: $detailItem) { item in
            EventDetailSheet(
                item: item,
                event: eventsForSelectedDay.first { $0.id == item.id },
                onEdit: {
                    detailItem = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        if item.isEvent {
                            editingEvent = eventsForSelectedDay.first { $0.id == item.id }
                        } else {
                            editingTask = tasksForSelectedDay.first { $0.id == item.id }
                        }
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
    }

    // MARK: - Classic

    private var classicTimeline: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        TimelineRulerView(startHour: startHour, endHour: endHour,
                                          hourHeight: hourHeight, rulerWidth: rulerWidth,
                                          totalWidth: geometry.size.width)

                        ForEach(tasksForSelectedDay) { task in
                            TaskBlockView(task: task, hourHeight: hourHeight)
                                .padding(.leading, rulerWidth + 4)
                                .offset(y: yOffset(for: task))
                                .frame(width: safeTaskBlockWidth(from: geometry.size.width),
                                       height: blockHeight(for: task))
                                .onTapGesture { editingTask = task }
                        }

                        if Calendar.current.isDateInToday(selectedDate) {
                            CurrentTimeBar(rulerWidth: rulerWidth,
                                           totalWidth: geometry.size.width,
                                           yOffset: currentTimeYOffset())
                            .id("currentTime")
                        }

                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { location in
                                onTapEmptySlot(time(fromYOffset: location.y))
                            }
                            .frame(height: totalHeight)
                    }
                    .frame(height: totalHeight)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo("currentTime", anchor: .center) }
                    }
                }
            }
        }
    }

    // MARK: - iOS Cards

    private var iosCardsTimeline: some View {
        GeometryReader { geometry in
            let cardSpacing: CGFloat = 8
            let visibleHours: CGFloat = 11
            let availH = max(geometry.size.height - 8, 0)
            let rowH = min(max((availH - (visibleHours - 1) * cardSpacing) / visibleHours, 38), 54)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: cardSpacing) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            IOSTimelineHourCard(
                                hour: hour,
                                items: timelineItems(for: hour),
                                baseRowHeight: rowH,
                                onTapHour: { onTapEmptySlot(hourDate(for: hour)) },
                                onTapItem: { item in detailItem = item }
                            )
                            .id(hour)
                        }
                    }
                    .padding(.bottom, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .onAppear {
                    let currentHour = Calendar.current.component(.hour, from: Date())
                    // Scroll to 1 hour before current time so current slot is visible near top
                    let targetHour = max(startHour, currentHour - 1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo(targetHour, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var totalHeight: CGFloat { CGFloat(endHour - startHour) * hourHeight }

    private func yOffset(for task: PlannerTask) -> CGFloat {
        let cal = Calendar.current
        let sod = cal.startOfDay(for: task.startTime)
        let hrs = task.startTime.timeIntervalSince(sod) / 3600
        return CGFloat(hrs - Double(startHour)) * hourHeight
    }

    private func blockHeight(for task: PlannerTask) -> CGFloat {
        max(CGFloat(task.durationMinutes) / 60.0 * hourHeight, 28)
    }

    private func currentTimeYOffset() -> CGFloat {
        let cal = Calendar.current
        let now = Date.now
        let sod = cal.startOfDay(for: now)
        let hrs = now.timeIntervalSince(sod) / 3600
        return min(max(CGFloat(hrs - Double(startHour)) * hourHeight, 0), totalHeight)
    }

    private func timelineItems(for hour: Int) -> [TimelineItem] {
        let cal = Calendar.current
        var items: [TimelineItem] = []

        for task in tasksForSelectedDay where cal.component(.hour, from: task.startTime) == hour {
            items.append(TimelineItem(
                id:         task.id,
                title:      task.title,
                accentHex:  task.category?.colorHex ?? task.colorHex,
                symbolName: task.category?.symbolName ?? task.symbolName,
                isEvent:    false,
                subtasks:   [],
                startTime:  task.startTime,
                endTime:    task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes) * 60)
            ))
        }

        for event in eventsForSelectedDay where cal.component(.hour, from: event.startTime) == hour {
            items.append(TimelineItem(
                id:         event.id,
                title:      event.title,
                accentHex:  event.accentHex,
                symbolName: event.category?.symbolName ?? resolvedSymbol(for: event.title),
                isEvent:    true,
                subtasks:   event.subtasks.sorted { $0.order < $1.order },
                startTime:  event.startTime,
                endTime:    event.endTime
            ))
        }

        return items.sorted { $0.startTime < $1.startTime }
    }

    private func hourDate(for hour: Int) -> Date {
        let cal = Calendar.current
        let sod = cal.startOfDay(for: selectedDate)
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: sod) ?? sod
    }

    private func time(fromYOffset y: CGFloat) -> Date {
        let hoursIntoDay = Double(y) / Double(hourHeight) + Double(startHour)
        let cal = Calendar.current
        let sod = cal.startOfDay(for: selectedDate)
        let mins = (Int(hoursIntoDay * 60) / 15) * 15
        return cal.date(byAdding: .minute, value: mins, to: sod) ?? sod
    }
}

// MARK: - Smart icon resolver

private func resolvedSymbol(for title: String) -> String {
    let t = title.lowercased()
    if t.contains("wake") || t.contains("alarm") || t.contains("morning")   { return "sun.horizon.fill" }
    if t.contains("routine") || t.contains("habit")                          { return "arrow.clockwise.heart.fill" }
    if t.contains("meeting") || t.contains("standup") || t.contains("sync") { return "person.2.fill" }
    if t.contains("workout") || t.contains("gym") || t.contains("lift")     { return "figure.strengthtraining.traditional" }
    if t.contains("run") || t.contains("jog")                               { return "figure.run" }
    if t.contains("walk")                                                    { return "figure.walk" }
    if t.contains("yoga") || t.contains("stretch") || t.contains("meditat") { return "figure.mind.and.body" }
    if t.contains("call") || t.contains("phone")                            { return "phone.fill" }
    if t.contains("lunch") || t.contains("dinner") || t.contains("eat")
        || t.contains("breakfast") || t.contains("food")                     { return "fork.knife" }
    if t.contains("focus") || t.contains("deep work") || t.contains("study"){ return "brain.head.profile" }
    if t.contains("read") || t.contains("book")                             { return "book.fill" }
    if t.contains("travel") || t.contains("commut") || t.contains("drive")  { return "car.fill" }
    if t.contains("flight") || t.contains("fly")                            { return "airplane" }
    if t.contains("coffee") || t.contains("tea")                            { return "cup.and.saucer.fill" }
    if t.contains("journal") || t.contains("note") || t.contains("plan")   { return "note.text" }
    if t.contains("music") || t.contains("practice")                        { return "music.note" }
    if t.contains("cook") || t.contains("meal prep")                        { return "frying.pan.fill" }
    if t.contains("clean") || t.contains("chore")                           { return "sparkles" }
    if t.contains("shop") || t.contains("errand")                           { return "bag.fill" }
    if t.contains("doctor") || t.contains("appointment") || t.contains("health") { return "stethoscope" }
    if t.contains("sleep") || t.contains("nap") || t.contains("rest")       { return "moon.fill" }
    return "calendar"
}

// MARK: - TimelineItem

struct TimelineItem: Identifiable {
    let id: UUID
    let title: String
    let accentHex: String
    let symbolName: String
    let isEvent: Bool
    let subtasks: [CalendarSubtask]
    let startTime: Date
    let endTime: Date
}

// MARK: - Hour Card

private struct IOSTimelineHourCard: View {
    let hour: Int
    let items: [TimelineItem]
    let baseRowHeight: CGFloat
    let onTapHour: () -> Void
    let onTapItem: (TimelineItem) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.82), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 5)

            HStack(alignment: .top, spacing: 10) {
                timePill
                    .padding(.top, 10)

                if items.isEmpty {
                    Spacer(minLength: 0)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            TimelineItemRow(item: item, onTap: { onTapItem(item) })
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.trailing, 10)
                }
            }
            .padding(.horizontal, 10)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            if items.isEmpty { onTapHour() }
        }
        .frame(minHeight: baseRowHeight)
    }

    private var timePill: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(hourNumberLabel)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "#5A6783"))
            Text(periodLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "#7B88A2"))
        }
        .frame(width: 58, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private var hourNumberLabel: String {
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h)"
    }
    private var periodLabel: String { hour >= 12 ? "PM" : "AM" }
}

// MARK: - Individual item row

private struct TimelineItemRow: View {
    let item: TimelineItem
    let onTap: () -> Void

    private var accent: Color { Color(hex: item.accentHex) }

    private var timeLabel: String {
        let fmt = Date.FormatStyle().hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits)
        return "\(item.startTime.formatted(fmt)) – \(item.endTime.formatted(fmt))"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1C2B3A"))
                        .lineLimit(1)

                    Text(timeLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#7B88A2"))
                }

                Spacer(minLength: 0)

                if !item.subtasks.isEmpty {
                    let done = item.subtasks.filter { $0.isCompleted }.count
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.square")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(done)/\(item.subtasks.count)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent.opacity(0.12)))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "#C0C8D8"))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        Divider()
            .padding(.leading, 48)
            .opacity(0.4)
    }
}

// MARK: - Event Detail Sheet

struct EventDetailSheet: View {
    let item: TimelineItem
    let event: CalendarEvent?
    let onEdit: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let theme = AppTheme.shared
    private var accent: Color { Color(hex: item.accentHex) }

    private var timeLabel: String {
        let fmt = Date.FormatStyle().hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits)
        return "\(item.startTime.formatted(fmt)) – \(item.endTime.formatted(fmt))"
    }

    private var dateLabel: String {
        item.startTime.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var durationLabel: String {
        let mins = Int(item.endTime.timeIntervalSince(item.startTime) / 60)
        let h = mins / 60; let m = mins % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0           { return "\(h)h" }
        return "\(m)m"
    }

    private var sortedSubtasks: [CalendarSubtask] {
        (event?.subtasks ?? item.subtasks).sorted { $0.order < $1.order }
    }

    var body: some View {
        ZStack {
            TodayScreenBackground()
            VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color(hex: "#D0D5E0"))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.16))
                                .frame(width: 56, height: 56)
                            Image(systemName: item.symbolName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color(hex: "#1C2B3A"))

                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundStyle(accent)
                                Text(timeLabel)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(hex: "#5D6785"))
                                Text("·")
                                    .foregroundStyle(Color(hex: "#9AA0B0"))
                                Text(durationLabel)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "#9AA0B0"))
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "#9AA0B0"))
                                Text(dateLabel)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "#9AA0B0"))
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Notes
                    if let notes = event?.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "#9AA0B0"))
                                .textCase(.uppercase)

                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#3A4560"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }

                    // Subtasks
                    if !sortedSubtasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Subtasks", systemImage: "checklist")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "#9AA0B0"))
                                .textCase(.uppercase)
                                .padding(.horizontal, 24)

                            VStack(spacing: 0) {
                                ForEach(sortedSubtasks) { sub in
                                    HStack(spacing: 12) {
                                        Button {
                                            withAnimation {
                                                sub.isCompleted.toggle()
                                                try? modelContext.save()
                                            }
                                        } label: {
                                            Image(systemName: sub.isCompleted ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 20))
                                                .foregroundStyle(sub.isCompleted ? accent : Color(hex: "#BBBDC6"))
                                        }
                                        .buttonStyle(.plain)

                                        Text(sub.title)
                                            .font(.system(size: 15))
                                            .strikethrough(sub.isCompleted)
                                            .foregroundStyle(sub.isCompleted ? Color(hex: "#ABAFC0") : Color(hex: "#1C2B3A"))

                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)

                                    if sub.id != sortedSubtasks.last?.id {
                                        Divider()
                                            .padding(.leading, 60)
                                            .opacity(0.4)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "#F5F7FB"))
                                    .padding(.horizontal, 16)
                            )
                        }
                        .padding(.bottom, 24)
                    }

                    Spacer(minLength: 40)
                }
            }

            // Edit button
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Edit Event")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(theme.buttonGradientH))
                .shadow(color: theme.buttonShadowColor, radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        } // ZStack
        .colorScheme(AppTheme.shared.colorScheme)
    }
}

// MARK: - TimelineItem: Identifiable for sheet presentation

extension TimelineItem: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Preview

#Preview {
    DayTimelineView(selectedDate: .constant(.now), onTapEmptySlot: { _ in })
        .modelContainer(for: [PlannerTask.self, TaskCategory.self, CalendarEvent.self, CalendarSubtask.self], inMemory: true)
}
