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

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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

    // MARK: - iPhone Layout  (tab bar with Today and Inbox tabs)

    private var iPhoneLayout: some View {
        TabView {
            TodayTabView()
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }

            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "tray.full")
                }
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
        NavigationStack {
            DayTimelineView(
                selectedDate: $selectedDate,
                onTapEmptySlot: { tappedTime in
                    presetStartTime = tappedTime
                    isAddingTask = true
                }
            )
            .navigationTitle(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DateNavigatorButtons(selectedDate: $selectedDate)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presetStartTime = nil
                        isAddingTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                TaskEditorView(startTime: presetStartTime ?? nextRoundedHour())
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
            case .inbox:
                InboxView()
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
                    ToolbarItem(placement: .navigationBarLeading) {
                        DateNavigatorButtons(selectedDate: $selectedDate)
                    }
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
            case .inbox:
                InboxView()
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
    case inbox
    case category(UUID)
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

                Label("Inbox", systemImage: "tray.full")
                    .tag(SidebarItem.inbox)
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
        }
        .listStyle(.sidebar)
        .navigationTitle("Planner")
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

// MARK: - Color Extension

/// Converts a hex string like "#FF6B6B" or "FF6B6B" into a SwiftUI Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
