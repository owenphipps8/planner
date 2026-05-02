// SettingsViewNew.swift
// DailyPlanner
//
// Settings and customization view for app appearance and features.

import SwiftUI
import SwiftData

struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @State private var theme = AppTheme.shared
    @State private var importer = CalendarImportManager.shared

    // MARK: - State

    @State private var showResetConfirmation = false
    @State private var disconnectTarget: CalendarProvider? = nil

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

                // Calendar Import section
                Section {
                    CalendarImportRow(
                        provider: .apple,
                        isConnected: importer.appleConnected,
                        account: importer.appleAccount,
                        status: importer.appleStatus,
                        onConnect: { importer.connectApple(modelContext: modelContext) },
                        onSync:    { importer.syncApple(modelContext: modelContext) },
                        onDisconnect: { disconnectTarget = .apple }
                    )

                    CalendarImportRow(
                        provider: .google,
                        isConnected: importer.googleConnected,
                        account: importer.googleAccount,
                        status: importer.googleStatus,
                        onConnect: { importer.connectGoogle(modelContext: modelContext) },
                        onSync:    { importer.syncGoogle(modelContext: modelContext) },
                        onDisconnect: { disconnectTarget = .google }
                    )

                    CalendarImportRow(
                        provider: .outlook,
                        isConnected: importer.outlookConnected,
                        account: importer.outlookAccount,
                        status: importer.outlookStatus,
                        onConnect: { importer.connectOutlook(modelContext: modelContext) },
                        onSync:    { importer.syncOutlook(modelContext: modelContext) },
                        onDisconnect: { disconnectTarget = .outlook }
                    )
                } header: {
                    Label("Calendar Import", systemImage: "calendar.badge.plus")
                }
                // Info note
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#5E8FFF"))
                        .padding(.top, 1)
                    Text("To connect Google or Outlook, first add your account in **iOS Settings → Mail → Accounts**, then tap Add above. Apple Calendar connects directly.")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .listRowBackground(Color(hex: "#F0F4FF").opacity(0.7))
                .confirmationDialog(
                    "Disconnect Calendar?",
                    isPresented: Binding(
                        get: { disconnectTarget != nil },
                        set: { if !$0 { disconnectTarget = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Disconnect", role: .destructive) {
                        switch disconnectTarget {
                        case .apple:   importer.disconnectApple()
                        case .google:  importer.disconnectGoogle()
                        case .outlook: importer.disconnectOutlook()
                        case nil: break
                        }
                        disconnectTarget = nil
                    }
                    Button("Cancel", role: .cancel) { disconnectTarget = nil }
                } message: {
                    if let p = disconnectTarget {
                        Text("Your \(p.displayName) events will remain in Plotted but no new events will be synced.")
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
            .scrollContentBackground(.hidden)
            .colorScheme(theme.colorScheme)
            .background(TodayScreenBackground())
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
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

// MARK: - Calendar Import Row

struct CalendarImportRow: View {
    let provider:     CalendarProvider
    let isConnected:  Bool
    let account:      String
    let status:       CalendarImportManager.ImportStatus
    let onConnect:    () -> Void
    let onSync:       () -> Void
    let onDisconnect: () -> Void

    private let theme = AppTheme.shared

    private var isLoading: Bool {
        status == .connecting || status == .syncing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                // Provider icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(provider.brandColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: provider.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(provider.brandColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#1C2B3A"))

                    if isConnected && !account.isEmpty {
                        Text(account)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#5D6785"))
                    } else {
                        Text("Not connected")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#9AA0B0"))
                    }
                }

                Spacer(minLength: 0)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.85)
                } else if isConnected {
                    // Connected state: sync + connected badge
                    HStack(spacing: 8) {
                        Button(action: onSync) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(provider.brandColor)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(provider.brandColor.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: onDisconnect) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "#34C759"))
                                    .frame(width: 7, height: 7)
                                Text("Connected")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "#34C759"))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color(hex: "#34C759").opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                } else {
                    // Not connected: Add button
                    Button(action: onConnect) {
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(theme.buttonGradientH))
                            .shadow(color: theme.buttonShadowColor, radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Status message
            switch status {
            case .success(let count):
                Label("\(count) event\(count == 1 ? "" : "s") imported", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#34C759"))
            case .error(let msg):
                Label(msg, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            case .needsIOSSetup:
                VStack(alignment: .leading, spacing: 4) {
                    Label("Account not found", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Add your \(provider.displayName) account in iOS Settings → Calendar → Accounts, then tap Add again.")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#5D6785"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            case .syncing:
                Label("Syncing events…", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#5D6785"))
            case .connecting:
                Label("Connecting…", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#5D6785"))
            case .idle:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
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
