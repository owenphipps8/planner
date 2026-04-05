// SettingsViewNew.swift
// DailyPlanner
//
// Settings and customization view for app appearance and features.

import SwiftUI

struct SettingsView: View {

    // MARK: - Environment

    @State private var theme = AppTheme.shared

    // MARK: - State

    @State private var showResetConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PlottedBrandHeroCard()
                }

                // Theme section
                Section("Theme") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preset Themes")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ThemePreset.presets, id: \.name) { preset in
                                    ThemePresetButton(preset: preset) {
                                        theme.primaryColorHex = preset.primaryColorHex
                                        theme.secondaryColorHex = preset.secondaryColorHex
                                        theme.accentColorHex = preset.accentColorHex
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Dark mode toggle
                    Toggle("Dark Mode", isOn: $theme.isDarkMode)
                }

                // Color customization section
                Section("Colors") {
                    ColorCustomizationRow(
                        label: "Primary Color",
                        selectedColor: $theme.primaryColorHex
                    )

                    ColorCustomizationRow(
                        label: "Secondary Color",
                        selectedColor: $theme.secondaryColorHex
                    )

                    ColorCustomizationRow(
                        label: "Accent Color",
                        selectedColor: $theme.accentColorHex
                    )
                }

                // Font section
                Section("Font") {
                    Picker("Font Family", selection: $theme.font) {
                        Text("System").tag("System")
                        Text("San Francisco").tag("San Francisco")
                        Text("Serif").tag("Serif")
                        Text("Monospace").tag("Monospace")
                    }
                }

                // App info section
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }
                }

                // Actions section
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                    }
                    .alert("Reset Settings?", isPresented: $showResetConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Reset", role: .destructive) {
                            theme.resetToDefaults()
                        }
                    } message: {
                        Text("This will reset all customizations to their default values.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Color Customization Row

struct ColorCustomizationRow: View {

    let label: String
    @Binding var selectedColor: String

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ColorPalette.allColors, id: \.self) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Theme Preset Button

struct ThemePresetButton: View {

    let preset: ThemePreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: preset.primaryColorHex))
                    Circle()
                        .fill(Color(hex: preset.secondaryColorHex))
                    Circle()
                        .fill(Color(hex: preset.accentColorHex))
                }
                .frame(height: 24)

                Text(preset.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: 70)
            .padding(8)
            .background(Color(hex: "#F5F5F5"))
            .cornerRadius(8)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Color Palette

struct ColorPalette {
    static let allColors: [String] = [
        "#FF6B6B", // Red
        "#FFA500", // Orange
        "#FFD93D", // Yellow
        "#51CF66", // Green
        "#5E8FFF", // Blue
        "#9775FA", // Purple
        "#FF8CC9", // Pink
        "#888888", // Gray
    ]
}

#Preview {
    SettingsView()
}
