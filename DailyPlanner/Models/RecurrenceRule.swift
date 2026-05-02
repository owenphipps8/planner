// RecurrenceRule.swift
// DailyPlanner
//
// Describes how a task repeats. Stored as JSON inside PlannerTask.recurrenceRuleData.

import Foundation

/// The days of the week, matching Swift's Calendar weekday numbering (1 = Sunday)
enum DayOfWeek: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday:    return "Su"
        case .monday:    return "Mo"
        case .tuesday:   return "Tu"
        case .wednesday: return "We"
        case .thursday:  return "Th"
        case .friday:    return "Fr"
        case .saturday:  return "Sa"
        }
    }

    var fullName: String {
        switch self {
        case .sunday:    return "Sunday"
        case .monday:    return "Monday"
        case .tuesday:   return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday:  return "Thursday"
        case .friday:    return "Friday"
        case .saturday:  return "Saturday"
        }
    }
}

/// Defines how often a task repeats
enum RecurrenceRule: Codable, Equatable {

    /// Repeats every day
    case daily

    /// Repeats on specific days of the week (e.g. Mon, Wed, Fri)
    case weekly(days: [DayOfWeek])

    /// Repeats on the same day every month
    case monthly

    // MARK: - Display Label

    var label: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekly(let days):
            if days.count == 7 {
                return "Every day"
            } else if days == [.monday, .tuesday, .wednesday, .thursday, .friday] {
                return "Weekdays"
            } else if days == [.saturday, .sunday] {
                return "Weekends"
            } else {
                let names = days.sorted { $0.rawValue < $1.rawValue }.map { $0.shortName }
                return names.joined(separator: ", ")
            }
        case .monthly:
            return "Every month"
        }
    }

    // MARK: - Next Occurrence

    /// Given a base date, return the next date this rule triggers after the given reference date.
    /// Returns nil if no occurrence can be found within a reasonable search window (90 days).
    func nextOccurrence(after reference: Date, baseDate: Date) -> Date? {
        let calendar = Calendar.current
        var candidate = calendar.date(byAdding: .day, value: 1, to: reference) ?? reference

        // Search up to 90 days ahead
        let limit = calendar.date(byAdding: .day, value: 90, to: reference) ?? reference

        while candidate <= limit {
            let weekday = calendar.component(.weekday, from: candidate)

            switch self {
            case .daily:
                // Transfer the time-of-day from the base date to the candidate date
                return transferTime(from: baseDate, toDate: candidate)

            case .weekly(let days):
                if days.map({ $0.rawValue }).contains(weekday) {
                    return transferTime(from: baseDate, toDate: candidate)
                }

            case .monthly:
                let baseDay = calendar.component(.day, from: baseDate)
                let candidateDay = calendar.component(.day, from: candidate)
                if candidateDay == baseDay {
                    return transferTime(from: baseDate, toDate: candidate)
                }
            }

            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        return nil
    }

    // MARK: - Private Helpers

    private func transferTime(from source: Date, toDate target: Date) -> Date {
        let calendar = Calendar.current
        let sourceComponents = calendar.dateComponents([.hour, .minute, .second], from: source)
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: target)
        targetComponents.hour = sourceComponents.hour
        targetComponents.minute = sourceComponents.minute
        targetComponents.second = sourceComponents.second
        return calendar.date(from: targetComponents) ?? target
    }
}
