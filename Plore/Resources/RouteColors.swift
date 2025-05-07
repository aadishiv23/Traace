//
//  RouteColors.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/19/25.
//

import SwiftUI
import HealthKit.HKWorkoutActivity

/// Enum representing different color themes for route polylines
enum RouteColorTheme: String, CaseIterable, Codable {
    case `default` // Standard SwiftUI colors
    case vibrant
    case pastel
    case night
    case earth
    case custom // Added custom case for user-defined colors
}

/// Centralized color palette for route polylines
enum RouteColors {
    static func colors(for theme: RouteColorTheme) -> (walking: Color, running: Color, cycling: Color) {
        switch theme {
        case .default:
            // Standard SwiftUI colors
            (walking: .blue, running: .red, cycling: .green)
        case .vibrant:
            (walking: Color(hex: "#00B4FF"), running: Color(hex: "#FF4B4B"), cycling: Color(hex: "#4BFF7A"))
        case .pastel:
            (walking: Color(hex: "#A3D8F4"), running: Color(hex: "#FFB3B3"), cycling: Color(hex: "#B3FFCB"))
        case .night:
            (walking: Color(hex: "#4A90E2"), running: Color(hex: "#D0021B"), cycling: Color(hex: "#417505"))
        case .earth:
            (walking: Color(hex: "#8D8741"), running: Color(hex: "#659DBD"), cycling: Color(hex: "#DAAD86"))
        case .custom:
            // Retrieve custom colors from UserDefaults
            (
                walking: Color(hex: UserDefaults.standard.string(forKey: "customWalkingColor") ?? "#00B4FF"),
                running: Color(hex: UserDefaults.standard.string(forKey: "customRunningColor") ?? "#FF4B4B"),
                cycling: Color(hex: UserDefaults.standard.string(forKey: "customCyclingColor") ?? "#4BFF7A")
            )
        }
    }

    /// NEW METHOD: Get specific color for activity type and theme
    static func color2(for type: HKWorkoutActivityType, theme: RouteColorTheme) -> Color {
        let themeColors = colors(for: theme) // Get the tuple of colors for the theme
        switch type {
        case .walking:
            return themeColors.walking
        case .running:
            return themeColors.running
        case .cycling:
            return themeColors.cycling
        default:
            // Return a default color for other activity types or the 'default' theme's walking color
            return colors(for: .default).walking // Or .gray, or any other fallback
        }
    }

    /// Save custom colors to UserDefaults
    static func saveCustomColors(walking: Color, running: Color, cycling: Color) {
        UserDefaults.standard.set(walking.toHex(), forKey: "customWalkingColor")
        UserDefaults.standard.set(running.toHex(), forKey: "customRunningColor")
        UserDefaults.standard.set(cycling.toHex(), forKey: "customCyclingColor")
    }
}

extension Color {
    /// Initialize Color from a hex string (e.g. "#FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Convert Color to hex string
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = components[0]
        let g = components[1]
        let b = components[2]

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
