// LayoutCustomizationStepView.swift

import Foundation
import SwiftUI
import HealthKit // For HKWorkoutActivityType
import CoreLocation // <-- ADD THIS IMPORT

// ... (LayoutCustomizationStepView struct remains largely the same) ...
struct LayoutCustomizationStepView: View {
    @EnvironmentObject var viewModel: SharingViewModel
    @Environment(\.routeColorTheme) private var routeColorTheme
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states
    @State private var previewScale: CGFloat = 0.95
    @State private var previewOpacity: CGFloat = 0
    @State private var selectedPresetIndex: Int = 0
    @State private var carouselOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Preview with enhanced presentation
            ZStack {
                if let baseImage = viewModel.baseMapImage {
                    // Card-like design for the preview
                    VStack(spacing: 0) {
                        ZStack {
                            Image(uiImage: baseImage)
                                .resizable()
                                .scaledToFit()
                                .overlay(
                                    Group {
                                        if let imgWithStats = viewModel.imageWithStats, viewModel.selectedLayout == currentLayoutInImageWithStats {
                                            Image(uiImage: imgWithStats)
                                                .resizable()
                                                .scaledToFit()
                                                .transition(.opacity)
                                        } else {
                                            StatOverlayView(route: viewModel.route, layout: viewModel.selectedLayout, routeColorTheme: routeColorTheme)
                                        }
                                    }
                                )
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .scaleEffect(previewScale)
                    .opacity(previewOpacity)
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
                                
                                Text("Preparing layout preview...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
                }
            }
            .onAppear {
                // Animate the preview on appearance
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    previewScale = 1.0
                    previewOpacity = 1.0
                }
                
                // Set the initial selected preset index
                if let index = StatLayoutPreset.allCases.firstIndex(where: { $0 == viewModel.selectedLayout }) {
                    selectedPresetIndex = index
                }
            }
            
            // Layout information card
            layoutInfoView
                .padding(.top, 16)
                .padding(.horizontal, 16)
            
            // Layout Carousel Picker
            layoutCarouselView
                .padding(.top, 20)
            
            Spacer()

            // Action Buttons
            VStack(spacing: 15) {
                ShareActionButton(
                    title: "Next: Add Flair",
                    iconName: "wand.and.stars.fill",
                    backgroundColor: routePrimaryColor.opacity(0.2),
                    foregroundColor: routePrimaryColor
                ) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Animate preview out before transition
                    withAnimation(.easeInOut(duration: 0.3)) {
                        previewScale = 0.95
                        previewOpacity = 0
                    }
                    
                    // Delay the transition to allow animation to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.goToDecoration()
                    }
                }
                .disabled(viewModel.imageWithStats == nil || viewModel.isProcessing)

                ShareActionButton(
                    title: "Share This Style",
                    iconName: "square.and.arrow.up.fill",
                    backgroundColor: routePrimaryColor,
                    foregroundColor: .white
                ) {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    viewModel.shareCurrentLayout()
                }
                .disabled(viewModel.imageWithStats == nil || viewModel.isProcessing)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Subviews
    
    private var layoutInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.selectedLayout.displayName)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(viewModel.selectedLayout.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6).opacity(0.5))
        )
        .transition(.opacity)
        .id(viewModel.selectedLayout.id) // Force transition when layout changes
    }
    
    private var layoutCarouselView: some View {
        VStack(spacing: 16) {
            // Current layout indicator
            HStack(spacing: 6) {
                ForEach(0..<StatLayoutPreset.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedPresetIndex ? routePrimaryColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == selectedPresetIndex ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPresetIndex)
                }
            }
            .padding(.bottom, 8)
            
            // Horizontal layout preset carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(StatLayoutPreset.allCases.enumerated()), id: \.element.id) { index, preset in
                        layoutPresetButton(preset, index: index)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                                    selectedPresetIndex = index
                                    carouselOffset = -CGFloat(index) * 110 // Adjust based on item width
                                }
                                
                                if viewModel.selectedLayout != preset {
                                    // Haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    
                                    // Apply the selected layout with a smooth animation
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        previewOpacity = 0.7
                                    }
                                    
                                    viewModel.renderAndSetImageWithStats(layout: preset)
                                    
                                    withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                                        previewOpacity = 1.0
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .offset(x: calculateCenteringOffset())
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: selectedPresetIndex)
            }
            .frame(height: 130)
            .onAppear {
                if let index = StatLayoutPreset.allCases.firstIndex(where: { $0 == viewModel.selectedLayout }) {
                    carouselOffset = -CGFloat(index) * 110
                }
            }
        }
    }
    
    private var currentLayoutInImageWithStats: StatLayoutPreset? {
        return viewModel.selectedLayout
    }
    
    private func calculateCenteringOffset() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth: CGFloat = 108 // Width of each layout item including spacing
        let centeringOffset = (screenWidth - itemWidth) / 2.0
        
        return centeringOffset + (CGFloat(selectedPresetIndex) * -itemWidth)
    }

    private func layoutPresetButton(_ preset: StatLayoutPreset, index: Int) -> some View {
        VStack(spacing: 8) {
            // Icon in a circle
            ZStack {
                Circle()
                    .fill(viewModel.selectedLayout == preset ? routePrimaryColor : Color(UIColor.systemGray5))
                    .frame(width: 68, height: 68)
                    .shadow(color: viewModel.selectedLayout == preset ? routePrimaryColor.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
                
                Image(systemName: preset.previewIconName)
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.selectedLayout == preset ? .white : Color(UIColor.systemGray))
                
                if viewModel.selectedLayout == preset {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 62, height: 62)
                }
            }
            
            // Layout name
            Text(preset.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(viewModel.selectedLayout == preset ? routePrimaryColor : .primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(width: 90)
        .contentShape(Rectangle())
        .scaleEffect(viewModel.selectedLayout == preset ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedLayout)
    }
    
    private var routePrimaryColor: Color {
        RouteColors.color2(for: viewModel.route.type, theme: routeColorTheme)
    }
}

// `StatOverlayView` (displays stats on the image)
struct StatOverlayView: View {
    let route: RouteInfo                 // Passed in
    let layout: StatLayoutPreset         // Passed in
    let routeColorTheme: RouteColorTheme // Passed in

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch layout {
            case .defaultCardBottom:
                defaultCardBottomView
            case .minimalistTop:
                minimalistTopView
            case .detailedSide:
                detailedSideView
            case .modernFloating:
                modernFloatingView
            case .gradientOverlay:
                gradientOverlayView
            case .metricsFocus:
                metricsFocusView
            case .elegantCorner:
                elegantCornerView
            case .infographicStyle:
                infographicStyleView
            }
        }
        .foregroundColor(.white)
        .background(Color.clear)
        .environment(\.routeColorTheme, routeColorTheme)
    }
    
    // MARK: - Layout Specific Views
    private var defaultCardBottomView: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(route.name ?? routeTypeName(for: route.type))
                        .font(.system(size: 28, weight: .bold))
                        .shadow(radius: 2)
                    
                    HStack {
                         Text(String(format: "%.1f mi", calculateDistanceInMiles()))
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(routeSpecificColor)
                            .shadow(radius: 3)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(routeTypeName(for: route.type).uppercased())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(routeSpecificColor.opacity(0.8))
                            Text(formattedDate(route.date))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                Spacer()
            }
            .padding(25)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]), startPoint: .bottom, endPoint: .top)
            )
            .overlay(Rectangle().frame(height: 4).foregroundColor(routeSpecificColor), alignment: .top)
        }
    }

    private var minimalistTopView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: "%.1f mi", calculateDistanceInMiles()))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(routeSpecificColor)
                .shadow(radius: 2)
            Text(route.name ?? routeTypeName(for: route.type))
                .font(.system(size: 18, weight: .medium))
                .shadow(radius: 1)
            Text(formattedDate(route.date))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .shadow(radius: 1)
        }
        .padding(20)
    }
    
    private var detailedSideView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                 Text(route.name ?? routeTypeName(for: route.type))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(routeSpecificColor)
                
                StatRow(label: "Distance", value: String(format: "%.1f mi", calculateDistanceInMiles()))
                StatRow(label: "Date", value: formattedDate(route.date))
                StatRow(label: "Type", value: routeTypeName(for: route.type))
                Spacer()
            }
            .padding(20)
            .background(Color.black.opacity(0.6))
            .frame(maxWidth: 280)
            Spacer()
        }
    }
    
    // New layout: Modern Floating Card
    private var modernFloatingView: some View {
        ZStack {
            VStack(alignment: .center, spacing: 12) {
                Spacer()
                VStack(spacing: 5) {
                    Text(String(format: "%.1f", calculateDistanceInMiles()))
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("MILES")
                        .font(.system(size: 14, weight: .bold))
                        .kerning(2)
                        .foregroundColor(routeSpecificColor)
                }
                
                Text(route.name ?? routeTypeName(for: route.type))
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 15) {
                    Label(routeTypeName(for: route.type), systemImage: routeTypeIcon(for: route.type))
                        .font(.system(size: 12, weight: .medium))
                    
                    Rectangle()
                        .frame(width: 1, height: 12)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Label(formattedDate(route.date), systemImage: "calendar")
                        .font(.system(size: 12, weight: .medium))
                }
                Spacer()
            }
            .frame(width: 250, height: 180)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.75))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(routeSpecificColor.opacity(0.6), lineWidth: 1.5)
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // New layout: Full Gradient Overlay
    private var gradientOverlayView: some View {
        ZStack {
            // Full screen gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    routeSpecificColor.opacity(0.8),
                    routeSpecificColor.opacity(0.2),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            
            VStack(alignment: .leading) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(route.name ?? routeTypeName(for: route.type))
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                    
                    Text(routeTypeName(for: route.type).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 10)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(String(format: "%.1f", calculateDistanceInMiles()))
                            .font(.system(size: 64, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("MI")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 10)
                    }
                    
                    Text(formattedDate(route.date))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(30)
            }
        }
    }
    
    // New layout: Metrics Focus
    private var metricsFocusView: some View {
        ZStack {
            VStack(alignment: .center) {
                Spacer()
                
                // Main distance metric
                ZStack {
                    Circle()
                        .fill(routeSpecificColor)
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.1f", calculateDistanceInMiles()))
                            .font(.system(size: 48, weight: .heavy))
                        
                        Text("MILES")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(1)
                    }
                    .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                
                // Route info bar
                HStack(spacing: 0) {
                    Text(route.name ?? routeTypeName(for: route.type))
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formattedDate(route.date))
                        .font(.system(size: 14, weight: .medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .lineLimit(1)
                }
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
            }
        }
    }
    
    // New layout: Elegant Corner Card
    private var elegantCornerView: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(route.name ?? routeTypeName(for: route.type))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", calculateDistanceInMiles()))
                            .font(.system(size: 30, weight: .heavy))
                        
                        Text("mi")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 12) {
                        Text(routeTypeName(for: route.type))
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("•")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(formattedDate(route.date))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            routeSpecificColor,
                            routeSpecificColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(15, corners: [.topLeft, .bottomRight])
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 2, y: 2)
                
                Spacer()
            }
            
            Spacer()
        }
    }
    
    // New layout: Infographic Style
    private var infographicStyleView: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            VStack(spacing: 15) {
                Spacer()
                
                // Title and route type
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(route.name ?? routeTypeName(for: route.type))
                            .font(.system(size: 26, weight: .bold))
                        
                        Text(routeTypeName(for: route.type).uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(routeSpecificColor)
                    }
                    
                    Spacer()
                    
                    // Date badge
                    VStack {
                        Text(formattedDateDay(route.date))
                            .font(.system(size: 20, weight: .bold))
                        
                        Text(formattedDateMonth(route.date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(routeSpecificColor)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Distance visualization
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(i < Int(calculateDistanceInMiles()*1.5) ? routeSpecificColor : Color.white.opacity(0.2))
                            .frame(width: 12, height: CGFloat(20 + i * 5))
                            .cornerRadius(6)
                    }
                }
                .padding(.vertical, 10)
                
                // Distance metrics
                HStack(alignment: .bottom, spacing: 0) {
                    Text(String(format: "%.1f", calculateDistanceInMiles()))
                        .font(.system(size: 52, weight: .black))
                    
                    Text(" MILES")
                        .font(.system(size: 14, weight: .bold))
                        .offset(y: -10)
                }
                .foregroundColor(.white)
            }
            .padding(25)
        }
    }

    struct StatRow: View {
        let label: String
        let value: String
        var body: some View {
            VStack(alignment: .leading) {
                Text(label.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.title3.weight(.medium))
            }
        }
    }

    // MARK: - Data Helpers for StatOverlayView
    private var routeSpecificColor: Color {
        RouteColors.color2(for: route.type, theme: routeColorTheme)
    }

    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walk"
        case .running: "Run"
        case .cycling: "Ride"
        default: "Activity"
        }
    }
    
    private func routeTypeIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        default: "figure.mixed.cardio"
        }
    }

    private func calculateDistanceInMiles() -> Double {
        let locations = route.locations
        guard locations.count > 1 else {
            return 0.0
        }
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(locations.count - 1) {
            totalDistance += locations[i].distance(from: locations[i + 1])
        }
        return totalDistance / 1609.34
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper methods for the infographic style
    private func formattedDateDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private func formattedDateMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
}

// Extension to allow corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
