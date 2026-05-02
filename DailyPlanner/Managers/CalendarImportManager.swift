// CalendarImportManager.swift
// DailyPlanner
//
// Manages importing events from Apple Calendar, Google Calendar, and Outlook
// using native iOS EventKit. Google and Outlook accounts connected via
// iOS Settings → Calendar → Accounts are automatically surfaced here —
// no OAuth or client IDs required.

import Foundation
import EventKit
import SwiftData
import SwiftUI

// MARK: - Provider

enum CalendarProvider: String, CaseIterable {
    case apple   = "apple"
    case google  = "google"
    case outlook = "outlook"

    var displayName: String {
        switch self {
        case .apple:   return "Apple Calendar"
        case .google:  return "Google Calendar"
        case .outlook: return "Outlook"
        }
    }

    var iconName: String {
        switch self {
        case .apple:   return "applelogo"
        case .google:  return "globe"
        case .outlook: return "envelope.fill"
        }
    }

    var brandColor: Color {
        switch self {
        case .apple:   return Color(hex: "#1C2B3A")
        case .google:  return Color(hex: "#4285F4")
        case .outlook: return Color(hex: "#0078D4")
        }
    }

    var connectedKey: String { "calendarConnected_\(rawValue)" }
    var accountKey:   String { "calendarAccount_\(rawValue)" }

    /// Keywords used to identify this provider in EKSource titles
    var sourceKeywords: [String] {
        switch self {
        case .apple:
            return [] // Apple is the fallback — everything not matched by others
        case .google:
            return ["google", "gmail"]
        case .outlook:
            return ["outlook", "hotmail", "live", "microsoft", "exchange", "office 365"]
        }
    }
}

// MARK: - Import Manager

@Observable
final class CalendarImportManager {

    static let shared = CalendarImportManager()

    private let store = EKEventStore()

    // Connection state per provider
    var appleConnected:   Bool   = false
    var googleConnected:  Bool   = false
    var outlookConnected: Bool   = false

    var appleAccount:     String = ""
    var googleAccount:    String = ""
    var outlookAccount:   String = ""

    // Status messages
    var appleStatus:   ImportStatus = .idle
    var googleStatus:  ImportStatus = .idle
    var outlookStatus: ImportStatus = .idle

    enum ImportStatus: Equatable {
        case idle
        case connecting
        case syncing
        case success(Int)       // number of events imported
        case needsIOSSetup      // account not found in iOS Settings
        case error(String)
    }

    private init() {
        appleConnected   = UserDefaults.standard.bool(forKey: CalendarProvider.apple.connectedKey)
        googleConnected  = UserDefaults.standard.bool(forKey: CalendarProvider.google.connectedKey)
        outlookConnected = UserDefaults.standard.bool(forKey: CalendarProvider.outlook.connectedKey)
        appleAccount     = UserDefaults.standard.string(forKey: CalendarProvider.apple.accountKey)   ?? ""
        googleAccount    = UserDefaults.standard.string(forKey: CalendarProvider.google.accountKey)  ?? ""
        outlookAccount   = UserDefaults.standard.string(forKey: CalendarProvider.outlook.accountKey) ?? ""
    }

    // MARK: - Permission

    /// Requests EventKit permission. Returns true if granted.
    @MainActor
    private func requestPermission() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                try await store.requestFullAccessToEvents()
            } else {
                try await store.requestAccess(to: .event)
            }
            let status = EKEventStore.authorizationStatus(for: .event)
            if #available(iOS 17.0, *) {
                return status == .fullAccess
            } else {
                return status == .authorized
            }
        } catch {
            return false
        }
    }

    // MARK: - Calendar Lookup

    /// Returns EKCalendars whose source matches the given provider.
    private func calendars(for provider: CalendarProvider) -> [EKCalendar] {
        let all = store.calendars(for: .event)
        switch provider {
        case .apple:
            // Apple calendars come from sources that are NOT matched by google or outlook keywords
            let googleKeys  = CalendarProvider.google.sourceKeywords
            let outlookKeys = CalendarProvider.outlook.sourceKeywords
            return all.filter { cal in
                let src = cal.source.title.lowercased()
                let isGoogle  = googleKeys.contains  { src.contains($0) }
                let isOutlook = outlookKeys.contains { src.contains($0) }
                return !isGoogle && !isOutlook
            }
        case .google, .outlook:
            let keywords = provider.sourceKeywords
            return all.filter { cal in
                let src = cal.source.title.lowercased()
                return keywords.contains { src.contains($0) }
            }
        }
    }

    // MARK: - Apple Calendar

    func connectApple(modelContext: ModelContext) {
        appleStatus = .connecting
        Task { @MainActor in
            guard await requestPermission() else {
                appleStatus = .error("Calendar access denied. Enable it in Settings → Privacy → Calendars.")
                return
            }
            appleStatus = .syncing
            let count = await importEvents(for: .apple, into: modelContext)
            let cals  = calendars(for: .apple)
            appleConnected = true
            appleAccount   = cals.first?.source.title ?? "Apple Calendar"
            UserDefaults.standard.set(true,        forKey: CalendarProvider.apple.connectedKey)
            UserDefaults.standard.set(appleAccount, forKey: CalendarProvider.apple.accountKey)
            appleStatus = .success(count)
        }
    }

    func syncApple(modelContext: ModelContext) {
        appleStatus = .syncing
        Task { @MainActor in
            let count = await importEvents(for: .apple, into: modelContext)
            appleStatus = .success(count)
        }
    }

    func disconnectApple() {
        appleConnected = false
        appleAccount   = ""
        appleStatus    = .idle
        UserDefaults.standard.set(false, forKey: CalendarProvider.apple.connectedKey)
        UserDefaults.standard.removeObject(forKey: CalendarProvider.apple.accountKey)
    }

    // MARK: - Google Calendar

    /// Google Calendar accounts added via iOS Settings → Mail → Accounts (or
    /// Settings → Calendar → Accounts) appear automatically in EventKit.
    func connectGoogle(modelContext: ModelContext) {
        googleStatus = .connecting
        Task { @MainActor in
            guard await requestPermission() else {
                googleStatus = .error("Calendar access denied. Enable it in Settings → Privacy → Calendars.")
                return
            }
            let cals = calendars(for: .google)
            guard !cals.isEmpty else {
                googleStatus = .needsIOSSetup
                return
            }
            googleStatus = .syncing
            let count = await importEvents(for: .google, into: modelContext)
            googleConnected = true
            googleAccount   = cals.first?.source.title ?? "Google Calendar"
            UserDefaults.standard.set(true,         forKey: CalendarProvider.google.connectedKey)
            UserDefaults.standard.set(googleAccount, forKey: CalendarProvider.google.accountKey)
            googleStatus = .success(count)
        }
    }

    func syncGoogle(modelContext: ModelContext) {
        googleStatus = .syncing
        Task { @MainActor in
            let count = await importEvents(for: .google, into: modelContext)
            googleStatus = .success(count)
        }
    }

    func disconnectGoogle() {
        googleConnected = false
        googleAccount   = ""
        googleStatus    = .idle
        UserDefaults.standard.set(false, forKey: CalendarProvider.google.connectedKey)
        UserDefaults.standard.removeObject(forKey: CalendarProvider.google.accountKey)
    }

    // MARK: - Outlook

    /// Outlook / Exchange accounts added via iOS Settings → Mail → Accounts
    /// appear automatically in EventKit.
    func connectOutlook(modelContext: ModelContext) {
        outlookStatus = .connecting
        Task { @MainActor in
            guard await requestPermission() else {
                outlookStatus = .error("Calendar access denied. Enable it in Settings → Privacy → Calendars.")
                return
            }
            let cals = calendars(for: .outlook)
            guard !cals.isEmpty else {
                outlookStatus = .needsIOSSetup
                return
            }
            outlookStatus = .syncing
            let count = await importEvents(for: .outlook, into: modelContext)
            outlookConnected = true
            outlookAccount   = cals.first?.source.title ?? "Outlook"
            UserDefaults.standard.set(true,          forKey: CalendarProvider.outlook.connectedKey)
            UserDefaults.standard.set(outlookAccount, forKey: CalendarProvider.outlook.accountKey)
            outlookStatus = .success(count)
        }
    }

    func syncOutlook(modelContext: ModelContext) {
        outlookStatus = .syncing
        Task { @MainActor in
            let count = await importEvents(for: .outlook, into: modelContext)
            outlookStatus = .success(count)
        }
    }

    func disconnectOutlook() {
        outlookConnected = false
        outlookAccount   = ""
        outlookStatus    = .idle
        UserDefaults.standard.set(false, forKey: CalendarProvider.outlook.connectedKey)
        UserDefaults.standard.removeObject(forKey: CalendarProvider.outlook.accountKey)
    }

    // MARK: - Write-back (two-way sync)

    /// Creates a new EKEvent in the best available connected calendar.
    /// Returns the EKEvent.eventIdentifier so it can be stored on the SwiftData model.
    @discardableResult
    func createEKEvent(title: String, startTime: Date, endTime: Date, notes: String) -> String? {
        let calStatus = EKEventStore.authorizationStatus(for: .event)
        let calAuthorized: Bool
        if #available(iOS 17.0, macOS 14.0, *) {
            calAuthorized = calStatus == .fullAccess
        } else {
            calAuthorized = calStatus == .authorized
        }
        guard calAuthorized else { return nil }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title     = title
        ekEvent.startDate = startTime
        ekEvent.endDate   = endTime
        ekEvent.notes     = notes.isEmpty ? nil : notes
        ekEvent.calendar  = bestWritableCalendar()

        do {
            try store.save(ekEvent, span: .thisEvent, commit: true)
            return ekEvent.eventIdentifier
        } catch {
            return nil
        }
    }

    /// Updates an existing EKEvent matched by its stored identifier.
    func updateEKEvent(identifier: String, title: String, startTime: Date, endTime: Date, notes: String) {
        let updateStatus = EKEventStore.authorizationStatus(for: .event)
        let updateAuthorized: Bool
        if #available(iOS 17.0, macOS 14.0, *) {
            updateAuthorized = updateStatus == .fullAccess
        } else {
            updateAuthorized = updateStatus == .authorized
        }
        guard updateAuthorized else { return }
        guard let ekEvent = store.event(withIdentifier: identifier) else { return }

        ekEvent.title     = title
        ekEvent.startDate = startTime
        ekEvent.endDate   = endTime
        ekEvent.notes     = notes.isEmpty ? nil : notes

        try? store.save(ekEvent, span: .thisEvent, commit: true)
    }

    /// Deletes the EKEvent matched by its stored identifier.
    func deleteEKEvent(identifier: String) {
        let deleteStatus = EKEventStore.authorizationStatus(for: .event)
        let deleteAuthorized: Bool
        if #available(iOS 17.0, macOS 14.0, *) {
            deleteAuthorized = deleteStatus == .fullAccess
        } else {
            deleteAuthorized = deleteStatus == .authorized
        }
        guard deleteAuthorized else { return }
        guard let ekEvent = store.event(withIdentifier: identifier) else { return }
        try? store.remove(ekEvent, span: .thisEvent, commit: true)
    }

    /// Picks the best calendar to write new events into.
    /// Priority: connected Google → connected Outlook → connected Apple → system default.
    private func bestWritableCalendar() -> EKCalendar {
        if googleConnected {
            let cals = calendars(for: .google)
            if let cal = cals.first(where: { $0.allowsContentModifications }) { return cal }
        }
        if outlookConnected {
            let cals = calendars(for: .outlook)
            if let cal = cals.first(where: { $0.allowsContentModifications }) { return cal }
        }
        if appleConnected {
            let cals = calendars(for: .apple)
            if let cal = cals.first(where: { $0.allowsContentModifications }) { return cal }
        }
        return store.defaultCalendarForNewEvents ?? store.calendars(for: .event).first!
    }

    // MARK: - Shared Import

    @MainActor
    private func importEvents(for provider: CalendarProvider, into context: ModelContext) async -> Int {
        let cals = calendars(for: provider)
        guard !cals.isEmpty else { return 0 }

        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: 90, to: now)!
        let pred = store.predicateForEvents(withStart: now, end: end, calendars: cals)
        let ekEvents = store.events(matching: pred)

        var imported = 0
        for ek in ekEvents {
            guard let title = ek.title, !title.isEmpty else { continue }
            let start = ek.startDate ?? now

            // Skip duplicates — match by ekEventIdentifier first, fall back to title+time
            let ekId = ek.eventIdentifier ?? ""
            let fetchByIdDesc = FetchDescriptor<CalendarEvent>(
                predicate: #Predicate { $0.ekEventIdentifier == ekId }
            )
            if let byId = try? context.fetch(fetchByIdDesc), !byId.isEmpty { continue }

            let fetchDesc = FetchDescriptor<CalendarEvent>(
                predicate: #Predicate { $0.title == title }
            )
            let existing = (try? context.fetch(fetchDesc)) ?? []
            let alreadyExists = existing.contains {
                Calendar.current.isDate($0.startTime, equalTo: start, toGranularity: .minute)
            }
            guard !alreadyExists else { continue }

            let duration = Int((ek.endDate?.timeIntervalSince(start) ?? 3600) / 60)
            let colorHex = ek.calendar.cgColor.map { hexFrom(cgColor: $0) } ?? "#5E8FFF"
            let event = CalendarEvent(
                title:              title,
                startTime:          start,
                durationMinutes:    max(duration, 15),
                colorHex:           colorHex,
                notes:              ek.notes ?? "",
                ekEventIdentifier:  ek.eventIdentifier
            )
            context.insert(event)
            imported += 1
        }
        try? context.save()
        return imported
    }

    private func hexFrom(cgColor: CGColor) -> String {
        guard let comps = cgColor.components, comps.count >= 3 else { return "#5E8FFF" }
        let r = Int(comps[0] * 255)
        let g = Int(comps[1] * 255)
        let b = Int(comps[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
