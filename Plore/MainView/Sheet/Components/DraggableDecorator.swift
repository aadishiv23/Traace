//
//  DraggableDecorator.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/5/25.
//

import Foundation
import SwiftUI

/// A view wrapper that makes any view draggable, resizable, and rotatable
struct DraggableDecorator<Content: View>: View {
    // MARK: - Properties
    
    /// The content view to make interactive
    private let content: Content
    
    /// Binding to the item's position
    @Binding var position: CGPoint
    
    /// Binding to the item's scale
    @Binding var scale: CGFloat
    
    /// Binding to the item's rotation in degrees
    @Binding var rotation: CGFloat
    
    /// Whether the item is selected
    @Binding var isSelected: Bool
    
    /// Minimum allowed scale
    private let minScale: CGFloat = 0.5
    
    /// Maximum allowed scale
    private let maxScale: CGFloat = 3.0
    
    /// State to track the drag operation
    @GestureState private var dragState = CGSize.zero
    
    /// State to track the scale operation
    @GestureState private var scaleState: CGFloat = 1.0
    
    /// State to track the rotation operation
    @GestureState private var rotationState: Angle = .zero
    
    // MARK: - Initialization
    
    init(content: Content, position: Binding<CGPoint>, scale: Binding<CGFloat>, rotation: Binding<CGFloat>, isSelected: Binding<Bool>) {
        self.content = content
        self._position = position
        self._scale = scale
        self._rotation = rotation
        self._isSelected = isSelected
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // The content
            content
                .scaleEffect(scale * scaleState)
            
            // Show controls if selected
            if isSelected {
                // Resize handle
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 2)
                    .offset(x: 30, y: 30)
                    .gesture(
                        DragGesture()
                            .updating($scaleState) { value, state, _ in
                                let startingDistance = sqrt(pow(30, 2) + pow(30, 2))
                                let currentDistance = sqrt(
                                    pow(value.location.x - 30, 2) +
                                    pow(value.location.y - 30, 2)
                                )
                                let ratio = currentDistance / startingDistance
                                state = ratio
                            }
                            .onEnded { value in
                                let startingDistance = sqrt(pow(30, 2) + pow(30, 2))
                                let currentDistance = sqrt(
                                    pow(value.location.x - 30, 2) +
                                    pow(value.location.y - 30, 2)
                                )
                                let ratio = currentDistance / startingDistance
                                scale = min(max(scale * ratio, minScale), maxScale)
                            }
                    )
                
                // Rotation handle
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 2)
                    .offset(x: -30, y: 30)
                    .gesture(
                        DragGesture()
                            .updating($rotationState) { value, state, _ in
                                let center = CGPoint(x: 0, y: 0)
                                let startVector = CGPoint(x: -30, y: 30)
                                let currentVector = CGPoint(
                                    x: value.location.x,
                                    y: value.location.y
                                )
                                
                                let startAngle = atan2(startVector.y - center.y, startVector.x - center.x)
                                let currentAngle = atan2(currentVector.y - center.y, currentVector.x - center.x)
                                
                                state = Angle(radians: Double(currentAngle - startAngle))
                            }
                            .onEnded { value in
                                let center = CGPoint(x: 0, y: 0)
                                let startVector = CGPoint(x: -30, y: 30)
                                let currentVector = CGPoint(
                                    x: value.location.x,
                                    y: value.location.y
                                )
                                
                                let startAngle = atan2(startVector.y - center.y, startVector.x - center.x)
                                let currentAngle = atan2(currentVector.y - center.y, currentVector.x - center.x)
                                
                                let angleDiff = currentAngle - startAngle
                                rotation += CGFloat(angleDiff * 180 / .pi)
                            }
                    )
                
                // Delete button
                Button {
                    // This would call the delete action
                    // We'll implement this in the parent view
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .padding(8)
                        .background(Color.white)
                        .foregroundColor(.red)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 2)
                }
                .offset(x: -30, y: -30)
                
                // Selection border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.3), radius: 2)
            }
        }
        .position(
            x: position.x + dragState.width,
            y: position.y + dragState.height
        )
        .rotationEffect(.degrees(rotation) + rotationState)
        .gesture(
            DragGesture()
                .updating($dragState) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    position.x += value.translation.width
                    position.y += value.translation.height
                    isSelected = true
                }
        )
        .onTapGesture {
            isSelected = true
        }
    }
}

/// An decorator item that can be moved, scaled and rotated
struct DecorationItemView: View {
    // MARK: - Properties
    
    /// The item being decorated
    let item: DrawingItem
    
    /// Whether the delete button was tapped
    @State private var shouldDelete = false
    
    /// Whether the item is selected
    @State private var isSelected = false
    
    /// Mutable position state
    @State private var position: CGPoint
    
    /// Mutable scale state
    @State private var scale: CGFloat
    
    /// Mutable rotation state in degrees
    @State private var rotation: CGFloat
    
    // MARK: - Initialization
    
    init(item: DrawingItem, onDelete: (() -> Void)? = nil) {
        self.item = item
        self._position = State(initialValue: item.position)
        self._scale = State(initialValue: item.scale)
        self._rotation = State(initialValue: item.rotation)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            // Different content based on item type
            switch item.type {
            case .text:
                DraggableDecorator(
                    content: Text(item.content)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 1, y: 1),
                    position: $position,
                    scale: $scale,
                    rotation: $rotation,
                    isSelected: $isSelected
                )
                
            case .emoji:
                DraggableDecorator(
                    content: Text(item.content)
                        .font(.system(size: 60)),
                    position: $position,
                    scale: $scale,
                    rotation: $rotation,
                    isSelected: $isSelected
                )
                
            case .sticker:
                if let sticker = StickersProvider.getSticker(id: item.content) {
                    DraggableDecorator(
                        content: Image(uiImage: sticker)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80),
                        position: $position,
                        scale: $scale,
                        rotation: $rotation,
                        isSelected: $isSelected
                    )
                } else {
                    // Fallback for missing stickers
                    DraggableDecorator(
                        content: Image(systemName: "star.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow),
                        position: $position,
                        scale: $scale,
                        rotation: $rotation,
                        isSelected: $isSelected
                    )
                }
                
            case .drawing:
                // Drawing would be a custom path
                EmptyView()
            }
        }
        // Tap anywhere else to deselect
        .onTapGesture(count: 2) {
            // Double tap to edit text
            if item.type == .text {
                // This would open a text editor
            }
        }
    }
}

// MARK: - Preview

struct DraggableDecorator_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            DecorationItemView(
                item: DrawingItem(
                    type: .emoji,
                    position: CGPoint(x: 200, y: 300),
                    content: "🔥",
                    scale: 1.0,
                    rotation: 0.0
                )
            )
        }
    }
}
