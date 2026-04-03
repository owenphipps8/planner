// RecurrencePickerView.swift
// DailyPlanner
//
// A dedicated sheet for choosing how a task repeats.

import SwiftUI

struct RecurrencePickerView: View {

    @Binding var recurrenceRule: RecurrenceRule?
    @Environment(\.dismiss) private var dismiss

    /// Which high-level option is selected in the picker
    @State private var selectedOption: RecurrenceOption = .never

    /// Which days are checked when "weekly" is selected
    @State private var selectedWeekdays: Set<Weekday> = []

    // Options shown in the picker list
    enum RecurrenceOption: String, CaseIterable, Identifiable {
        case never   = "Never"
        case daily   = "Every Day"
        case weekly  = "Weekly"
        case monthly = "Every Month"

        var id: String { rawValue }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Repeat", selection: $selectedOption) {
                        ForEach(RecurrenceOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // Day-of-week selector only shown when "weekly" is picked
                if selectedOption == .weekly {
                    Section("On these days") {
                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                let isSelected = selectedWeekdays.contains(day)
                                Text(day.shortName)
                                    .font(.caption)
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle().fill(isSelected ? Color.accentColor : Color(.systemGray5))
                                    )
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .onTapGesture {
                                        if isSelected {
                                            selectedWeekdays.remove(day)
                                        } else {
                                            selectedWeekdays.insert(day)
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applySelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear { loadCurrentRule() }
        .presentationDetents([.medium])
    }

    // MARK: - Load / Apply

    private func loadCurrentRule() {
        switch recurrenceRule {
        case nil:
            selectedOption = .never
        case .daily:
            selectedOption = .daily
        case .weekly(let days):
            selectedOption = .weekly
            selectedWeekdays = Set(days)
        case .monthly:
            selectedOption = .monthly
        }
    }

    private func applySelection() {
        switch selectedOption {
        case .never:
            recurrenceRule = nil
        case .daily:
            recurrenceRule = .daily
        case .weekly:
            if selectedWeekdays.isEmpty {
                recurrenceRule = nil
            } else {
                recurrenceRule = .weekly(days: Array(selectedWeekdays))
            }
        case .monthly:
            recurrenceRule = .monthly
        }
    }
}

// MARK: - Preview

#Preview {
    RecurrencePickerView(recurrenceRule: .constant(.weekly(days: [.monday, .wednesday, .friday])))
}
