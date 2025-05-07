//
//  DecorationsOverlayView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import Foundation
import SwiftUI

// DecorationsOverlayView.swift

import Foundation
import SwiftUI

struct DecorationsOverlayView: View {
    @EnvironmentObject var viewModel: SharingViewModel // Access full VM for updates
    let baseImageSize: CGSize // To help with initial sizing if needed

    var body: some View {
        GeometryReader { geometry in // geometry is now available here
            ZStack {
                // Now use the extracted subview
                ForEach($viewModel.decorations) { $decoProxy in
                    SingleDecorationItemView(decoration: $decoProxy, geometry: geometry)
                        // The viewModel will be passed via environment from the parent
                        // of DecorationsOverlayView (which is DecorationStepView)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                 viewModel.selectedDecorationID = nil
            }
        }
        .clipped()
        .background(Color.clear)
    }
}

// Create this as a new struct, perhaps in the same file or a new one.
struct SingleDecorationItemView: View {
    @EnvironmentObject var viewModel: SharingViewModel
    @Binding var decoration: DecorationModel // This is the $decoProxy from ForEach
    var geometry: GeometryProxy

    var body: some View {
        DraggableResizableView(
            decoration: $decoration,
            isSelected: .init( // Derived binding for isSelected
                get: { viewModel.selectedDecorationID == decoration.id },
                set: { _ in /* Tap gesture in DraggableResizableView handles selection setting in VM */ }
            ),
            onUpdate: { updatedDeco in
                // Find and update in ViewModel's array
                // This logic is now simpler as we're updating the @Binding 'decoration'
                // which directly reflects in viewModel.decorations
                // However, onUpdate in DraggableResizableView can call viewModel.updateDecorationProperties
                viewModel.updateDecorationProperties(updatedDeco)
            },
            onTapped: {
                viewModel.selectedDecorationID = decoration.id
            },
            // onDelete: nil, // Already nil
            geometryProxy: geometry
        )
    }
}
