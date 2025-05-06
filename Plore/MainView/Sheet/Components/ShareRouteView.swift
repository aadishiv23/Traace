//
//  ShareRouteView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/5/25.
//

import Foundation
import SwiftUI
import UIKit
import MapKit
import HealthKit

/// A multi-step sharing flow for route sharing with customization options
struct ShareRouteView: View {
    // MARK: - Properties
    
    let route: RouteInfo
    let initialImage: UIImage
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.routeColorTheme) private var routeColorTheme
    
    @State private var currentStep: ShareStep = .layout
    @State private var selectedTemplate: ShareTemplate = .standard
    @State private var customizations = ShareCustomizations()
    @State private var finalImage: UIImage?
    @State private var drawingItems: [DrawingItem] = []
    @State private var isGeneratingImage = false
    @State private var showStickers = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Preview of the share
                    previewSection
                    
                    // Bottom section with controls
                    bottomSection
                }
            }
            .navigationTitle(currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if currentStep == .decoration {
                            shareImage()
                        } else {
                            withAnimation {
                                currentStep = .decoration
                            }
                        }
                    } label: {
                        Text(currentStep == .decoration ? "Share" : "Next")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showStickers) {
                StickerPickerView { sticker in
                    let newItem = DrawingItem(
                        type: .sticker,
                        position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3),
                        content: sticker,
                        scale: 1.0,
                        rotation: 0.0
                    )
                    drawingItems.append(newItem)
                    showStickers = false
                }
            }
            .overlay {
                if isGeneratingImage {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Preparing your image...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.systemBackground).opacity(0.9))
                                .shadow(color: Color.black.opacity(0.2), radius: 15)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    /// Preview section showing the current share image
    private var previewSection: some View {
        GeometryReader { geometry in
            ZStack {
                Color(UIColor.systemBackground)
                
                if let finalImage {
                    Image(uiImage: finalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.1), radius: 8)
                        .padding()
                        .overlay {
                            if currentStep == .decoration {
                                // Canvas where users can add items
                                DecorationCanvas(items: $drawingItems)
                            }
                        }
                } else {
                    // Show a loading indicator while the image is being generated
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading preview...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                }
            }
            .onAppear {
                if finalImage == nil {
                    generateImage()
                }
            }
        }
    }
    
    /// Bottom section with controls based on the current step
    private var bottomSection: some View {
        VStack {
            // Separator line
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 0.5)
            
            // Controls that change based on the current step
            switch currentStep {
            case .layout:
                layoutControls
            case .decoration:
                decorationControls
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    /// Controls for the layout selection step
    private var layoutControls: some View {
        VStack(spacing: 20) {
            Text("Choose a Template")
                .font(.headline)
                .padding(.top, 20)
            
            // Template picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(ShareTemplate.allCases, id: \.self) { template in
                        TemplateButton(
                            template: template,
                            isSelected: selectedTemplate == template,
                            routeType: route.type,
                            routeColorTheme: routeColorTheme
                        ) {
                            selectedTemplate = template
                            generateImage()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
            
            // Customization options
            VStack(spacing: 15) {
                Toggle("Show Route Name", isOn: $customizations.showRouteName)
                    .onChange(of: customizations.showRouteName) { _ in generateImage() }
                
                Toggle("Show Distance", isOn: $customizations.showDistance)
                    .onChange(of: customizations.showDistance) { _ in generateImage() }
                
                Toggle("Show Date", isOn: $customizations.showDate)
                    .onChange(of: customizations.showDate) { _ in generateImage() }
                
                Toggle("Show App Branding", isOn: $customizations.showBranding)
                    .onChange(of: customizations.showBranding) { _ in generateImage() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    /// Controls for the decoration step
    private var decorationControls: some View {
        VStack(spacing: 0) {
            // Tools header
            Text("Customize Your Share")
                .font(.headline)
                .padding(.top, 15)
                .padding(.bottom, 10)
            
            // Tools in a horizontal scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Text tool
                    ToolButton(title: "Text", systemName: "textformat") {
                        let newItem = DrawingItem(
                            type: .text,
                            position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3),
                            content: "Tap to edit",
                            scale: 1.0,
                            rotation: 0.0
                        )
                        drawingItems.append(newItem)
                    }
                    
                    // Emoji tool
                    ToolButton(title: "Emoji", systemName: "face.smiling") {
                        let newItem = DrawingItem(
                            type: .emoji,
                            position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3),
                            content: "🏃‍♂️",
                            scale: 1.0,
                            rotation: 0.0
                        )
                        drawingItems.append(newItem)
                    }
                    
                    // Stickers tool
                    ToolButton(title: "Stickers", systemName: "square.fill.on.square.fill") {
                        showStickers = true
                    }
                    
                    // Drawing tool
                    ToolButton(title: "Draw", systemName: "pencil.tip") {
                        // Enable drawing mode
                    }
                    
                    // Clear all tool
                    ToolButton(title: "Clear All", systemName: "trash") {
                        drawingItems.removeAll()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generates the share image based on current template and customizations
    private func generateImage() {
        isGeneratingImage = true
        
        // Get the route color
        let routeColor = routeTypeColor(for: route.type)
        
        // Convert to UIColor
        let routeUIColor = UIColor(routeColor)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Generate the base image
            var generatedImage: UIImage?
            
            switch selectedTemplate {
            case .standard:
                generatedImage = ShareImageRenderer.createStandardTemplate(
                    baseImage: initialImage,
                    route: route,
                    routeColor: routeUIColor,
                    customizations: customizations
                )
            case .minimal:
                generatedImage = ShareImageRenderer.createMinimalTemplate(
                    baseImage: initialImage,
                    route: route,
                    routeColor: routeUIColor,
                    customizations: customizations
                )
            case .statistics:
                generatedImage = ShareImageRenderer.createStatisticsTemplate(
                    baseImage: initialImage,
                    route: route,
                    routeColor: routeUIColor,
                    customizations: customizations
                )
            case .vintage:
                generatedImage = ShareImageRenderer.createVintageTemplate(
                    baseImage: initialImage,
                    route: route,
                    routeColor: routeUIColor,
                    customizations: customizations
                )
            case .dark:
                generatedImage = ShareImageRenderer.createDarkTemplate(
                    baseImage: initialImage,
                    route: route,
                    routeColor: routeUIColor,
                    customizations: customizations
                )
            }
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                finalImage = generatedImage
                isGeneratingImage = false
            }
        }
    }
    
    /// Shares the final image with decorations
    private func shareImage() {
        isGeneratingImage = true
        
        // Render the final image with decorations
        DispatchQueue.main.async {
            let renderer = ImageRenderer(content:
                ZStack {
                    if let finalImage {
                        Image(uiImage: finalImage)
                            .resizable()
                            .scaledToFit()
                    }
                    
                    // Render decoration items
                    ForEach(drawingItems.indices, id: \.self) { index in
                        DecorationItemView(item: drawingItems[index])
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.5)
                .background(Color.clear)
            )
            
            if let renderedImage = renderer.uiImage {
                DispatchQueue.main.async {
                    isGeneratingImage = false
                    
                    // Show share sheet with the final image
                    let activityVC = UIActivityViewController(
                        activityItems: [renderedImage],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true)
                    }
                    
                    // Dismiss this view after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isGeneratingImage = false
                }
            }
        }
    }
    
    /// Returns the color for a route type
    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        let colors = RouteColors.colors(for: routeColorTheme)
        switch type {
        case .walking: return colors.walking
        case .running: return colors.running
        case .cycling: return colors.cycling
        default: return .gray
        }
    }
}

// MARK: - Supporting Types

/// Enum representing the different steps in the share flow
enum ShareStep {
    case layout
    case decoration
    
    var title: String {
        switch self {
        case .layout: return "Choose Layout"
        case .decoration: return "Add Graphics"
        }
    }
}

/// Enum representing the different share templates
enum ShareTemplate: String, CaseIterable {
    case standard = "Standard"
    case minimal = "Minimal"
    case statistics = "Stats"
    case vintage = "Vintage"
    case dark = "Dark Mode"
    
    var previewIcon: String {
        switch self {
        case .standard: return "square.grid.2x2"
        case .minimal: return "rectangle.compress.vertical"
        case .statistics: return "chart.bar"
        case .vintage: return "camera.filters"
        case .dark: return "moon.stars"
        }
    }
}

/// Structure to hold customization options
struct ShareCustomizations {
    var showRouteName: Bool = true
    var showDistance: Bool = true
    var showDate: Bool = true
    var showBranding: Bool = true
}

/// Enum representing the different types of drawing items
enum DrawingItemType {
    case text
    case emoji
    case sticker
    case drawing
}

/// Structure representing a decorative item added to the share
struct DrawingItem: Identifiable {
    let id = UUID()
    var type: DrawingItemType
    var position: CGPoint
    var content: String
    var scale: CGFloat
    var rotation: CGFloat
}

// MARK: - Supporting Views

/// Button for selecting a template
struct TemplateButton: View {
    let template: ShareTemplate
    let isSelected: Bool
    let routeType: HKWorkoutActivityType
    let routeColorTheme: RouteColorTheme
    let action: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? routeTypeColor(for: routeType) : Color(UIColor.secondarySystemBackground))
                    .frame(width: 80, height: 80)
                    .shadow(color: isSelected ? routeTypeColor(for: routeType).opacity(0.4) : Color.clear, radius: 8)
                
                Image(systemName: template.previewIcon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : routeTypeColor(for: routeType))
            }
            
            Text(template.rawValue)
                .font(.caption)
                .foregroundColor(isSelected ? routeTypeColor(for: routeType) : .primary)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }
    }
    
    /// Returns the color for a route type
    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        let colors = RouteColors.colors(for: routeColorTheme)
        switch type {
        case .walking: return colors.walking
        case .running: return colors.running
        case .cycling: return colors.cycling
        default: return .gray
        }
    }
}

/// Button for decoration tools
struct ToolButton: View {
    let title: String
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Button {
                action()
            } label: {
                Image(systemName: systemName)
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Canvas for adding decorative items to the share
struct DecorationCanvas: View {
    @Binding var items: [DrawingItem]
    
    var body: some View {
        ZStack {
            Color.clear
            
            ForEach(items.indices, id: \.self) { index in
                DecorationItemView(item: items[index])
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                items[index].position = value.location
                            }
                    )
                    .onTapGesture {
                        // Handle tap (e.g., edit text, show controls)
                    }
            }
        }
    }
}

///// View for rendering a single decoration item
//struct DecorationItemView: View {
//    let item: DrawingItem
//    
//    var body: some View {
//        ZStack {
//            switch item.type {
//            case .text:
//                Text(item.content)
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                    .shadow(color: .black.opacity(0.5), radius: 3, x: 1, y: 1)
//                
//            case .emoji:
//                Text(item.content)
//                    .font(.system(size: 60))
//                
//            case .sticker:
//                // Placeholder for sticker image
//                if let sticker = StickersProvider.getSticker(id: item.content) {
//                    Image(uiImage: sticker)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 80, height: 80)
//                } else {
//                    Image(systemName: "star.fill")
//                        .font(.system(size: 40))
//                        .foregroundColor(.yellow)
//                }
//                
//            case .drawing:
//                // Drawing path would be implemented here
//                EmptyView()
//            }
//        }
//        .position(item.position)
//        .scaleEffect(item.scale)
//        .rotationEffect(.degrees(item.rotation))
//    }
//}

/// View for picking stickers
struct StickerPickerView: View {
    let onStickerSelected: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                    ForEach(StickersProvider.allStickers, id: \.self) { stickerId in
                        Button {
                            onStickerSelected(stickerId)
                        } label: {
                            if let sticker = StickersProvider.getSticker(id: stickerId) {
                                Image(uiImage: sticker)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose a Sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onStickerSelected("")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct ShareRouteView_Previews: PreviewProvider {
    static var previews: some View {
        ShareRouteView(
            route: mockRouteInfo,
            initialImage: UIImage(systemName: "map")!
        )
    }
    
    static var mockRouteInfo: RouteInfo {
        let locations = stride(from: 0.0, to: 0.01, by: 0.001).map {
            CLLocation(latitude: 37.7749 + $0, longitude: -122.4194 + $0)
        }
        
        let coordinates = locations.map(\.coordinate)
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        
        return RouteInfo(
            id: UUID(),
            name: "Golden Gate Jog",
            type: .running,
            date: Date(),
            locations: locations
        )
    }
}
