// AppTheme.swift
// DailyPlanner
//
// Single source of truth for app-wide colors, dark mode, and font.

import SwiftUI

@Observable
final class AppTheme {
    static let shared = AppTheme()

    var primaryColorHex: String {
        didSet { saveTheme() }
    }

    var secondaryColorHex: String {
        didSet { saveTheme() }
    }

    var accentColorHex: String {
        didSet { saveTheme() }
    }

    var isDarkMode: Bool {
        didSet { saveTheme() }
    }

    var font: String {
        didSet { saveTheme() }
    }

    // MARK: - Computed Color Properties

    var primaryColor: Color   { Color(hex: primaryColorHex) }
    var secondaryColor: Color { Color(hex: secondaryColorHex) }
    var accentColor: Color    { Color(hex: accentColorHex) }

    /// Two-color gradient used for buttons, selected states, FABs
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Horizontal variant (e.g. pill buttons)
    var buttonGradientH: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Shadow color derived from primary
    var buttonShadowColor: Color {
        primaryColor.opacity(0.38)
    }

    /// Three-stop background gradient (pastel wash over white)
    var backgroundGradientColors: [Color] {
        if isDarkMode {
            return [
                primaryColor.opacity(0.30),
                secondaryColor.opacity(0.18),
                accentColor.opacity(0.22),
            ]
        } else {
            return [
                primaryColor.opacity(0.38),
                secondaryColor.opacity(0.22),
                accentColor.opacity(0.28),
            ]
        }
    }

    /// Base background color (dark or white)
    var backgroundBase: Color {
        isDarkMode ? Color(hex: "#12131A") : Color.white
    }

    /// Resolved ColorScheme
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }

    // MARK: - Initialization

    private init() {
        self.primaryColorHex   = UserDefaults.standard.string(forKey: "primaryColorHex")   ?? "#6D66FF"
        self.secondaryColorHex = UserDefaults.standard.string(forKey: "secondaryColorHex") ?? "#32B4FF"
        self.accentColorHex    = UserDefaults.standard.string(forKey: "accentColorHex")    ?? "#F5DCEB"
        self.isDarkMode        = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.font              = UserDefaults.standard.string(forKey: "font")              ?? "System"
    }

    // MARK: - Persistence

    private func saveTheme() {
        UserDefaults.standard.set(primaryColorHex,   forKey: "primaryColorHex")
        UserDefaults.standard.set(secondaryColorHex, forKey: "secondaryColorHex")
        UserDefaults.standard.set(accentColorHex,    forKey: "accentColorHex")
        UserDefaults.standard.set(isDarkMode,         forKey: "isDarkMode")
        UserDefaults.standard.set(font,               forKey: "font")
    }

    func resetToDefaults() {
        primaryColorHex   = "#6D66FF"
        secondaryColorHex = "#32B4FF"
        accentColorHex    = "#F5DCEB"
        isDarkMode        = false
        font              = "System"
    }
}

// MARK: - Theme Presets

struct ThemePreset {
    let name: String
    let primaryColorHex: String
    let secondaryColorHex: String
    let accentColorHex: String
}

extension ThemePreset {
    static let presets: [ThemePreset] = [
        ThemePreset(
            name: "Default",
            primaryColorHex:   "#6D66FF",
            secondaryColorHex: "#32B4FF",
            accentColorHex:    "#F5DCEB"
        ),
        ThemePreset(
            name: "Ocean",
            primaryColorHex:   "#5E8FFF",
            secondaryColorHex: "#00D4FF",
            accentColorHex:    "#B8E8FF"
        ),
        ThemePreset(
            name: "Sunset",
            primaryColorHex:   "#FF6B6B",
            secondaryColorHex: "#FFA500",
            accentColorHex:    "#FFD93D"
        ),
        ThemePreset(
            name: "Forest",
            primaryColorHex:   "#51CF66",
            secondaryColorHex: "#2D9E5E",
            accentColorHex:    "#C8F5D0"
        ),
        ThemePreset(
            name: "Lavender",
            primaryColorHex:   "#9775FA",
            secondaryColorHex: "#DA77F2",
            accentColorHex:    "#F3D9FA"
        ),
        ThemePreset(
            name: "Rose",
            primaryColorHex:   "#FF6BA6",
            secondaryColorHex: "#FF8CC9",
            accentColorHex:    "#FFD6E8"
        ),
        ThemePreset(
            name: "Midnight",
            primaryColorHex:   "#6C8EFF",
            secondaryColorHex: "#A78BFA",
            accentColorHex:    "#1E1E3F"
        ),
    ]
}
