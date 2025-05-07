//
//  ShareModels.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import SwiftUI
import UIKit // For UIImage
import MapKit // For MKMapType
import HealthKit // For HKWorkoutActivityType

// Enum to define the steps in the sharing process
enum SharingStep {
    case loadingInitialSnapshot
    case previewInitial // Show base image, options: Next (to layout), Share Default
    case layoutCustomization // Choose stat layout
    case decoration // Add emojis, text
    // case finalizing // Could be added for long final render
}

// Enum for different ways stats can be laid out on the image
enum StatLayoutPreset: String, CaseIterable, Identifiable {
    case defaultCardBottom
    case minimalistTop
    case detailedSide
    case modernFloating
    case gradientOverlay
    case metricsFocus
    case elegantCorner
    case infographicStyle
    // case noStats // Option to have no stats overlay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultCardBottom: "Info Card"
        case .minimalistTop: "Minimalist Top"
        case .detailedSide: "Detailed Side"
        case .modernFloating: "Modern Floating"
        case .gradientOverlay: "Gradient Overlay"
        case .metricsFocus: "Metrics Focus"
        case .elegantCorner: "Elegant Corner"
        case .infographicStyle: "Infographic Style"
        // case .noStats: "No Stats"
        }
    }

    // You could add a small preview icon name for each preset
    var previewIconName: String {
        switch self {
        case .defaultCardBottom: "doc.richtext"
        case .minimalistTop: "text.aligntop"
        case .detailedSide: "text.alignleading"
        case .modernFloating: "rectangle.on.rectangle"
        case .gradientOverlay: "rectangle.fill.on.rectangle.fill"
        case .metricsFocus: "chart.bar.fill"
        case .elegantCorner: "square.tophalf.filled"
        case .infographicStyle: "chart.xyaxis.line"
        // case .noStats: "eye.slash"
        }
    }
    
    // Description of each preset for better UX
    var description: String {
        switch self {
        case .defaultCardBottom: "Clean footer card with route information"
        case .minimalistTop: "Subtle header with essential stats"
        case .detailedSide: "Detailed side panel with full metrics"
        case .modernFloating: "Modern floating card with focus on distance"
        case .gradientOverlay: "Full screen gradient with elegant typography"
        case .metricsFocus: "Bold focus on your key metrics"
        case .elegantCorner: "Elegant corner card with minimal interference"
        case .infographicStyle: "Data visualization style with graphic elements"
        }
    }
}

// Model for a single decoration item (text, emoji, sticker, image)
struct DecorationModel: Identifiable, Equatable {
    let id = UUID()
    var type: DecorationType
    var content: String // For text or emoji character, or image name/URL
    var uiImage: UIImage? // For photo sticker
    var position: CGPoint = .zero // Relative to image size (0,0 to 1,1) or absolute
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var color: Color = .white // For text
    var fontName: String = "HelveticaNeue-Bold" // For text
    var fontSize: CGFloat = 30 // Relative to a base size

    enum DecorationType {
        case text, emoji, imageSticker
    }

    // Initial position often center of the image
    init(type: DecorationType, content: String = "", uiImage: UIImage? = nil, initialPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        self.type = type
        self.content = content
        self.uiImage = uiImage
        self.position = initialPosition
        if type == .emoji {
            self.fontSize = 60 // Emojis are often larger
        }
    }
}
