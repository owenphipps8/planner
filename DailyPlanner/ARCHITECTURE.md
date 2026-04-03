# DailyPlanner - Architecture Guide

A visual daily planner app for iPhone, iPad, Mac, and Apple Watch, inspired by Structured.

---

## Xcode Project Setup

### Step 1: Create the Project

1. Open Xcode and choose **File > New > Project**
2. Select **Multiplatform > App** (this creates a single target that runs on iPhone, iPad, and Mac)
3. Name it **DailyPlanner**
4. Set:
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - Check **Include Tests** (recommended)
5. Choose a Team (your Apple Developer account)
6. Enable **iCloud** in Signing & Capabilities > + Capability > CloudKit

### Step 2: Add Watch Target

1. File > New > Target
2. Choose **watchOS > Watch App**
3. Name it **DailyPlannerWatch**
4. Make sure "Include Notification Scene" is checked

### Step 3: Add Widget Target

1. File > New > Target
2. Choose **iOS > Widget Extension**
3. Name it **PlannerWidget**
4. Include Live Activity: No (keep it simple for v1)

### Step 4: Add App Groups (for sharing data with Widget and Watch)

1. Select the main app target > Signing & Capabilities > + Capability > **App Groups**
2. Add: `group.com.yourname.dailyplanner`
3. Repeat for the Widget and Watch targets

---

## Project File Structure

Copy the Swift files from this scaffold into Xcode by dragging them into the Navigator pane.

```
DailyPlanner/               <- Main app target
  App/
    DailyPlannerApp.swift   <- App entry point, sets up SwiftData + CloudKit
  Models/
    PlannerTask.swift       <- SwiftData model for a task
    TaskCategory.swift      <- Category/color grouping
    RecurrenceRule.swift    <- Enum for repeating tasks
  ViewModels/
    PlannerViewModel.swift  <- Business logic, CRUD operations
  Views/
    ContentView.swift       <- Root view (handles iPhone/iPad/Mac layout)
    Timeline/
      DayTimelineView.swift  <- The visual timeline (core feature)
      TaskBlockView.swift    <- Individual task block on the timeline
      TimelineRuler.swift    <- Hour labels and grid lines
      CurrentTimeBar.swift   <- The red "now" indicator
    TaskEditor/
      TaskEditorView.swift   <- Create/edit a task (sheet)
      RecurrencePickerView.swift
      DurationPickerView.swift
    Shared/
      CategoryBadge.swift    <- Colored dot/pill used in multiple places
  Managers/
    NotificationManager.swift <- Scheduling local notifications

PlannerWidget/              <- Widget extension target
  PlannerWidget.swift
  PlannerWidgetEntry.swift

PlannerWatch/               <- watchOS target
  WatchContentView.swift
  WatchUpNextView.swift
```

---

## Technology Stack

| Need | Technology | Why |
|---|---|---|
| UI framework | SwiftUI | Works on all Apple platforms with shared code |
| Data persistence | SwiftData | Apple's modern ORM, simpler than CoreData |
| Cloud sync | CloudKit (via SwiftData) | Free iCloud sync, no backend needed |
| Notifications | UserNotifications | Local push alerts |
| Widgets | WidgetKit | Home Screen, Lock Screen, StandBy widgets |
| Watch | WatchKit / SwiftUI | Companion glance and complication |

---

## Data Model Overview

### PlannerTask
The central model. Stored in SwiftData and synced via CloudKit.

```
PlannerTask
  id: UUID
  title: String
  startTime: Date          <- exact start date+time
  durationMinutes: Int     <- how long the task runs
  colorHex: String         <- e.g. "#FF6B6B"
  symbolName: String       <- SF Symbol name e.g. "fork.knife"
  notes: String
  isCompleted: Bool
  recurrenceRule: String?  <- JSON-encoded RecurrenceRule
  category: TaskCategory?
```

### TaskCategory
```
TaskCategory
  id: UUID
  name: String             <- "Work", "Health", "Personal"
  colorHex: String
  symbolName: String
```

---

## Architecture Pattern: MVVM

**Model** - SwiftData objects (PlannerTask, TaskCategory)
**ViewModel** - PlannerViewModel handles filtering, sorting, creating tasks
**View** - SwiftUI views read from the ViewModel using @Query and @Observable

```
View (SwiftUI) ---reads---> ViewModel (@Observable)
                               |
                        SwiftData @Model
                               |
                          CloudKit sync
```

---

## Timeline View Explained

The timeline is a vertical, scrollable view. The math:

- Each hour = 60 points tall (the `hourHeight` constant)
- A task block's Y offset = `(taskStartHour - visibleStartHour) * hourHeight + (taskStartMinute / 60.0) * hourHeight`
- A task block's height = `(durationMinutes / 60.0) * hourHeight`

The timeline shows hours from midnight (0) to midnight (24), but scrolls to the current time on launch.

---

## iCloud Sync Setup

SwiftData handles CloudKit sync automatically when you:

1. Configure ModelContainer with a CloudKit container identifier
2. Enable iCloud + CloudKit in the app target's capabilities
3. Use `@Model` on your data classes

The container string is your bundle ID prefixed with `iCloud.`:
`iCloud.com.yourname.dailyplanner`

---

## Minimum Deployment Targets

| Platform | Minimum Version | Why |
|---|---|---|
| iOS / iPadOS | 17.0 | SwiftData requires iOS 17 |
| macOS | 14.0 (Sonoma) | SwiftData requires macOS 14 |
| watchOS | 10.0 | SwiftUI improvements |

---

## Next Steps After Scaffolding

1. Create the Xcode project using the instructions above
2. Copy in the Swift files from this scaffold
3. Add your App Group identifier everywhere you see `group.com.yourname.dailyplanner`
4. Replace `com.yourname.dailyplanner` with your actual bundle ID
5. Build and run on iPhone simulator first
6. Then test on iPad, Mac (via Designed for iPad or native Mac), and Watch simulator
