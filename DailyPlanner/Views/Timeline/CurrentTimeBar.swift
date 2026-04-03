// CurrentTimeBar.swift
// DailyPlanner
//
// The red horizontal line + dot that shows where "now" is on the timeline.
// Only shown when the user is viewing today.
// Auto-refreshes every minute to stay accurate.

import SwiftUI

struct CurrentTimeBar: View {

    let rulerWidth: CGFloat
    let totalWidth: CGFloat
    let yOffset: CGFloat

    /// Trigger a view refresh every 60 seconds so the bar moves with time
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    @State private var currentOffset: CGFloat

    init(rulerWidth: CGFloat, totalWidth: CGFloat, yOffset: CGFloat) {
        self.rulerWidth = rulerWidth
        self.totalWidth = totalWidth
        self.yOffset = yOffset
        _currentOffset = State(initialValue: yOffset)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // The horizontal line
            Rectangle()
                .fill(Color.red)
                .frame(width: totalWidth - rulerWidth, height: 1.5)
                .offset(x: rulerWidth)

            // The dot on the left end of the line
            Circle()
                .fill(Color.red)
                .frame(width: 9, height: 9)
                .offset(x: rulerWidth - 4)
        }
        .offset(y: currentOffset)
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.3)) {
                currentOffset = recalculateOffset()
            }
        }
    }

    // MARK: - Time Calculation

    private func recalculateOffset() -> CGFloat {
        let hourHeight: CGFloat = 64 // must match DayTimelineView
        let calendar = Calendar.current
        let now = Date.now
        let startOfDay = calendar.startOfDay(for: now)
        let secondsIntoDay = now.timeIntervalSince(startOfDay)
        let hoursIntoDay = secondsIntoDay / 3600
        return CGFloat(hoursIntoDay) * hourHeight
    }
}
