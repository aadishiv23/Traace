//
//  ActivityColors.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/11/25.
//

import Foundation
import SwiftUI
import HealthKit.HKWorkoutActivity

/// Constants for activity-related colors throughout the app
struct ActivityColors {
    // MARK: - Standard Colors
    
    /// Standard vibrant colors for activities
    struct Standard {
        /// Color for walking activities
        static let walking = Color.blue
        
        /// Color for running activities
        static let running = Color.red
        
        /// Color for cycling activities
        static let cycling = Color.green
    }
    
    // MARK: - Map Style Colors
    
    /// Softer, map-friendly colors for activities
    struct MapStyle {
        /// Pastel blue for walking activities
        static let walking = Color(red: 0.65, green: 0.8, blue: 0.95)
        
        /// Soft coral for running activities
        static let running = Color(red: 0.95, green: 0.6, blue: 0.55)
        
        /// Mint green for cycling activities
        static let cycling = Color(red: 0.7, green: 0.9, blue: 0.7)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate color for a given activity type
    /// - Parameters:
    ///   - type: The activity type
    ///   - style: Whether to use standard or map style colors
    /// - Returns: The color corresponding to the activity type
    static func color(for type: HKWorkoutActivityType, style: ColorStyle = .standard) -> Color {
        switch style {
        case .standard:
            switch type {
            case .walking:
                return Standard.walking
            case .running:
                return Standard.running
            case .cycling:
                return Standard.cycling
            default:
                return Color.gray
            }
        case .mapStyle:
            switch type {
            case .walking:
                return MapStyle.walking
            case .running:
                return MapStyle.running
            case .cycling:
                return MapStyle.cycling
            default:
                return Color.gray.opacity(0.7)
            }
        }
    }
}

/// Color style options for activity colors
enum ColorStyle {
    /// Vibrant standard colors
    case standard
    
    /// Softer map-friendly colors
    case mapStyle
}
