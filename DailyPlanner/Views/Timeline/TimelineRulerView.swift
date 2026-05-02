// TimelineRulerView.swift
// DailyPlanner
//
// Draws the hour labels and horizontal grid lines that form the background of the timeline.
// This is a pure display view with no interactivity.

import SwiftUI

struct TimelineRulerView: View {

    let startHour: Int
    let endHour: Int
    let hourHeight: CGFloat
    let rulerWidth: CGFloat
    let totalWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HourRow(
                    hour: hour,
                    hourHeight: hourHeight,
                    rulerWidth: rulerWidth,
                    totalWidth: totalWidth
                )
                .offset(y: CGFloat(hour - startHour) * hourHeight)
            }
        }
    }
}

// MARK: - Hour Row

private struct HourRow: View {
    let hour: Int
    let hourHeight: CGFloat
    let rulerWidth: CGFloat
    let totalWidth: CGFloat

    private var safeTotalWidth: CGFloat { totalWidth.isFinite ? max(totalWidth, 0) : 0 }
    private var safeGridWidth: CGFloat {
        let raw = safeTotalWidth - rulerWidth
        return raw.isFinite ? max(raw, 0) : 0
    }
    private var safeLabelWidth: CGFloat {
        let raw = rulerWidth - 8
        return raw.isFinite ? max(raw, 0) : 0
    }

    var body: some View {
        ZStack(alignment: .topLeading) {

            // Horizontal grid line from the ruler edge to full width
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(width: safeTotalWidth, height: 0.5)

            // Half-hour divider (lighter, starts after ruler)
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(width: safeGridWidth, height: 0.5)
                .offset(x: rulerWidth, y: hourHeight / 2)

            // Label: fully above the line, right-aligned in the ruler column.
            // Use a single compact line so we know the exact height (~13pt),
            // then offset up by that height so the baseline sits on the line.
            Text(hourLabel(for: hour))
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Color.secondary.opacity(0.75))
                .frame(width: safeLabelWidth, alignment: .trailing)
                .offset(y: -13)
        }
        .frame(height: hourHeight)
    }

    /// "12 AM", "1 PM", etc. — single line compact format
    private func hourLabel(for hour: Int) -> String {
        let num: String
        if hour == 0 || hour == 12 { num = "12" }
        else if hour < 12           { num = "\(hour)" }
        else                        { num = "\(hour - 12)" }
        let period = hour < 12 ? "AM" : "PM"
        return "\(num) \(period)"
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        TimelineRulerView(
            startHour: 6,
            endHour: 22,
            hourHeight: 64,
            rulerWidth: 56,
            totalWidth: 375
        )
    }
}
