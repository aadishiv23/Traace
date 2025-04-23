//
//  RouteShareCustomizer.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/22/25.
//

import Foundation
import SwiftUI
import UIKit
import PencilKit

// MARK: - Route Share Customizer View

/// A view that allows users to customize their route snapshot before sharing
struct RouteShareCustomizer: View {
    // MARK: - Properties
    
    let baseImage: UIImage
    let route: RouteInfo
    @Binding var isPresented: Bool
    @State private var customizedImage: UIImage?
    @State private var currentDrawingImage: UIImage?
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showingEmojiPicker = false
    @State private var showingTextTool = false
    @State private var showingStickerPicker = false
    @State private var selectedEmoji: String?
    @State private var textInput: String = ""
    @State private var textColor: Color = .white
    @State private var fontSize: CGFloat = 36
    @State private var isEditingText = false
    @State private var textPosition: CGPoint = .zero
    @State private var placedItems: [PlacedItem] = []
    @State private var selectedFilter: ImageFilter = .none
    
    // Current tool selection
    @State private var selectedTool: EditorTool = .draw
    
    @State private var showShareSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Main editing area
                VStack(spacing: 0) {
                    // Image canvas with items
                    GeometryReader { geometry in
                        ZStack {
                            // Base image with filter
                            Image(uiImage: baseImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .modifier(ImageFilterModifier(filter: selectedFilter))
                            
                            // Drawing canvas (only visible when drawing tool is active)
                            if selectedTool == .draw {
                                CanvasView(canvasView: $canvasView, toolPicker: $toolPicker, onSave: { image in
                                    if let image = image {
                                        self.currentDrawingImage = image
                                    }
                                })
                                .opacity(selectedTool == .draw ? 1 : 0)
                            }
                            
                            // Placed items layer
                            ForEach(placedItems) { item in
                                switch item.type {
                                case .emoji:
                                    Text(item.content)
                                        .font(.system(size: item.size))
                                        .position(item.position)
                                        .shadow(color: .black.opacity(0.5), radius: 3, x: 1, y: 1)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    if let index = placedItems.firstIndex(where: { $0.id == item.id }) {
                                                        var updatedItem = placedItems[index]
                                                        updatedItem.position = value.location
                                                        placedItems[index] = updatedItem
                                                    }
                                                }
                                        )
                                case .text:
                                    Text(item.content)
                                        .font(.system(size: item.size, weight: .bold))
                                        .foregroundColor(item.color)
                                        .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
                                        .position(item.position)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    if let index = placedItems.firstIndex(where: { $0.id == item.id }) {
                                                        var updatedItem = placedItems[index]
                                                        updatedItem.position = value.location
                                                        placedItems[index] = updatedItem
                                                    }
                                                }
                                        )
                                case .sticker:
                                    Image(item.content)
                                        .resizable()
                                        .frame(width: item.size, height: item.size)
                                        .position(item.position)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    if let index = placedItems.firstIndex(where: { $0.id == item.id }) {
                                                        var updatedItem = placedItems[index]
                                                        updatedItem.position = value.location
                                                        placedItems[index] = updatedItem
                                                    }
                                                }
                                        )
                                }
                            }
                            
                            // Active text input (when adding new text)
                            if showingTextTool && isEditingText {
                                VStack(spacing: 10) {
                                    TextField("Enter text...", text: $textInput)
                                        .font(.system(size: 20, weight: .bold))
                                        .padding()
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(10)
                                    
                                    HStack {
                                        Text("Color:")
                                        ColorPicker("", selection: $textColor)
                                            .labelsHidden()
                                        
                                        Text("Size:")
                                        Slider(value: $fontSize, in: 20...100)
                                            .frame(width: 100)
                                        
                                        Button("Add") {
                                            if !textInput.isEmpty {
                                                let centerPosition = CGPoint(
                                                    x: geometry.size.width / 2,
                                                    y: geometry.size.height / 2
                                                )
                                                let newItem = PlacedItem(
                                                    type: .text,
                                                    content: textInput,
                                                    position: centerPosition,
                                                    size: fontSize,
                                                    color: textColor
                                                )
                                                placedItems.append(newItem)
                                                textInput = ""
                                                isEditingText = false
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(width: geometry.size.width * 0.9)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(15)
                                .padding()
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
                            }
                            
                            // Emoji picker overlay
                            if showingEmojiPicker {
                                VStack {
                                    Text("Select an Emoji")
                                        .font(.headline)
                                        .padding(.top)
                                    
                                    ScrollView {
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8)) {
                                            ForEach(commonEmojis, id: \.self) { emoji in
                                                Button(action: {
                                                    let centerPosition = CGPoint(
                                                        x: geometry.size.width / 2,
                                                        y: geometry.size.height / 2
                                                    )
                                                    let newItem = PlacedItem(
                                                        type: .emoji,
                                                        content: emoji,
                                                        position: centerPosition,
                                                        size: 60
                                                    )
                                                    placedItems.append(newItem)
                                                    showingEmojiPicker = false
                                                }) {
                                                    Text(emoji)
                                                        .font(.system(size: 32))
                                                        .frame(width: 44, height: 44)
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 200)
                                    
                                    Button("Cancel") {
                                        showingEmojiPicker = false
                                    }
                                    .padding(.bottom)
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(15)
                                .shadow(radius: 10)
                                .frame(width: geometry.size.width * 0.9)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                            
                            // Sticker picker overlay
                            if showingStickerPicker {
                                VStack {
                                    Text("Select a Sticker")
                                        .font(.headline)
                                        .padding(.top)
                                    
                                    ScrollView {
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                                            ForEach(stickerNames, id: \.self) { stickerName in
                                                Button(action: {
                                                    let centerPosition = CGPoint(
                                                        x: geometry.size.width / 2,
                                                        y: geometry.size.height / 2
                                                    )
                                                    let newItem = PlacedItem(
                                                        type: .sticker,
                                                        content: stickerName,
                                                        position: centerPosition,
                                                        size: 80
                                                    )
                                                    placedItems.append(newItem)
                                                    showingStickerPicker = false
                                                }) {
                                                    Image(stickerName)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 60, height: 60)
                                                        .padding(8)
                                                }
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(10)
                                            }
                                        }
                                    }
                                    .frame(height: 200)
                                    
                                    Button("Cancel") {
                                        showingStickerPicker = false
                                    }
                                    .padding(.bottom)
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(15)
                                .shadow(radius: 10)
                                .frame(width: geometry.size.width * 0.9)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                    }
                    
                    // Bottom toolbar
                    VStack {
                        // Filter selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ImageFilter.allCases, id: \.self) { filter in
                                    FilterThumbnail(
                                        filter: filter,
                                        isSelected: filter == selectedFilter,
                                        onTap: {
                                            selectedFilter = filter
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        // Tool selector
                        HStack(spacing: 20) {
                            ForEach(EditorTool.allCases, id: \.self) { tool in
                                Button {
                                    selectedTool = tool
                                    
                                    // Handle tool-specific actions
                                    switch tool {
                                    case .draw:
                                        showingEmojiPicker = false
                                        showingTextTool = false
                                        showingStickerPicker = false
                                        toolPicker.setVisible(true, forFirstResponder: canvasView)
                                        canvasView.becomeFirstResponder()
                                    case .emoji:
                                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                                        showingEmojiPicker = true
                                        showingTextTool = false
                                        showingStickerPicker = false
                                    case .text:
                                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                                        showingEmojiPicker = false
                                        showingTextTool = true
                                        showingStickerPicker = false
                                        isEditingText = true
                                    case .sticker:
                                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                                        showingEmojiPicker = false
                                        showingTextTool = false
                                        showingStickerPicker = true
                                    case .erase:
                                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                                        showingEmojiPicker = false
                                        showingTextTool = false
                                        showingStickerPicker = false
                                        if !placedItems.isEmpty {
                                            placedItems.removeLast()
                                        }
                                    }
                                } label: {
                                    VStack {
                                        Image(systemName: tool.iconName)
                                            .font(.system(size: 22))
                                            .foregroundColor(selectedTool == tool ? .white : .gray)
                                        
                                        Text(tool.displayName)
                                            .font(.caption2)
                                            .foregroundColor(selectedTool == tool ? .white : .gray)
                                    }
                                    .frame(width: 60)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                    }
                    .background(Color.black)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        // Generate final image and share
                        let renderer = ImageRenderer(content: finalImageView)
                        renderer.scale = UIScreen.main.scale
                        if let image = renderer.uiImage {
                            customizedImage = image
                            showShareSheet = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = customizedImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    // View for final image rendering
    private var finalImageView: some View {
        GeometryReader { geometry in
            ZStack {
                // Base image with filter
                Image(uiImage: baseImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .modifier(ImageFilterModifier(filter: selectedFilter))
                
                // Drawing layer
                if let drawingImage = currentDrawingImage {
                    Image(uiImage: drawingImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                
                // Placed items layer
                ForEach(placedItems) { item in
                    switch item.type {
                    case .emoji:
                        Text(item.content)
                            .font(.system(size: item.size))
                            .position(item.position)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 1, y: 1)
                    case .text:
                        Text(item.content)
                            .font(.system(size: item.size, weight: .bold))
                            .foregroundColor(item.color)
                            .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
                            .position(item.position)
                    case .sticker:
                        Image(item.content)
                            .resizable()
                            .frame(width: item.size, height: item.size)
                            .position(item.position)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    // MARK: - Helper Constants
    
    let commonEmojis = ["😀", "😂", "🥳", "👏", "❤️", "🔥", "👍", "🏃", "🚶", "🚴", "🏃‍♀️", "⚡️", "💪", "🎯",
                       "🚀", "🌟", "🏆", "🥇", "🎖️", "💯", "🌈", "☀️", "🌄", "🏞️", "⛰️", "🌊", "🌴", "🍃"]
    
    let stickerNames = ["activity_badge", "running_shoes", "mountain_peak", "fitness_tracker", "route_marker",
                       "finish_flag", "medal_gold", "heart_rate", "water_drop", "achievement_star", "elevation_chart",
                       "compass_rose"]
}

// MARK: - Canvas View for Drawing

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    var onSave: (UIImage?) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.marker, color: .white, width: 5)
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update logic if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        
        init(_ parent: CanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Convert drawing to image when it changes
            let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            parent.onSave(image)
        }
    }
}

// MARK: - Filter Thumbnail View

struct FilterThumbnail: View {
    let filter: ImageFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Text(filter.emoji)
                    .font(.system(size: 32))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            
            Text(filter.displayName)
                .font(.caption2)
                .foregroundColor(.white)
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Image Filter Modifier

struct ImageFilterModifier: ViewModifier {
    let filter: ImageFilter
    
    func body(content: Content) -> some View {
        switch filter {
        case .none:
            content
        case .noir:
            content
                .colorMultiply(.gray)
                .contrast(1.5)
        case .vivid:
            content
                .saturation(1.5)
                .contrast(1.2)
        case .warm:
            content
                .colorMultiply(Color(red: 1.1, green: 0.9, blue: 0.8))
        case .cool:
            content
                .colorMultiply(Color(red: 0.8, green: 0.9, blue: 1.1))
        case .retro:
            content
                .colorMultiply(Color(red: 1.0, green: 0.9, blue: 0.7))
                .saturation(0.7)
                .contrast(1.1)
        }
    }
}

// MARK: - Supporting Types

/// Types of items that can be placed on the image
enum PlacedItemType {
    case emoji
    case text
    case sticker
}

/// An item placed on the image
struct PlacedItem: Identifiable {
    let id = UUID()
    let type: PlacedItemType
    let content: String
    var position: CGPoint
    var size: CGFloat
    var color: Color = .white
}

/// Available image filters
enum ImageFilter: String, CaseIterable {
    case none
    case noir
    case vivid
    case warm
    case cool
    case retro
    
    var displayName: String {
        switch self {
        case .none: return "Original"
        case .noir: return "Noir"
        case .vivid: return "Vivid"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .retro: return "Retro"
        }
    }
    
    var emoji: String {
        switch self {
        case .none: return "🔄"
        case .noir: return "🖤"
        case .vivid: return "✨"
        case .warm: return "🔥"
        case .cool: return "❄️"
        case .retro: return "📷"
        }
    }
}

/// Editor tools
enum EditorTool: String, CaseIterable {
    case draw
    case emoji
    case text
    case sticker
    case erase
    
    var displayName: String {
        switch self {
        case .draw: return "Draw"
        case .emoji: return "Emoji"
        case .text: return "Text"
        case .sticker: return "Sticker"
        case .erase: return "Undo"
        }
    }
    
    var iconName: String {
        switch self {
        case .draw: return "pencil.tip"
        case .emoji: return "face.smiling"
        case .text: return "textformat"
        case .sticker: return "square.fill.on.square.fill"
        case .erase: return "arrow.uturn.backward"
        }
    }
}
