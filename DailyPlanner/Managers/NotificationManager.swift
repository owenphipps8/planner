// NotificationManager.swift
// DailyPlanner
//
// Handles scheduling and canceling local notifications.
// iOS/macOS: uses UserNotifications framework.
// The app must request permission before scheduling (done at first launch).

import Foundation
import UserNotifications

final class NotificationManager {

    // MARK: - Singleton

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    /// Call this once at app startup to ask the user for notification permission.
    /// On macOS and iOS this shows a system dialog the first time.
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    // MARK: - Schedule

    /// Schedules a local notification to fire at the task's start time.
    /// If a notification for this task already exists, it is replaced.
    func scheduleNotification(for task: PlannerTask) {
        // Don't schedule notifications for tasks that have already passed
        guard task.startTime > Date.now else { return }

        // Remove any existing notification for this task first
        removeNotification(for: task)

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = "Starting now · \(task.durationLabel)"
        content.sound = .default

        // Use the task's category name as the notification category if available
        if let category = task.category {
            content.subtitle = category.name
        }

        // The identifier for this notification uses the task's ID
        let identifier = notificationIdentifier(for: task)

        // Create the trigger from the task's exact start time
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.startTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification for \(task.title): \(error)")
            }
        }
    }

    /// Schedules notifications for all tasks in the provided list that haven't started yet.
    func scheduleAll(tasks: [PlannerTask]) {
        for task in tasks where task.startTime > Date.now {
            scheduleNotification(for: task)
        }
    }

    // MARK: - Remove

    /// Cancels the notification for a specific task.
    func removeNotification(for task: PlannerTask) {
        let identifier = notificationIdentifier(for: task)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancels all pending notifications (useful on sign-out or data wipe).
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func notificationIdentifier(for task: PlannerTask) -> String {
        "task-\(task.id.uuidString)"
    }
}
