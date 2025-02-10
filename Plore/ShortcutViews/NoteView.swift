//
//  NoteView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/10/25.
//

import Foundation
import SwiftUI

// MARK: - NoteView (Hidden Navigation Bar)

/// A view demonstrating the LigiPhotoPicker API in use.
struct NoteView: View {
    @State private var image: UIImage? = nil

    var body: some View {
        NavigationView {
            VStack {
                LigiPhotoPicker(
                    selectedImage: $image,
                    cropShape: .circle
                ) // You can also pass a cropShape parameter here.
                Spacer()
            }
            .navigationTitle("LigiPhotoPicker Demo")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green.opacity(0.2))
        .ignoresSafeArea()
    }
}
