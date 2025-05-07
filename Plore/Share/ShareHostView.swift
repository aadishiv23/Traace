//
//  ShareHostView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/6/25.
//

import Foundation
import MapKit // For MKMapType constants
import SwiftUI

struct ShareHostView: View {
    @StateObject var viewModel: SharingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var animationProgress: CGFloat = 0
    @State private var showHeader = false
    
    /// Used to pass initial map style from RouteDetailView
    init(route: RouteInfo, initialMapStyle: MapStyle = .standard, routeColorTheme: RouteColorTheme) {
        _viewModel = StateObject(wrappedValue: SharingViewModel(
            route: route,
            routeColorTheme: routeColorTheme,
            initialMapStyle: initialMapStyle
        ))
    }

    var currentMapStyleIsStandard: Bool {
        viewModel.mapTypeForSnapshot == .standard
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                backgroundView
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar Area
                    customNavigationBar
                        .opacity(showHeader ? 1 : 0)
                    
                    // Content based on step
                    contentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .overlay(
                    Group {
                        if viewModel.isProcessing, viewModel.currentStep != .loadingInitialSnapshot {
                            ProcessingOverlayView(message: viewModel.userMessage ?? "Processing...")
                        }
                    }
                )
            }
            .navigationBarHidden(true)
            .environmentObject(viewModel) 
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showHeader = true
                }
                
                // Start the animation sequence
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationProgress = 1
                }
                
                viewModel.dismissFlow = { 
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showHeader = false
                        animationProgress = 0
                    }
                    
                    // Delay the actual dismissal to allow the animation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        dismiss()
                    }
                }
                
                if viewModel.baseMapImage == nil {
                    viewModel.start()
                }
            }
            .sheet(isPresented: $viewModel.showShareSheetView) {
                if let image = viewModel.finalImageToShare {
                    ShareSheet(
                        items: [image, "Check out my route on TRAACE! #traaceapp"],
                        completion: { returnedItems, completed in
                            // Call onShareCompleted callback if defined
                            viewModel.onShareCompleted?(returnedItems, completed)
                            
                            // Provide haptic feedback for completion
                            if completed {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                            }
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                } else {
                    Text("Error: Image not available for sharing.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        ZStack {
            Color(UIColor.systemBackground)
            
            // Subtle gradient based on color scheme
            LinearGradient(
                gradient: Gradient(
                    colors: colorScheme == .dark 
                        ? [Color.black, Color(UIColor.systemGray6)] 
                        : [Color(UIColor.systemGray6), Color.white]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.5)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var customNavigationBar: some View {
        HStack {
            // Back/Dismiss button with dynamic icon
            Button {
                // Haptic feedback for navigation actions
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                if viewModel.currentStep == .previewInitial || viewModel.currentStep == .loadingInitialSnapshot {
                    viewModel.dismissFlow?()
                } else {
                    viewModel.goBack()
                }
            } label: {
                Image(
                    systemName: viewModel.currentStep == .previewInitial || viewModel.currentStep == .loadingInitialSnapshot
                        ? "xmark"
                        : "chevron.left"
                )
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }

            Spacer()
            
            // Animated step indicator with title
            Text(navigationTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .transition(.opacity)
                .id(navigationTitle) // Forces animation when title changes
            
            Spacer()

            // Map style toggle button
            if viewModel.currentStep != .loadingInitialSnapshot {
                Button(action: {
                    // Haptic feedback for map toggle
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.updateMapType(currentMapStyleIsStandard ? .hybrid : .standard)
                    }
                }) {
                    Image(systemName: currentMapStyleIsStandard ? "globe.americas.fill" : "map.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .frame(height: 56)
        .background(
            colorScheme == .dark
                ? Color.black.opacity(0.8)
                : Color.white.opacity(0.8)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
    
    private var contentView: some View {
        Group {
            switch viewModel.currentStep {
            case .loadingInitialSnapshot:
                LoadingStepView(message: viewModel.userMessage ?? "Loading...")
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 1.1))
                        )
                    )
            case .previewInitial:
                SnapshotPreviewStepView()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            case .layoutCustomization:
                LayoutCustomizationStepView()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            case .decoration:
                DecorationStepView()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
    }

    var navigationTitle: String {
        switch viewModel.currentStep {
        case .loadingInitialSnapshot: "Preparing Share"
        case .previewInitial: "Preview Route"
        case .layoutCustomization: "Customize Style"
        case .decoration: "Add Flair"
        }
    }
}

struct LoadingStepView: View {
    let message: String
    @State private var opacity: Double = 0.7
    
    var body: some View {
        VStack(spacing: 20) {
            // Modern loading indicator with pulsing animation
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
            
            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .opacity(opacity)
                .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: opacity)
                .onAppear {
                    // Subtle breathing animation for loading text
                    opacity = 0.5
                }
        }
    }
}

struct ProcessingOverlayView: View {
    let message: String
    @State private var animationAmount = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            VStack(spacing: 20) {
                ZStack {
                    // Outer pulsing circle
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationAmount)
                        .opacity(2 - animationAmount)
                    
                    // Inner progress view
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
        }
        .onAppear {
            // Create a pulsing animation
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                animationAmount = 1.5
            }
        }
    }
}

/// ShareActionButton (reusable button style)
struct ShareActionButton: View {
    let title: String
    let iconName: String?
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 12) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isEnabled 
                    ? backgroundColor
                    : Color.gray.opacity(0.3)
            )
            .foregroundColor(
                isEnabled 
                    ? foregroundColor
                    : Color.gray.opacity(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isEnabled 
                            ? backgroundColor.opacity(0.5)
                            : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isEnabled ? backgroundColor.opacity(0.3) : Color.clear,
                radius: 5,
                x: 0,
                y: 2
            )
            // Add press animation
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// Extension to handle press events
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
