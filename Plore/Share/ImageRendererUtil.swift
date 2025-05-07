//
//  ImageRendererUtil.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import Foundation
import SwiftUI
import UIKit

enum ImageRenderer {
    @MainActor // UIHostingController interaction must be on the main thread
    private static func renderSwiftUIToImage<V: View>(view: V, size: CGSize) -> UIImage? {
        let rootView = view
            .frame(width: size.width, height: size.height)
            .background(Color.clear) // Crucial for transparent overlays

        // UIHostingController is the bridge
        let controller = UIHostingController(rootView: rootView)
        guard let targetView = controller.view else { return nil }

        targetView.bounds = CGRect(origin: .zero, size: size)
        targetView.backgroundColor = .clear

        // Render the view hierarchy to an image
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            targetView.drawHierarchy(in: targetView.bounds, afterScreenUpdates: true)
        }
        return image
    }

    // Asynchronously renders a SwiftUI view and composites it onto a base UIImage
    static func renderAndComposite<V: View>(baseImage: UIImage, overlayView: V, overlaySize: CGSize) async -> UIImage? {
        // 1. Render SwiftUI overlay to UIImage (must happen on main thread)
        let overlayUIImage = await MainActor.run {
            renderSwiftUIToImage(view: overlayView, size: overlaySize)
        }

        guard let overlayUIImage = overlayUIImage else {
            // If overlay fails, decide behavior: return base, return nil, etc.
            print("Failed to render SwiftUI overlay to image.")
            return baseImage // Or nil if overlay is critical
        }

        // 2. Composite images (can be done on a background thread)
        return await Task.detached(priority: .userInitiated) {
            UIGraphicsBeginImageContextWithOptions(baseImage.size, false, baseImage.scale) // false for alpha
            baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))
            overlayUIImage.draw(in: CGRect(origin: .zero, size: baseImage.size), blendMode: .normal, alpha: 1.0)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }.value
    }
}
