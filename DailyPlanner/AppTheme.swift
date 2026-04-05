// AppTheme.swift
// DailyPlanner
//
// Data model for app theme customization.

import SwiftUI

@Observable
final class AppTheme {
    static let shared = AppTheme()

    var primaryColorHex: String {
        didSet {
            saveTheme()
        }
    }

    var secondaryColorHex: String {
        didSet {
            saveTheme()
        }
    }

    var accentColorHex: String {
        didSet {
            saveTheme()
        }
    }

    var isDarkMode: Bool {
        didSet {
            saveTheme()
        }
    }

    var font: String {
        didSet {
            saveTheme()
        }
    }

    // MARK: - Initialization

    init() {
        self.primaryColorHex = UserDefaults.standard.string(forKey: "primaryColorHex") ?? "#5E8FFF"
        self.secondaryColorHex = UserDefaults.standard.string(forKey: "secondaryColorHex") ?? "#51CF66"
        self.accentColorHex = UserDefaults.standard.string(forKey: "accentColorHex") ?? "#FF6B6B"
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.font = UserDefaults.standard.string(forKey: "font") ?? "System"
    }

    // MARK: - Methods

    private func saveTheme() {
        UserDefaults.standard.set(primaryColorHex, forKey: "primaryColorHex")
        UserDefaults.standard.set(secondaryColorHex, forKey: "secondaryColorHex")
        UserDefaults.standard.set(accentColorHex, forKey: "accentColorHex")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(font, forKey: "font")
    }

    func resetToDefaults() {
        primaryColorHex = "#5E8FFF"
        secondaryColorHex = "#51CF66"
        accentColorHex = "#FF6B6B"
        isDarkMode = false
        font = "System"
    }
}

// Theme presets
struct ThemePreset {
    let name: String
    let primaryColorHex: String
    let secondaryColorHex: String
    let accentColorHex: String
}

extension ThemePreset {
    static let presets: [ThemePreset] = [
        ThemePreset(
            name: "Ocean",
            primaryColorHex: "#5E8FFF",
            secondaryColorHex: "#00D4FF",
            accentColorHex: "#0099FF"
        ),
        ThemePreset(
            name: "Sunset",
            primaryColorHex: "#FF6B6B",
            secondaryColorHex: "#FFA500",
            accentColorHex: "#FFD93D"
        ),
        ThemePreset(
            name: "Forest",
            primaryColorHex: "#51CF66",
            secondaryColorHex: "#2D7D2D",
            accentColorHex: "#1B4620"
        ),
        ThemePreset(
            name: "Lavender",
            primaryColorHex: "#9775FA",
            secondaryColorHex: "#DA77F2",
            accentColorHex: "#E599F7"
        ),
        ThemePreset(
            name: "Rose",
            primaryColorHex: "#FF8CC9",
            secondaryColorHex: "#FF6BA6",
            accentColorHex: "#FB5899"
        ),
        ThemePreset(
            name: "Midnight",
            primaryColorHex: "#1A1A2E",
            secondaryColorHex: "#16213E",
            accentColorHex: "#0F3460"
        ),
    ]
}
