// ContentView.swift
// DailyPlanner
//
// Root view. Adapts layout by platform:
//   - iPhone:          TabView — Today timeline + Inbox
//   - iPad (regular):  NavigationSplitView with sidebar
//   - macOS:           NavigationSplitView with wider sidebar
//   - watchOS:         Separate PlannerWatch target

import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#endif

struct ContentView: View {

    init() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1.0)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().itemPositioning = .fill
        #endif
    }

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedIPhoneTab: IPhoneTab = .today

    // MARK: - Body

    var body: some View {
        #if os(macOS)
        _MacSplitViewContent()
        #else
        if horizontalSizeClass == .regular {
            _iPadSplitViewContent()
        } else {
            iPhoneLayout
        }
        #endif
    }

    // MARK: - iPhone Layout  (tab bar with all features)

    private var iPhoneLayout: some View {
        ZStack {
            TodayScreenBackground()

            Group {
                switch selectedIPhoneTab {
                case .today:
                    TodayTabView()
                case .calendar:
                    MonthCalendarView()
                case .tasks:
                    InboxView()
                case .alerts:
                    RemindersView()
                case .notes:
                    NotesViewTab()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            IPhoneBottomNav(selectedTab: $selectedIPhoneTab)
        }
    }

}

// MARK: - Today Tab (iPhone)

/// The "Today" tab on iPhone — wraps the timeline inside a NavigationStack
/// with date navigation and a New Task button.
struct TodayTabView: View {

    @State private var selectedDate: Date = .now
    @State private var isAddingTask = false
    @State private var presetStartTime: Date? = nil

    var body: some View {
        ZStack {
            TodayScreenBackground()

            VStack(spacing: 16) {
                TodayScreenHeader(
                    selectedDate: $selectedDate,
                    onTapAdd: {
                        presetStartTime = nil
                        isAddingTask = true
                    }
                )

                DayTimelineView(
                    selectedDate: $selectedDate,
                    style: .iosCards,
                    onTapEmptySlot: { tappedTime in
                        presetStartTime = tappedTime
                        isAddingTask = true
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $isAddingTask) {
            TaskEditorView(startTime: presetStartTime ?? nextRoundedHour())
        }
    }

    private func nextRoundedHour() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let minuteComponent = calendar.component(.minute, from: now)
        let minutesToAdd = minuteComponent == 0 ? 60 : (60 - minuteComponent)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
    }
}

// MARK: - iPad Split View Content

private struct _iPadSplitViewContent: View {

    @State private var selectedDate: Date = .now
    @State private var isAddingTask = false
    @State private var presetStartTime: Date? = nil
    @State private var sidebarSelection: SidebarItem? = .today

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedDate: $selectedDate, selection: $sidebarSelection)
        } detail: {
            switch sidebarSelection {
            case .calendar:
                MonthCalendarView()
            case .inbox:
                InboxView()
            case .reminders:
                RemindersView()
            case .notes:
                NotesViewTab()
            case .settings:
                SettingsView()
            default:
                DayTimelineView(
                    selectedDate: $selectedDate,
                    onTapEmptySlot: { tappedTime in
                        presetStartTime = tappedTime
                        isAddingTask = true
                    }
                )
                .navigationTitle(selectedDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            presetStartTime = nil
                            isAddingTask = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }
                    }
                    #if !os(macOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        DateNavigatorButtons(selectedDate: $selectedDate)
                    }
                    #endif
                }
                .sheet(isPresented: $isAddingTask) {
                    TaskEditorView(startTime: presetStartTime ?? nextRoundedHour())
                }
            }
        }
    }

    private func nextRoundedHour() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let minuteComponent = calendar.component(.minute, from: now)
        let minutesToAdd = minuteComponent == 0 ? 60 : (60 - minuteComponent)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
    }
}

// MARK: - macOS Split View Content

#if os(macOS)
private struct _MacSplitViewContent: View {

    @State private var selectedDate: Date = .now
    @State private var isAddingTask = false
    @State private var presetStartTime: Date? = nil
    @State private var sidebarSelection: SidebarItem? = .today

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedDate: $selectedDate, selection: $sidebarSelection)
                .frame(minWidth: 220)
        } detail: {
            switch sidebarSelection {
            case .calendar:
                MonthCalendarView()
            case .inbox:
                InboxView()
            case .reminders:
                RemindersView()
            case .notes:
                NotesViewTab()
            case .settings:
                SettingsView()
            default:
                DayTimelineView(
                    selectedDate: $selectedDate,
                    onTapEmptySlot: { tappedTime in
                        presetStartTime = tappedTime
                        isAddingTask = true
                    }
                )
                .navigationTitle(selectedDate.formatted(.dateTime.weekday(.wide).month().day().year()))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            presetStartTime = nil
                            isAddingTask = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isAddingTask) {
                    TaskEditorView(startTime: presetStartTime ?? nextRoundedHour())
                        .frame(minWidth: 500, minHeight: 600)
                }
            }
        }
    }

    private func nextRoundedHour() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let minuteComponent = calendar.component(.minute, from: now)
        let minutesToAdd = minuteComponent == 0 ? 60 : (60 - minuteComponent)
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
    }
}
#endif

// MARK: - Sidebar Item

/// Identifies which "section" the sidebar is navigating to.
enum SidebarItem: Hashable {
    case today
    case calendar
    case inbox
    case reminders
    case notes
    case settings
    case category(UUID)
}

enum IPhoneTab: Hashable {
    case today
    case calendar
    case tasks
    case alerts
    case notes
    case settings
}

struct IPhoneBottomNav: View {
    @Binding var selectedTab: IPhoneTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 0) {
                navButton(.today,    title: "Today",    symbol: "calendar.day.timeline.left", color: Color(hex: "#E58E1D"))
                navButton(.calendar, title: "Cal",      symbol: "calendar",                   color: Color(hex: "#C74F46"))
                navButton(.tasks,    title: "Tasks",    symbol: "checkmark.circle",           color: Color(hex: "#2E7D32"))
                navButton(.alerts,   title: "Alerts",   symbol: "alarm",                      color: Color(hex: "#7A56C5"))
                navButton(.notes,    title: "Notes",    symbol: "note.text",                  color: Color(hex: "#2D8E93"))
                navButton(.settings, title: "Settings", symbol: "gear",                       color: Color(hex: "#5D6785"))
            }
            .padding(.horizontal, 2)
            .frame(height: 52)
        }
        .background(Color.white)
        .frame(maxWidth: .infinity, alignment: .bottom)
    }

    @ViewBuilder
    private func navButton(_ tab: IPhoneTab, title: String, symbol: String, color: Color) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == tab ? color : color.opacity(0.9))
            .padding(.vertical, 0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar View

/// The left sidebar shown on iPad and Mac. Shows navigation items and a date picker.
struct SidebarView: View {
    @Binding var selectedDate: Date
    @Binding var selection: SidebarItem?
    @Query private var categories: [TaskCategory]

    var body: some View {
        List(selection: $selection) {
            Section("Schedule") {
                Label("Today", systemImage: "calendar.day.timeline.left")
                    .tag(SidebarItem.today)

                Label("Calendar", systemImage: "calendar")
                    .tag(SidebarItem.calendar)

                Label("Tasks", systemImage: "checkmark.circle")
                    .tag(SidebarItem.inbox)

                Label("Reminders", systemImage: "alarm")
                    .tag(SidebarItem.reminders)
            }

            Section("Content") {
                Label("Notes", systemImage: "note.text")
                    .tag(SidebarItem.notes)
            }

            Section("Date") {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            }

            if !categories.isEmpty {
                Section("Categories") {
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.symbolName)
                            .foregroundStyle(Color(hex: category.colorHex))
                            .tag(SidebarItem.category(category.id))
                    }
                }
            }

            Section("App") {
                Label("Settings", systemImage: "gear")
                    .tag(SidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Plotted")
    }
}

// MARK: - Date Navigator Buttons

/// Back/forward arrows + "Today" button for quickly moving between days
struct DateNavigatorButtons: View {
    @Binding var selectedDate: Date

    var body: some View {
        HStack(spacing: 4) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }

            Button("Today") {
                selectedDate = .now
            }
            .font(.caption)

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
        }
    }
}

// MARK: - Brand System

enum PlottedBrandColors {
    static let accent = Color(hex: "#D18A3A")
    static let navy = Color(hex: "#173B5D")
    static let teal = Color(hex: "#2D8E93")
    static let warmPaper = Color(hex: "#F7F8F7")
    static let mist = Color(hex: "#E9EEEC")
}

struct PlottedBrandBackground: View {
    var body: some View {
        LinearGradient(
            colors: [PlottedBrandColors.warmPaper, PlottedBrandColors.mist],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct PlottedGlobalTopBanner: View {
    let onTapSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onTapSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PlottedBrandColors.navy.opacity(0.6))
                    .frame(width: 34, height: 34)
            }

            Spacer()

            HStack(spacing: 8) {
                PlottedLogoMark(size: 20)
                Text("PLOTTED")
                    .font(.custom("AvenirNext-Bold", size: 17))
                    .foregroundStyle(PlottedBrandColors.navy)
                Text("digital\nplanner")
                    .font(.custom("AvenirNext-Medium", size: 9))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(PlottedBrandColors.teal)
                    .lineSpacing(0)
            }

            Spacer()

            Color.clear
                .frame(width: 34, height: 34)
        }
        .padding(.horizontal, 10)
        .padding(.top, 1)
        .padding(.bottom, 2)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct PlottedPageContainer<Content: View>: View {
    let onTapSettings: () -> Void
    var showTopBanner: Bool = true
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            TodayScreenBackground()

            VStack(spacing: 0) {
                if showTopBanner {
                    PlottedGlobalTopBanner(onTapSettings: onTapSettings)
                }
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct TodayScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#A8C9FF"),
                Color(hex: "#D7E3FF"),
                Color(hex: "#F5DCEB")
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
        .overlay {
            RadialGradient(
                colors: [Color.white.opacity(0.45), Color.clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }
}

struct TodayScreenHeader: View {
    @Binding var selectedDate: Date
    let onTapAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            TodayDateControl(selectedDate: $selectedDate)
                .fixedSize(horizontal: true, vertical: false)

            Text(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "#26324A"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .layoutPriority(1)

            Spacer(minLength: 0)

            Button(action: onTapAdd) {
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
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 2)
                    )
                    .shadow(color: Color(hex: "#6784D6").opacity(0.38), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TodayDateControl: View {
    @Binding var selectedDate: Date

    var body: some View {
        HStack(spacing: 12) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#5D6785"))
            }

            Button("Today") {
                selectedDate = .now
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(hex: "#2F3851"))

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
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
    }
}

struct PlottedLogoMark: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [PlottedBrandColors.navy, PlottedBrandColors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: size * 0.06)
                .padding(size * 0.2)

            VStack(spacing: size * 0.1) {
                HStack(spacing: size * 0.1) {
                    Circle().fill(Color.white.opacity(0.95))
                    Circle().fill(Color.white.opacity(0.95))
                    Circle().fill(Color.white.opacity(0.95))
                }
                .frame(height: size * 0.14)

                RoundedRectangle(cornerRadius: size * 0.05, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: size * 0.48, height: size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: PlottedBrandColors.navy.opacity(0.2), radius: 8, y: 4)
    }
}

struct PlottedBrandHeroCard: View {
    var body: some View {
        HStack(spacing: 14) {
            PlottedLogoMark(size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("Plotted Daily Planner")
                    .font(.custom("AvenirNext-Bold", size: 22))
                    .foregroundStyle(PlottedBrandColors.navy)

                Text("Plan beautifully. Focus deeply.")
                    .font(.custom("AvenirNext-Regular", size: 14))
                    .foregroundStyle(PlottedBrandColors.navy.opacity(0.72))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), PlottedBrandColors.warmPaper],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}
