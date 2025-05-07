//
//  DraggableResizableView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import Foundation
import SwiftUI

// DraggableResizableView.swift
import SwiftUI

struct DraggableResizableView: View {
    @Binding var decoration: DecorationModel
    @Binding var isSelected: Bool
    
    let onUpdate: (DecorationModel) -> Void
    let onTapped: () -> Void
    // onDelete is removed as it's handled by the central toolbar

    @State private var currentDragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    
    @State private var startDragPosition: CGPoint?
    // startScale and startRotation are now directly reflecting decoration.scale/rotation at gesture start

    var geometryProxy: GeometryProxy

    // Haptic generator
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        let itemContent = Group { // Content of the decoration
            switch decoration.type {
            case .text:
                Text(decoration.content)
                    .font(.custom(decoration.fontName, size: decoration.fontSize))
                    .foregroundColor(decoration.color)
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(5) // Padding so border doesn't clip text
            case .emoji:
                Text(decoration.content)
                    .font(.system(size: decoration.fontSize)) // Emojis scale well
            case .imageSticker:
                if let uiImage = decoration.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: max(50, 150 * (uiImage.size.width / uiImage.size.height)), height: 150)
                } else {
                    Image(systemName: "photo.fill") // Placeholder
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
        }

        // Determine the actual frame of the content for accurate border placement
        // This is tricky without knowing the exact rendered size beforehand.
        // For simplicity, we'll use a general padding for the border.
        // A more robust solution might usePreferenceKey to get content size.

        itemContent
            .scaleEffect(decoration.scale * currentScale)
            .rotationEffect(decoration.rotation + currentRotation)
            .position(
                x: (decoration.position.x * geometryProxy.size.width) + currentDragOffset.width,
                y: (decoration.position.y * geometryProxy.size.height) + currentDragOffset.height
            )
            .overlay(
                Group { // Selection indicator
                    if isSelected {
                        // More "Apple-like" selection: rounded rect with "handles"
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .padding(-6) // Expand border slightly outwards

                        // Simulate corner handles (small circles)
                        // This is a visual simulation; they are not interactive handles here.
                        // For truly interactive handles, each would need its own gesture recognizer.
                        ForEach(0..<4) { i in
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 10, height: 10)
                                .position(handlePosition(for: i, in: geometryProxy.size, itemScale: decoration.scale * currentScale))
                                .padding(-6) // Align with outer border
                        }
                    }
                }
            )
            .contentShape(Rectangle()) // Make the whole area tappable
            .onTapGesture {
                onTapped()
                hapticGenerator.impactOccurred()
            }
            .gesture(dragGesture)
            .gesture(isSelected ? pinchGesture.simultaneously(with: rotationGesture) : nil)
            .onChange(of: isSelected) { newValue in
                if !newValue {
                    resetGestureStates()
                }
                // No need to set startScale/startRotation here; it's done at gesture start
            }
    }
    
    // Helper to position simulated handles - this needs to account for item's actual size,
    // which is hard without PreferenceKey. This is a rough approximation.
    // A more robust approach would get the item's actual frame after layout.
    private func handlePosition(for index: Int, in containerSize: CGSize, itemScale: CGFloat) -> CGPoint {
        // Approximate item size (needs improvement for accuracy)
        let itemWidth: CGFloat = (decoration.type == .imageSticker ? 150 : 100) * itemScale
        let itemHeight: CGFloat = (decoration.type == .imageSticker ? 150 : 60) * itemScale

        let halfWidth = itemWidth / 2
        let halfHeight = itemHeight / 2
        
        // Position relative to the item's center (which is its .position point)
        switch index {
        case 0: return CGPoint(x: -halfWidth, y: -halfHeight) // Top-left
        case 1: return CGPoint(x: halfWidth, y: -halfHeight)  // Top-right
        case 2: return CGPoint(x: -halfWidth, y: halfHeight) // Bottom-left
        case 3: return CGPoint(x: halfWidth, y: halfHeight)  // Bottom-right
        default: return .zero
        }
    }


    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if startDragPosition == nil {
                    startDragPosition = value.startLocation
                    currentDragOffset = .zero // Start with zero offset from model pos
                    hapticGenerator.prepare() // Prepare haptics
                }
                currentDragOffset = CGSize(
                    width: value.location.x - (startDragPosition?.x ?? value.location.x),
                    height: value.location.y - (startDragPosition?.y ?? value.location.y)
                )
                hapticGenerator.impactOccurred(intensity: 0.5) // Subtle feedback during drag
            }
            .onEnded { value in
                let finalX = (decoration.position.x * geometryProxy.size.width) + currentDragOffset.width
                let finalY = (decoration.position.y * geometryProxy.size.height) + currentDragOffset.height

                var newDeco = decoration
                newDeco.position = CGPoint(
                    x: finalX / geometryProxy.size.width,
                    y: finalY / geometryProxy.size.height
                )
                onUpdate(newDeco)
                resetGestureStates()
                hapticGenerator.impactOccurred()
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = value // `value` is a multiplier from the gesture's start
            }
            .onEnded { value in
                var newDeco = decoration
                newDeco.scale *= value
                newDeco.scale = max(0.2, min(newDeco.scale, 5.0)) // Min/Max scale
                onUpdate(newDeco)
                resetGestureStates(keepDrag: true)
                hapticGenerator.impactOccurred()
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                currentRotation = value // `value` is an Angle from the gesture's start
            }
            .onEnded { value in
                var newDeco = decoration
                newDeco.rotation += value
                onUpdate(newDeco)
                resetGestureStates(keepDrag: true)
                hapticGenerator.impactOccurred()
            }
    }
    
    private func resetGestureStates(keepDrag: Bool = false) {
        if !keepDrag {
            currentDragOffset = .zero
            startDragPosition = nil
        }
        // These are multipliers/additives for the current gesture, reset to neutral
        currentScale = 1.0
        currentRotation = .zero
    }
}
