//
//  SnapshotPreviewStepView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import Foundation
import SwiftUI

struct SnapshotPreviewStepView: View {
    @EnvironmentObject var viewModel: SharingViewModel
    @Environment(\.routeColorTheme) private var routeColorTheme
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var imageScale = 0.95
    @State private var imageOpacity = 0.0
    @State private var buttonsOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Preview Area with improved presentation
            imagePreviewArea
                .scaleEffect(imageScale)
                .opacity(imageOpacity)
            
            Spacer()

            // Action Buttons with improved styling
            actionButtonsArea
                .opacity(buttonsOpacity)
        }
        .onAppear {
            // Staggered animation sequence for a polished entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                imageScale = 1.0
                imageOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                buttonsOpacity = 1.0
            }
        }
    }
    
    // MARK: - Subviews
    
    private var imagePreviewArea: some View {
        ZStack {
            if let image = viewModel.imageWithStats ?? viewModel.baseMapImage {
                // Card-like presentation for the image
                VStack(spacing: 0) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
            } else {
                // Enhanced loading placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                    .frame(height: 400)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: routePrimaryColor))
                            
                            Text("Preparing route preview...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            }
        }
    }
    
    private var actionButtonsArea: some View {
        VStack(spacing: 16) {
            // Title for the action area
            Text("Share Your Route")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 8)
            
            // Description text
            Text("Share your route as is, or customize it with different styles and decorations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            
            // Action buttons with improved design
            ShareActionButton(
                title: "Customize Style",
                iconName: "slider.horizontal.3",
                backgroundColor: routePrimaryColor.opacity(0.15),
                foregroundColor: routePrimaryColor
            ) {
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                withAnimation {
                    viewModel.goToLayoutCustomization()
                }
            }
            .disabled(viewModel.baseMapImage == nil)
            .padding(.horizontal, 24)

            ShareActionButton(
                title: "Share Now",
                iconName: "square.and.arrow.up",
                backgroundColor: routePrimaryColor,
                foregroundColor: .white
            ) {
                // Add haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                viewModel.shareDefault()
            }
            .disabled(viewModel.baseMapImage == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .padding(.bottom, 16)
    }
    
    private var routePrimaryColor: Color {
        RouteColors.color2(for: viewModel.route.type, theme: routeColorTheme)
    }
}
