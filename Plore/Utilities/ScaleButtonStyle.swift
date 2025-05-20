//
//  ScaleButtonStyle.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/20/25.
//

import Foundation
import SwiftUI

/// A custom button style that scales the button slightly when pressed
/// for a satisfying tactile feel.
struct ScaleButtonStyle: ButtonStyle {
    /// The amount to scale down when pressed (default is 0.96)
    var scaleFactor: CGFloat = 0.96

    /// The animation duration for the press effect (default is 0.2 seconds)
    var duration: Double = 0.2

    /// The animation damping for the press effect (default is 0.7)
    var dampingFraction: Double = 0.7

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleFactor : 1)
            .animation(.spring(response: duration, dampingFraction: dampingFraction), value: configuration.isPressed)
    }
}

// MARK: - Usage Examples

extension ScaleButtonStyle {
    /// A subtle scale effect
    static var subtle: ScaleButtonStyle {
        ScaleButtonStyle(scaleFactor: 0.98, duration: 0.15, dampingFraction: 0.8)
    }

    /// A more pronounced scale effect
    static var pronounced: ScaleButtonStyle {
        ScaleButtonStyle(scaleFactor: 0.92, duration: 0.25, dampingFraction: 0.6)
    }
}

// MARK: - View Extension

extension View {
    /// Apply the scale button style with custom parameters
    /// - Parameters:
    ///   - scaleFactor: The amount to scale down when pressed
    ///   - duration: The animation duration for the press effect
    ///   - dampingFraction: The animation damping for the press effect
    /// - Returns: A view with the scale button style applied
    func scaleButtonStyle(
        scaleFactor: CGFloat = 0.96,
        duration: Double = 0.2,
        dampingFraction: Double = 0.7
    ) -> some View {
        buttonStyle(ScaleButtonStyle(
            scaleFactor: scaleFactor,
            duration: duration,
            dampingFraction: dampingFraction
        ))
    }
}
