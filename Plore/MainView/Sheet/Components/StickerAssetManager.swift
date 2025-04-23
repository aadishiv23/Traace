//
//  StickerAssetManager.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/22/25.
//

import Foundation
// MARK: - Sticker Asset Management

/// Manages the app's sticker assets
struct StickerAssetManager {
    /// The available sticker categories
    enum StickerCategory: String, CaseIterable {
        case achievements
        case activity
        case elements
        case miscellaneous
        
        var displayName: String {
            switch self {
            case .achievements: return "Achievements"
            case .activity: return "Activity"
            case .elements: return "Elements"
            case .miscellaneous: return "Misc"
            }
        }
    }
    
    /// Returns the stickers for a given category
    static func stickers(for category: StickerCategory) -> [StickerAsset] {
        switch category {
        case .achievements:
            return [
                StickerAsset(name: "medal_gold", displayName: "Gold Medal"),
                StickerAsset(name: "medal_silver", displayName: "Silver Medal"),
                StickerAsset(name: "medal_bronze", displayName: "Bronze Medal"),
                StickerAsset(name: "trophy", displayName: "Trophy"),
                StickerAsset(name: "achievement_star", displayName: "Achievement Star"),
                StickerAsset(name: "finish_flag", displayName: "Finish Flag"),
                StickerAsset(name: "podium", displayName: "Podium")
            ]
        case .activity:
            return [
                StickerAsset(name: "activity_badge", displayName: "Activity Badge"),
                StickerAsset(name: "running_shoes", displayName: "Running Shoes"),
                StickerAsset(name: "fitness_tracker", displayName: "Fitness Tracker"),
                StickerAsset(name: "water_bottle", displayName: "Water Bottle"),
                StickerAsset(name: "heart_rate", displayName: "Heart Rate"),
                StickerAsset(name: "stopwatch", displayName: "Stopwatch"),
                StickerAsset(name: "energy_bolt", displayName: "Energy Bolt")
            ]
        case .elements:
            return [
                StickerAsset(name: "mountain_peak", displayName: "Mountain Peak"),
                StickerAsset(name: "route_marker", displayName: "Route Marker"),
                StickerAsset(name: "compass_rose", displayName: "Compass Rose"),
                StickerAsset(name: "elevation_chart", displayName: "Elevation Chart"),
                StickerAsset(name: "water_drop", displayName: "Water Drop"),
                StickerAsset(name: "sun_rays", displayName: "Sun Rays"),
                StickerAsset(name: "forest", displayName: "Forest")
            ]
        case .miscellaneous:
            return [
                StickerAsset(name: "speech_bubble", displayName: "Speech Bubble"),
                StickerAsset(name: "thought_bubble", displayName: "Thought Bubble"),
                StickerAsset(name: "thumbs_up", displayName: "Thumbs Up"),
                StickerAsset(name: "fire", displayName: "Fire"),
                StickerAsset(name: "star_burst", displayName: "Star Burst"),
                StickerAsset(name: "arrow", displayName: "Arrow"),
                StickerAsset(name: "spark", displayName: "Spark")
            ]
        }
    }
    
    /// Returns all sticker assets
    static var allStickers: [StickerAsset] {
        StickerCategory.allCases.flatMap { stickers(for: $0) }
    }
}

/// Represents a sticker asset
struct StickerAsset: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
}

// MARK: - Sticker UI Components

/// A sticker category selector view
struct StickerCategorySelector: View {
    @Binding var selectedCategory: StickerAssetManager.StickerCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(StickerAssetManager.StickerCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == category ? Color.white : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(selectedCategory == category ? Color.black : Color.white)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

/// A grid of stickers for selection
struct StickerGrid: View {
    let stickers: [StickerAsset]
    let onSelectSticker: (StickerAsset) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                ForEach(stickers) { sticker in
                    Button {
                        onSelectSticker(sticker)
                    } label: {
                        VStack {
                            Image(sticker.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                            
                            Text(sticker.displayName)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Sample Sticker Asset

/// This is a placeholder for actual image assets. In a real app, you would use actual images in your Assets.xcassets.
/// Here's an implementation of a SwiftUI View that generates placeholder stickers programmatically.

import SwiftUI

struct StickerPlaceholder: View {
    let name: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .overlay(
                    Circle()
                        .strokeBorder(color, lineWidth: 3)
                )
            
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
    }
    
    private var iconName: String {
        switch name {
        case "medal_gold": return "medal"
        case "medal_silver": return "medal"
        case "medal_bronze": return "medal"
        case "trophy": return "trophy"
        case "achievement_star": return "star.fill"
        case "finish_flag": return "flag.fill"
        case "podium": return "square.3.stack.3d"
            
        case "activity_badge": return "figure.run"
        case "running_shoes": return "shoe"
        case "fitness_tracker": return "applewatch"
        case "water_bottle": return "drop.fill"
        case "heart_rate": return "heart.fill"
        case "stopwatch": return "stopwatch"
        case "energy_bolt": return "bolt.fill"
            
        case "mountain_peak": return "mountain.2"
        case "route_marker": return "mappin"
        case "compass_rose": return "location.north.fill"
        case "elevation_chart": return "chart.bar"
        case "water_drop": return "drop.fill"
        case "sun_rays": return "sun.max.fill"
        case "forest": return "leaf.fill"
            
        case "speech_bubble": return "message"
        case "thought_bubble": return "bubble.right"
        case "thumbs_up": return "hand.thumbsup.fill"
        case "fire": return "flame.fill"
        case "star_burst": return "sparkles"
        case "arrow": return "arrow.right"
        case "spark": return "sparkle"
            
        default: return "questionmark"
        }
    }
}

// MARK: - Preview

struct StickerPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                StickerPlaceholder(name: "medal_gold", color: .yellow)
                StickerPlaceholder(name: "achievement_star", color: .orange)
                StickerPlaceholder(name: "finish_flag", color: .red)
            }
            .frame(height: 80)
            
            HStack {
                StickerPlaceholder(name: "activity_badge", color: .blue)
                StickerPlaceholder(name: "running_shoes", color: .green)
                StickerPlaceholder(name: "heart_rate", color: .pink)
            }
            .frame(height: 80)
            
            HStack {
                StickerPlaceholder(name: "mountain_peak", color: .brown)
                StickerPlaceholder(name: "compass_rose", color: .cyan)
                StickerPlaceholder(name: "forest", color: .green)
            }
            .frame(height: 80)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Extension to Create an Image from a View

extension View {
    /// Converts a SwiftUI view to a UIImage
    func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // Set the controller view size
        controller.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // Create an image renderer with the same size as the view
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Extension to Use Programmatic Stickers

extension Image {
    /// Creates a programmatic sticker image from a name
    static func sticker(_ name: String) -> Image {
        // Determine color based on sticker category
        let color: Color
        
        if name.contains("medal") || name.contains("trophy") || name.contains("achievement") {
            color = .yellow
        } else if name.contains("activity") || name.contains("running") || name.contains("fitness") {
            color = .blue
        } else if name.contains("mountain") || name.contains("forest") || name.contains("nature") {
            color = .green
        } else if name.contains("heart") || name.contains("energy") {
            color = .red
        } else {
            color = .purple
        }
        
        // Create the sticker placeholder and convert to UIImage
        let stickerView = StickerPlaceholder(name: name, color: color)
        let uiImage = stickerView.asUIImage()
        
        // Return as SwiftUI Image
        return Image(uiImage: uiImage)
    }
}
