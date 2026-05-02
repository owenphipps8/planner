// CalendarViews.swift
// DailyPlanner
//
// Single-month calendar. Tap a day to reveal the daily summary inline below the grid.

import SwiftUI
import SwiftData

struct MonthCalendarView: View {

    // MARK: - Data

    @Query(sort: \CalendarEvent.startTime) private var allEvents: [CalendarEvent]
    @Query(sort: \PlannerTask.startTime)   private var allTasks:  [PlannerTask]

    // MARK: - State

    @State private var currentMonth  = Date()
    @State private var selectedDay:  Date? = nil
    @State private var showYearPicker = false
    @State private var isAddingEvent  = false
    @State private var editingEvent: CalendarEvent? = nil

    private let cal = Calendar.current
    private let weekLetters = ["S","M","T","W","T","F","S"]
    private let theme = AppTheme.shared

    // Tall cells when no day selected, compact when summary is showing
    private var cellHeight: CGFloat { selectedDay == nil ? 96 : 52 }

    // Approximate fixed heights for spacer math
    private let headerHeight: CGFloat    = 80
    private let weekdayRowHeight: CGFloat = 30

    // MARK: - Derived

    private var currentYear: Int { cal.component(.year, from: currentMonth) }

    private var daysGrid: [Date?] {
        let comps = cal.dateComponents([.year, .month], from: currentMonth)
        guard let start = cal.date(from: comps) else { return [] }
        var endComps = DateComponents(); endComps.month = 1; endComps.day = -1
        let end = cal.date(byAdding: endComps, to: start)!
        var days: [Date?] = []
        let firstWeekday = cal.component(.weekday, from: start)
        for _ in 0..<(firstWeekday - 1) { days.append(nil) }
        var cur = start
        while true {
            days.append(cur)
            if cal.isDate(cur, inSameDayAs: end) { break }
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }
        return days
    }

    private var rowCount: Int { max(Int(ceil(Double(daysGrid.count) / 7.0)), 1) }

    private func events(for date: Date) -> [CalendarEvent] {
        allEvents.filter { cal.isDate($0.startTime, inSameDayAs: date) }
    }
    private func tasks(for date: Date) -> [PlannerTask] {
        allTasks.filter { !$0.isInbox && cal.isDate($0.startTime, inSameDayAs: date) }
    }

    private var yearOptions: [Int] { Array((currentYear - 5)...(currentYear + 10)) }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    weekdayRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                    calendarGrid
                        .padding(.horizontal, 16)

                    if let day = selectedDay {
                        DailyInlineSummary(
                            date: day,
                            events: events(for: day),
                            tasks: tasks(for: day),
                            onAddEvent: { isAddingEvent = true },
                            editingEvent: $editingEvent
                        )
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }

                    // When no day selected, push calendar to fill available height
                    if selectedDay == nil {
                        Spacer(minLength: 0)
                            .frame(height: max(0, geo.size.height
                                - headerHeight
                                - weekdayRowHeight
                                - CGFloat(rowCount) * cellHeight
                                - 30))
                    } else {
                        Spacer(minLength: 24)
                    }
                }
                .frame(minHeight: geo.size.height, alignment: .top)
            }
            .scrollDisabled(selectedDay == nil)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: selectedDay)
        .sheet(isPresented: $isAddingEvent) {
            CalendarEventEditorView(startTime: defaultEventStart(for: selectedDay ?? Date()))
        }
        .sheet(item: $editingEvent) { event in
            CalendarEventEditorView(existingEvent: event)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth)!
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#5D6785"))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.85)))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(currentMonth.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(theme.isDarkMode ? Color.white : Color(hex: "#1C2B3A"))

                Button {
                    showYearPicker = true
                } label: {
                    HStack(spacing: 3) {
                        Text(String(currentYear))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.isDarkMode ? Color.white.opacity(0.7) : Color(hex: "#5D6785"))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.isDarkMode ? Color.white.opacity(0.7) : Color(hex: "#5D6785"))
                    }
                }
                .buttonStyle(.plain)
                .confirmationDialog("Select Year", isPresented: $showYearPicker, titleVisibility: .visible) {
                    ForEach(yearOptions, id: \.self) { yr in
                        Button(String(yr)) {
                            if let d = cal.date(bySetting: .year, value: yr, of: currentMonth) {
                                currentMonth = d
                                selectedDay = nil
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            Spacer()

            Button {
                currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth)!
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#5D6785"))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.85)))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }
            .buttonStyle(.plain)

            Button {
                isAddingEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(theme.buttonGradient))
                    .shadow(color: theme.buttonShadowColor, radius: 10, y: 5)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekday Row

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekLetters, id: \.self) { d in
                Text(d)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.isDarkMode ? Color.white.opacity(0.5) : Color(hex: "#8A93AA"))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        GeometryReader { geo in
            let colW = geo.size.width / 7
            let isExpanded = selectedDay == nil
            let circleSize: CGFloat = isExpanded ? 40 : 30
            let fontSize: CGFloat   = isExpanded ? 18 : 13
            let dotSize: CGFloat    = isExpanded ? 6  : 4

            ZStack(alignment: .topLeading) {
                // Grid border lines drawn as a single background
                gridLines(colW: colW)

                VStack(spacing: 0) {
                    ForEach(0..<rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { col in
                                let idx = row * 7 + col
                                if idx < daysGrid.count, let date = daysGrid[idx] {
                                    let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: date) } ?? false
                                    let isToday    = cal.isDateInToday(date)
                                    let dayNum     = cal.component(.day, from: date)
                                    let evts       = events(for: date)
                                    let tsks       = tasks(for: date)
                                    let holiday    = HolidayProvider.holiday(for: date)

                                    VStack(spacing: isExpanded ? 4 : 2) {
                                        Text("\(dayNum)")
                                            .font(.system(size: fontSize, weight: isToday || isSelected ? .bold : .medium))
                                            .foregroundStyle(
                                                isSelected ? .white :
                                                isToday    ? theme.primaryColor :
                                                theme.isDarkMode ? Color.white.opacity(0.85) :
                                                             Color(hex: "#1C2B3A")
                                            )
                                            .frame(width: circleSize, height: circleSize)
                                            .background {
                                                if isSelected {
                                                    Circle().fill(theme.buttonGradient)
                                                        .shadow(color: theme.buttonShadowColor, radius: 6, y: 3)
                                                } else if isToday {
                                                    Circle().fill(theme.primaryColor.opacity(0.14))
                                                }
                                            }

                                        // Holiday icon
                                        if isExpanded, let h = holiday {
                                            Image(systemName: h.symbol)
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(isSelected ? .white : h.color)
                                        }

                                        HStack(spacing: 3) {
                                            ForEach(evts.prefix(3), id: \.id) { ev in
                                                Circle().fill(Color(hex: ev.accentHex))
                                                    .frame(width: dotSize, height: dotSize)
                                            }
                                            ForEach(tsks.prefix(max(0, 3 - evts.count)), id: \.id) { t in
                                                Circle().fill(Color(hex: t.colorHex))
                                                    .frame(width: dotSize, height: dotSize)
                                            }
                                        }
                                        .frame(height: dotSize + 2)
                                    }
                                    .frame(width: colW, height: cellHeight)
                                    .background(
                                        isSelected ? theme.primaryColor.opacity(0.06) :
                                        isToday    ? theme.primaryColor.opacity(0.06) :
                                                     Color.clear
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                            selectedDay = isSelected ? nil : date
                                        }
                                    }
                                } else {
                                    Color.clear.frame(width: colW, height: cellHeight)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: CGFloat(rowCount) * cellHeight)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: cellHeight)
    }

    private func defaultEventStart(for date: Date) -> Date {
        var c = cal.dateComponents([.year, .month, .day], from: date)
        c.hour = 9; c.minute = 0
        return cal.date(from: c) ?? date
    }

    @ViewBuilder
    private func gridLines(colW: CGFloat) -> some View {
        let lineColor = Color(hex: "#C8CEDE").opacity(0.55)
        let totalW    = colW * 7
        let totalH    = CGFloat(rowCount) * cellHeight

        Canvas { ctx, size in
            // Horizontal lines (row dividers)
            for row in 0...rowCount {
                let y = CGFloat(row) * cellHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: totalW, y: y))
                ctx.stroke(path, with: .color(lineColor), lineWidth: 0.75)
            }
            // Vertical lines (column dividers)
            for col in 0...7 {
                let x = CGFloat(col) * colW
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: totalH))
                ctx.stroke(path, with: .color(lineColor), lineWidth: 0.75)
            }
        }
        .frame(width: totalW, height: totalH)
    }
}

// MARK: - Inline Daily Summary

private struct DailyInlineSummary: View {
    let date: Date
    let events: [CalendarEvent]
    let tasks: [PlannerTask]
    let onAddEvent: () -> Void
    @Binding var editingEvent: CalendarEvent?

    @Environment(\.modelContext) private var modelContext
    private let theme = AppTheme.shared

    private var holiday: Holiday? { HolidayProvider.holiday(for: date) }
    private var hasItems: Bool { !events.isEmpty || !tasks.isEmpty || holiday != nil }

    private var dayNum: String { "\(Calendar.current.component(.day, from: date))" }
    private var dayName: String { date.formatted(.dateTime.weekday(.wide)) }

    // Merge tasks and events sorted by time
    private var sortedItems: [(isEvent: Bool, eventId: UUID?, taskId: UUID?)] {
        var items: [(time: Date, isEvent: Bool, eventId: UUID?, taskId: UUID?)] = []
        for e in events { items.append((e.startTime, true, e.id, nil)) }
        for t in tasks  { items.append((t.startTime, false, nil, t.id)) }
        return items.sorted { $0.time < $1.time }.map { ($0.isEvent, $0.eventId, $0.taskId) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day badge row
            HStack(alignment: .center, spacing: 16) {
                // Numbered circle
                ZStack {
                    Circle()
                        .fill(theme.buttonGradient)
                        .frame(width: 48, height: 48)
                        .shadow(color: theme.buttonShadowColor, radius: 10, y: 5)
                    Text(dayNum)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(dayName)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color(hex: "#1C2B3A"))

                Spacer()

                Button(action: onAddEvent) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(theme.buttonGradient))
                        .shadow(color: theme.buttonShadowColor, radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 14)

            if !hasItems {
                HStack(spacing: 10) {
                    // Dashed line
                    Rectangle()
                        .fill(Color(hex: "#DADCE8"))
                        .frame(width: 1.5)
                        .padding(.leading, 23)

                    Text("Nothing scheduled")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#9AA0B0"))
                        .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Timeline line + items
                HStack(alignment: .top, spacing: 0) {
                    // Vertical dashed line
                    Rectangle()
                        .fill(Color(hex: "#DADCE8"))
                        .frame(width: 1.5)
                        .padding(.leading, 23)

                    VStack(alignment: .leading, spacing: 0) {
                        // Holiday row at the top if applicable
                        if let h = holiday {
                            HolidayRow(holiday: h)
                        }

                        ForEach(Array(sortedItems.enumerated()), id: \.offset) { _, item in
                            if item.isEvent, let eid = item.eventId,
                               let event = events.first(where: { $0.id == eid }) {
                                SummaryEventRow(event: event)
                                    .onTapGesture { editingEvent = event }
                            } else if let tid = item.taskId,
                                      let task = tasks.first(where: { $0.id == tid }) {
                                SummaryTaskRow(task: task)
                            }
                        }
                    }
                    .padding(.leading, 16)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, y: 6)
        )
    }
}

// MARK: - Holiday Row

private struct HolidayRow: View {
    let holiday: Holiday

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(holiday.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: holiday.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(holiday.color)
            }
            .padding(.leading, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(holiday.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(holiday.color)
                Text("Public Holiday")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#9AA0B0"))
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.4)
        }
    }
}

// MARK: - Summary Task Row

private struct SummaryTaskRow: View {
    @Environment(\.modelContext) private var modelContext
    let task: PlannerTask

    private var color: Color { Color(hex: task.colorHex) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { task.isCompleted.toggle(); try? modelContext.save() }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isCompleted ? color : Color(hex: "#BBBDC6"))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color(hex: "#ABAFC0") : Color(hex: "#1C2B3A"))

                if !task.isInbox {
                    Text(task.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#9AA0B0"))
                }
            }

            Spacer(minLength: 0)

            if let cat = task.category {
                Text(cat.symbolName)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.4)
        }
    }
}

// MARK: - Summary Event Row

private struct SummaryEventRow: View {
    @Environment(\.modelContext) private var modelContext
    let event: CalendarEvent

    private var color: Color { Color(hex: event.accentHex) }
    private var sortedSubtasks: [CalendarSubtask] {
        event.subtasks.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event title row
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .padding(.leading, 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C2B3A"))

                    Text("\(event.startTime.formatted(date: .omitted, time: .shortened)) - \(event.endTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#9AA0B0"))
                }

                Spacer(minLength: 0)

                if let cat = event.category {
                    Image(systemName: cat.symbolName)
                        .font(.system(size: 13))
                        .foregroundStyle(color)
                }
            }
            .padding(.vertical, 10)

            // Subtasks (if any)
            if !sortedSubtasks.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sortedSubtasks) { sub in
                        HStack(spacing: 10) {
                            Button {
                                withAnimation {
                                    sub.isCompleted.toggle()
                                    try? modelContext.save()
                                }
                            } label: {
                                Image(systemName: sub.isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 16))
                                    .foregroundStyle(sub.isCompleted ? color : Color(hex: "#BBBDC6"))
                            }
                            .buttonStyle(.plain)

                            Text(sub.title)
                                .font(.system(size: 13))
                                .strikethrough(sub.isCompleted)
                                .foregroundStyle(sub.isCompleted ? Color(hex: "#ABAFC0") : Color(hex: "#3A4560"))

                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 29)
                        .padding(.vertical, 5)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .overlay(alignment: .bottom) {
            Divider().opacity(0.4)
        }
    }
}

// MARK: - Holiday Provider

struct Holiday {
    let name: String
    let symbol: String   // SF Symbol name
    let color: Color
}

struct HolidayProvider {
    private static let cal = Calendar(identifier: .gregorian)

    /// Returns the holiday for `date`, or nil if there isn't one.
    static func holiday(for date: Date) -> Holiday? {
        let comps = cal.dateComponents([.year, .month, .day, .weekday, .weekdayOrdinal], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return nil }

        switch (m, d) {
        case (1, 1):  return Holiday(name: "New Year's Day",    symbol: "sparkles",          color: .purple)
        case (6, 19): return Holiday(name: "Juneteenth",        symbol: "star.fill",          color: Color(hex: "#E58E1D"))
        case (7, 4):  return Holiday(name: "Independence Day",  symbol: "flag.fill",          color: .red)
        case (11, 11):return Holiday(name: "Veterans Day",      symbol: "medal.fill",         color: Color(hex: "#5E8FFF"))
        case (12, 25):return Holiday(name: "Christmas Day",     symbol: "gift.fill",          color: .red)
        case (12, 26):return Holiday(name: "Kwanzaa Begins",    symbol: "flame.fill",         color: Color(hex: "#E58E1D"))
        case (12, 31):return Holiday(name: "New Year's Eve",    symbol: "party.popper.fill",  color: .purple)
        default: break
        }

        // Floating holidays — need weekday math
        let wd  = comps.weekday ?? 0           // 1=Sun … 7=Sat
        let ord = comps.weekdayOrdinal ?? 0    // 1st, 2nd, … occurrence in month

        switch m {
        case 1 where wd == 2 && ord == 3:     // 3rd Monday Jan → MLK Day
            return Holiday(name: "MLK Day", symbol: "person.fill", color: Color(hex: "#51CF66"))
        case 2 where wd == 2 && ord == 3:     // 3rd Monday Feb → Presidents Day
            return Holiday(name: "Presidents' Day", symbol: "building.columns.fill", color: Color(hex: "#5E8FFF"))
        case 5 where wd == 2:                 // Last Monday May → Memorial Day
            // Check if it is the last Monday
            if isLastWeekdayOfMonth(date: date, weekday: 2) {
                return Holiday(name: "Memorial Day", symbol: "star.and.crescent.fill", color: Color(hex: "#5E8FFF"))
            }
        case 9 where wd == 2 && ord == 1:     // 1st Monday Sep → Labor Day
            return Holiday(name: "Labor Day", symbol: "wrench.and.screwdriver.fill", color: Color(hex: "#51CF66"))
        case 10 where wd == 2 && ord == 2:    // 2nd Monday Oct → Columbus Day
            return Holiday(name: "Columbus Day", symbol: "globe.americas.fill", color: Color(hex: "#5E8FFF"))
        case 11 where wd == 5 && ord == 4:    // 4th Thursday Nov → Thanksgiving
            return Holiday(name: "Thanksgiving", symbol: "leaf.fill", color: Color(hex: "#E58E1D"))
        default: break
        }

        // Easter (Gregorian algorithm)
        if let easter = easterDate(year: y), cal.isDate(easter, inSameDayAs: date) {
            return Holiday(name: "Easter", symbol: "circle.fill", color: Color(hex: "#FF8CC9"))
        }

        return nil
    }

    private static func isLastWeekdayOfMonth(date: Date, weekday: Int) -> Bool {
        let nextWeek = cal.date(byAdding: .day, value: 7, to: date)!
        return cal.component(.month, from: nextWeek) != cal.component(.month, from: date)
    }

    private static func easterDate(year: Int) -> Date? {
        // Anonymous Gregorian algorithm
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day   = ((h + l - 7 * m + 114) % 31) + 1
        return cal.date(from: DateComponents(year: year, month: month, day: day))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "#A8C9FF"), Color(hex: "#D7E3FF"), Color(hex: "#F5DCEB")],
            startPoint: .bottomLeading, endPoint: .topTrailing
        ).ignoresSafeArea()
        MonthCalendarView()
    }
    .modelContainer(for: [PlannerTask.self, TaskCategory.self, CalendarEvent.self], inMemory: true)
}
