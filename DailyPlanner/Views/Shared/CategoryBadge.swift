// CategoryBadge.swift
// DailyPlanner
//
// A reusable view component for displaying a TaskCategory inline.
// Used in task blocks, task lists, the inbox, and the sidebar.

import SwiftUI

struct CategoryBadge: View {

    let category: TaskCategory
    var style: Style = .pill

    // MARK: - Style Variants

    enum Style {
        /// Full capsule pill with icon + name, tinted in category color
        case pill
        /// Small colored dot — minimal footprint (e.g., inline list)
        case dot
        /// Just the SF Symbol in the category color
        case iconOnly
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .pill:
            Label(category.name, systemImage: category.symbolName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color(hex: category.colorHex))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(hex: category.colorHex).opacity(0.12))
                )

        case .dot:
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 8, height: 8)

        case .iconOnly:
            Image(systemName: category.symbolName)
                .foregroundStyle(Color(hex: category.colorHex))
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        CategoryBadge(
            category: TaskCategory(name: "Work", colorHex: "#5E8FFF", symbolName: "laptopcomputer"),
            style: .pill
        )
        HStack(spacing: 8) {
            CategoryBadge(
                category: TaskCategory(name: "Health", colorHex: "#4CAF82", symbolName: "heart.fill"),
                style: .dot
            )
            Text("Health category")
                .font(.caption)
        }
        CategoryBadge(
            category: TaskCategory(name: "Personal", colorHex: "#FF9F43", symbolName: "person.fill"),
            style: .iconOnly
        )
    }
    .padding()
}
