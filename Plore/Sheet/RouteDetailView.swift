//
//  RouteDetailView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/9/25.
//

import Foundation
import HealthKit
import MapKit
import SwiftUI

// A detailed view for a single route with full-screen map and statistics
// RouteDetailView.swift
import Foundation
import HealthKit
import MapKit
import SwiftUI

/// A detailed view for a single route with full-screen map and statistics
struct RouteDetailView: View {
    // MARK: - Properties

    let route: RouteInfo

    @Environment(\.routeColorTheme) private var routeColorTheme
    @Environment(\.dismiss) private var dismiss
    @State private var mapPosition: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard
    @State private var isStandardMap: Bool = true

    @State private var isShareExperiencePresented = false // For the new sharing flow
    @State private var shareButtonScale = 1.0 // Animation for share button
    @State private var isShowingShareTransition = false // For transition animation

    // MARK: - Initialization

    init(route: RouteInfo) {
        self.route = route

        // Initialize map position to fit the route
        let rect = route.polyline.boundingMapRect // Assuming route.polyline is accessible

        // Add some padding to the bounding rect
        let paddingWidth = rect.size.width * 0.25 // More generous padding for better view
        let paddingHeight = rect.size.height * 0.25
        let paddedRect = MKMapRect(
            x: rect.origin.x - paddingWidth,
            y: rect.origin.y - paddingHeight,
            width: rect.size.width + (paddingWidth * 2),
            height: rect.size.height + (paddingHeight * 2)
        )
        _mapPosition = State(initialValue: .rect(paddedRect))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 0) {
                mapView // The Map for RouteDetailView itself
                detailPanel
            }

            // Custom navigation bar overlay
            customNavigationBar
            
            // Share transition overlay - only visible during transition animation
            if isShowingShareTransition {
                Color.black
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isShareExperiencePresented) {
            // Pass the route and the *current map style* of the detail view as initial preference
            ShareHostView(route: route, initialMapStyle: mapStyle, routeColorTheme: routeColorTheme)
                .environment(\.routeColorTheme, routeColorTheme) // Pass theme
        }
    }

    // MARK: - Subviews

    private var customNavigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            Spacer()

            Button {
                isStandardMap.toggle()
                mapStyle = isStandardMap
                    ? .standard
                    : .hybrid(elevation: .realistic, showsTraffic: false) // Example hybrid style
            } label: {
                Image(systemName: isStandardMap ? "globe.americas.fill" : "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(
            .top,
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 0 + 10
        )
    }

    /// Full-screen map view with the route for this DetailView
    private var mapView: some View {
        Map(position: $mapPosition, interactionModes: .all) {
            // Route polyline
            MapPolyline(route.polyline)
                .stroke(routeTypeColor(for: route.type), lineWidth: 5)

            // Start marker
            if let firstLocation = route.locations.first {
                Annotation("Start", coordinate: firstLocation.coordinate) {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 30, height: 30).shadow(radius: 3)
                        Circle().fill(routeTypeColor(for: route.type)).frame(width: 20, height: 20)
                    }
                }
            }

            // End marker
            if let lastLocation = route.locations.last, (route.locations.count ?? 0) > 1 {
                Annotation("End", coordinate: lastLocation.coordinate) {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 30, height: 30).shadow(radius: 3)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(routeTypeColor(for: route.type))
                    }
                }
            }
        }
        .mapStyle(mapStyle) // Use the local mapStyle state for this view's map
    }

    /// Detail panel with route statistics
    private var detailPanel: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route name and type
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(route.name ?? "Unnamed Route")
                            .font(.title2).fontWeight(.bold)
                        HStack {
                            Image(systemName: routeTypeIcon(for: route.type))
                                .foregroundColor(routeTypeColor(for: route.type))
                            Text(routeTypeName(for: route.type))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        Text(formattedDate(route.date)).font(.subheadline)
                        Text(formattedTime(route.date)).font(.caption).foregroundColor(.secondary)
                    }
                }

                // Statistics cards (Only distance is calculated here, add others if data available)
                HStack(spacing: 15) {
                    StatCard(
                        value: calculateDistance(),
                        unit: "mi", // Or adapt to locale
                        label: "Distance",
                        icon: "arrow.left.and.right.square.fill",
                        color: routeTypeColor(for: route.type)
                    )
                    // Add StatCards for Duration, Pace if available in RouteInfo
                }

                // Elevation profile placeholder
                elevationProfilePlaceholder()

                // Share button with improved UI and animations
                Button {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Button press animation
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        shareButtonScale = 0.95
                    }
                    
                    // Show transition overlay
                    withAnimation(.easeIn(duration: 0.2)) {
                        isShowingShareTransition = true
                    }
                    
                    // Return button to normal size with slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            shareButtonScale = 1.0
                        }
                        
                        // Present sharing flow with delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isShareExperiencePresented = true
                            
                            // Reset transition overlay when sheet is fully presented
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isShowingShareTransition = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share Route")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(routeTypeColor(for: route.type).opacity(0.15))
                    )
                    .foregroundColor(routeTypeColor(for: route.type))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(routeTypeColor(for: route.type).opacity(0.3), lineWidth: 1)
                    )
                    .shadow(
                        color: routeTypeColor(for: route.type).opacity(0.2),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                }
                .scaleEffect(shareButtonScale)
                .padding(.top, 10)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground)) // Adapts to light/dark mode
        .clipShape(
            .rect(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.45) // Limit height of panel
    }

    private func elevationProfilePlaceholder() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Elevation Profile")
                .font(.headline)
            HStack(spacing: 0) {
                ForEach(0..<20, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(routeTypeColor(for: route.type).opacity(Double.random(in: 0.3...0.8)))
                        .frame(width: 12, height: CGFloat.random(in: 10...60))
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            Text("Elevation data not yet available for this view.")
                .font(.footnote).foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Methods

    private func routeTypeIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        default: "figure.mixed.cardio" // A generic fitness icon
        }
    }

    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walk"
        case .running: "Run"
        case .cycling: "Bike Ride"
        default: "Activity"
        }
    }

    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        RouteColors.color2(for: type, theme: routeColorTheme)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func calculateDistance() -> String {
        let locations = route.locations
        if locations.isEmpty {
            return "0.0"
        }
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(locations.count - 1) {
            totalDistance += locations[i].distance(from: locations[i + 1])
        }
        let distanceInMiles = totalDistance / 1609.34
        return String(format: "%.1f", distanceInMiles)
    }
}

struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RouteDetailView(route: mockRouteInfo)
        }
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
            type: .running, date: Date(),
            locations: locations
        )
    }
}
