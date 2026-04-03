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

    var body: some View {
        ZStack(alignment: .topLeading) {

            // Horizontal grid line spanning the full width
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(width: totalWidth, height: 0.5)
                .offset(y: 0)

            // Half-hour divider line (lighter, shorter)
            Rectangle()
                .fill(Color(.separator).opacity(0.15))
                .frame(width: totalWidth - rulerWidth, height: 0.5)
                .offset(x: rulerWidth, y: hourHeight / 2)

            // Hour label on the left
            Text(hourLabel(for: hour))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: rulerWidth - 8, alignment: .trailing)
                .offset(y: -8) // nudge up so the label aligns with the line
        }
        .frame(height: hourHeight)
    }

    /// Format: "12 AM", "1 PM", "12 PM", etc.
    private func hourLabel(for hour: Int) -> String {
        if hour == 0  { return "12\nAM" }
        if hour == 12 { return "12\nPM" }
        if hour < 12  { return "\(hour)\nAM" }
        return "\(hour - 12)\nPM"
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
