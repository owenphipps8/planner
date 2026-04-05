// CalendarViews.swift
// DailyPlanner
//
// Month calendar grid. Queries CalendarEvent — completely separate from PlannerTask/Tasks.

import SwiftUI
import SwiftData

struct MonthCalendarView: View {

    // MARK: - Data

    @Query(sort: \CalendarEvent.startTime) private var allEvents: [CalendarEvent]

    // MARK: - State

    @State private var currentMonth  = Date()
    @State private var selectedDay: CalendarDaySelection?
    @State private var isAddingEvent = false
    @State private var newEventStart = Date.now

    // MARK: - Helpers

    private var calendar: Calendar { Calendar.current }

    private var monthRange: (start: Date, end: Date) {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let end   = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        return (start, end)
    }

    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        let range = monthRange

        let weekday = calendar.component(.weekday, from: range.start)
        for _ in 0..<(weekday - 1) { days.append(nil) }

        var current = range.start
        while true {
            days.append(current)
            if calendar.isDate(current, inSameDayAs: range.end) { break }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }

    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        allEvents.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }

    private var defaultEventStart: Date {
        var c = calendar.dateComponents([.year, .month, .day], from: Date.now)
        c.hour = 9; c.minute = 0
        return calendar.date(from: c) ?? Date.now
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let headerH: CGFloat  = 78
            let weekdayH: CGFloat = 26
            let spacingH: CGFloat = 30
            let bottomInset = proxy.safeAreaInsets.bottom
            let rowCount = max(Int(ceil(Double(daysInMonth.count) / 7.0)), 1)
            let availH   = proxy.size.height - headerH - weekdayH - spacingH - bottomInset
            let rowHeight = min(max(availH / CGFloat(rowCount), 70), 120)

            VStack(spacing: 10) {

                // Month navigation header — styled like TodayScreenHeader
                HStack(spacing: 14) {
                    // Capsule month navigator
                    HStack(spacing: 12) {
                        Button {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "#5D6785"))
                        }

                        Button {
                            currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now))!
                        } label: {
                            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: "#2F3851"))
                        }

                        Button {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "#2F3851"))
                        }
                    }
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
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    // Gradient add button — same as Today tab
                    Button {
                        newEventStart = defaultEventStart
                        isAddingEvent = true
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

                // Weekday headers
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: "#5D6785"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                VStack(spacing: 6) {
                    ForEach(0..<rowCount, id: \.self) { week in
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { day in
                                let idx = week * 7 + day
                                if idx < daysInMonth.count, let date = daysInMonth[idx] {
                                    CalendarDayCell(
                                        date: date,
                                        events: eventsForDate(date),
                                        rowHeight: rowHeight
                                    )
                                    .onTapGesture {
                                        selectedDay = CalendarDaySelection(date: date)
                                    }
                                } else {
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                        .frame(height: rowHeight)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $isAddingEvent) {
            CalendarEventEditorView(startTime: newEventStart)
        }
        .sheet(item: $selectedDay) { sel in
            CalendarDayDetailSheet(date: sel.date)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let rowHeight: CGFloat

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(isToday ? Color(hex: "#3A7BD5") : Color(hex: "#1C2B3A"))

            HStack(spacing: 2) {
                ForEach(events.prefix(3), id: \.id) { event in
                    Image(systemName: event.category?.symbolName ?? "calendar")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(hex: event.accentHex))
                }

                if events.count > 3 {
                    Text("+\(events.count - 3)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isToday ? Color(hex: "#3A7BD5").opacity(0.12) : Color.white.opacity(0.70))
        )
        .frame(height: rowHeight)
    }
}

// MARK: - Day selection wrapper

private struct CalendarDaySelection: Identifiable {
    let date: Date
    var id: Date { Calendar.current.startOfDay(for: date) }
}

// MARK: - Day Detail Sheet

private struct CalendarDayDetailSheet: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startTime) private var allEvents: [CalendarEvent]

    @State private var isAddingEvent = false
    @State private var editingEvent: CalendarEvent?

    private var dayEvents: [CalendarEvent] {
        allEvents.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dayEvents.isEmpty {
                    ContentUnavailableView {
                        Label("No events", systemImage: "calendar")
                    } description: {
                        Text("Tap + to add an event for this day.")
                    }
                } else {
                    List {
                        ForEach(dayEvents) { event in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: event.accentHex))
                                    .frame(width: 4, height: 44)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    HStack(spacing: 4) {
                                        Text(event.startTime.formatted(date: .omitted, time: .shortened))
                                        Text("·")
                                        Text(event.durationLabel)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let cat = event.category {
                                    Image(systemName: cat.symbolName)
                                        .foregroundStyle(Color(hex: event.accentHex))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editingEvent = event }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(event)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(.dateTime.month().day().year()))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isAddingEvent = true } label: {
                        Label("New Event", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $isAddingEvent) {
                CalendarEventEditorView(startTime: defaultStart, embedInNavigationStack: false)
            }
            .navigationDestination(item: $editingEvent) { event in
                CalendarEventEditorView(existingEvent: event, embedInNavigationStack: false)
            }
        }
    }

    private var defaultStart: Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        c.hour = 9; c.minute = 0
        return Calendar.current.date(from: c) ?? date
    }
}

// MARK: - Preview

#Preview {
    MonthCalendarView()
        .modelContainer(for: [PlannerTask.self, TaskCategory.self, CalendarEvent.self], inMemory: true)
}
