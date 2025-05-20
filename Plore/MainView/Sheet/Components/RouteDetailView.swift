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

/// A detailed view for a single route with full-screen map and statistics
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

/// A detailed view for a single route with full-screen map and statistics.
struct RouteDetailView: View {
    // MARK: - Properties

    let route: RouteInfo

    @Environment(\.routeColorTheme) private var routeColorTheme
    @AppStorage("polylineStyle") private var polylineStyle: PolylineStyle = .standard
    @Environment(\.dismiss) private var dismiss
    @State private var mapPosition: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard
    @State private var isStandardMap: Bool = true

    @State private var isShareSheetPresented = false
    @State private var shareImage: UIImage?
    @State private var isGeneratingSnapshot = false

    /// Stores the initial bounding rectangle of the route for recentering.
    private let initialMapRect: MKMapRect

    // MARK: - Initialization

    init(route: RouteInfo) {
        self.route = route

        // Initialize map position to fit the route
        let rect = route.polyline.boundingMapRect

        // Add some padding to the bounding rect
        let paddingFactor = 0.3
        let padding = max(rect.size.width * paddingFactor, rect.size.height * paddingFactor)

        let paddedRect = MKMapRect(
            x: rect.origin.x - padding,
            y: rect.origin.y - padding,
            width: rect.size.width + (padding * 2),
            height: rect.size.height + (padding * 2)
        )
        self.initialMapRect = paddedRect
        _mapPosition = State(initialValue: .rect(paddedRect))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Main content: Map and Detail Panel
            VStack(spacing: 0) {
                mapView
                detailPanel
            }

            // Overlay for Floating Action Buttons and Top Controls
            mapControlsOverlay
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true)
        .sheet(isPresented: $isShareSheetPresented) {
            if let image = shareImage {
                ShareSheet(items: [image]) // Your MapSnapshotGenerator creates the image with overlays
            }
        }
        .overlay(snapshotLoadingOverlay) // Overlay for the loading indicator
    }

    // MARK: - Subviews

    /// Full-screen map view with the route and annotations.
    private var mapView: some View {
        Map(position: $mapPosition, interactionModes: .all) {
            if polylineStyle == .custom {
                // Casing for the route polyline
                MapPolyline(route.polyline)
                    .stroke(Color.black.opacity(0.4), lineWidth: 9) // Casing layer, slightly thicker than main line

                // Route polyline
                MapPolyline(route.polyline)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [routeTypeColor(for: route.type).opacity(0.8), routeTypeColor(for: route.type)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 7 // Main line
                    )
            } else {
                // Standard route polyline
                MapPolyline(route.polyline)
                    .stroke(routeTypeColor(for: route.type), lineWidth: 6)
            }

            // Start marker
            if let firstLocation = route.locations.first {
                Annotation("Start", coordinate: firstLocation.coordinate) {
                    startMarker
                }
            }

            // End marker
            if let lastLocation = route.locations.last, route.locations.count > 1 {
                Annotation("End", coordinate: lastLocation.coordinate) {
                    endMarker
                }
            }
        }
        .mapStyle(mapStyle)
        .contentMargins(.top, 60, for: .automatic)
        .contentMargins(.trailing, 15, for: .automatic)
        .contentMargins(.leading, 15, for: .automatic)
    }

    /// Overlay containing map control buttons (Back, Map Style, Recenter).
    private var mapControlsOverlay: some View {
        VStack {
            HStack {
                // Back button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .mapControlButtonStyling()
                }

                Spacer()

                // Map style toggle button
                Button {
                    isStandardMap.toggle()
                    mapStyle = isStandardMap ? .standard : .hybrid
                } label: {
                    Image(systemName: isStandardMap ? "map.fill" : "globe.americas.fill")
                        .mapControlButtonStyling()
                }

                // Recenter map button
                Button {
                    withAnimation(.easeInOut) {
                        mapPosition = .rect(initialMapRect)
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .mapControlButtonStyling()
                }
            }
            .padding(.horizontal)
            .padding(.top, UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets.top ?? 20)

            Spacer()
        }
    }


    /// Detail panel with route statistics and actions.
    private var detailPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.vertical, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    routeHeader
                    statisticsGrid // Simplified based on RouteInfo
                    elevationProfilePlaceholderSection // Placeholder as RouteInfo doesn't store elevation details
                    shareRouteButton
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Material.regular)
        .clipShape(
            .rect(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: -5)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.50) // Adjusted height
    }

    /// Header section for the detail panel showing route name, type, and date.
    private var routeHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(route.name ?? "Unnamed Route")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)

                HStack {
                    Image(systemName: routeTypeIcon(for: route.type))
                        .foregroundColor(routeTypeColor(for: route.type))
                        .imageScale(.medium)
                    Text(routeTypeName(for: route.type))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(formattedDate(route.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formattedTime(route.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Grid display for key route statistics.
    private var statisticsGrid: some View {
        // Only distance is directly calculable from the provided RouteInfo
        StatCard(
            value: calculateDistance(),
            unit: "mi",
            label: "Distance",
            icon: "arrow.left.and.right.circle.fill",
            color: routeTypeColor(for: route.type)
        )
        // Other StatCards (duration, pace, calories) are removed as
        // RouteInfo doesn't contain this data.
        // You could add them back with placeholder data or if RouteInfo is expanded.
    }

    /// Section displaying the (placeholder) elevation profile.
    private var elevationProfilePlaceholderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elevation Profile")
                .font(.headline)

            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { _ in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [routeTypeColor(for: route.type).opacity(0.8), routeTypeColor(for: route.type).opacity(0.4)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: CGFloat(20 + Int.random(in: 5...60)))
                    }
                }
            }
            .frame(height: 120)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            Text("Detailed elevation data not available for display.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    /// Button to trigger the route sharing functionality.
    private var shareRouteButton: some View {
        Button {
            shareRoute()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up.fill")
                Text("Share Route Image") // Clarified button action
            }
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(routeTypeColor(for: route.type))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: routeTypeColor(for: route.type).opacity(0.4), radius: 5, y: 3)
        }
        .padding(.top, 10)
        .disabled(isGeneratingSnapshot)
    }

    /// Overlay shown when the map snapshot is being generated.
    @ViewBuilder
    private var snapshotLoadingOverlay: some View {
        if isGeneratingSnapshot {
            ZStack {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.8)
                        .tint(.white)

                    Text("Creating route image...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(Material.thickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            }
        }
    }

    // MARK: - Marker Views
    
    /// View for the start marker on the map.
    private var startMarker: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)

            Circle()
                .fill(routeTypeColor(for: route.type))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 2)
                )
            Image(systemName: routeTypeIcon(for: route.type)) // Use route type icon for start
                .foregroundColor(.white)
                .font(.system(size: 10, weight: .bold))
        }
    }

    /// View for the end marker on the map.
    private var endMarker: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 34, height: 34)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)

            Image(systemName: "flag.checkered")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(routeTypeColor(for: route.type))
        }
    }


    // MARK: - Helper Methods

    private func routeTypeIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        case .hiking: "figure.hiking"
        default: "point.topleft.down.curvedto.point.bottomright.up.fill"
        }
    }

    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walking"
        case .running: "Running"
        case .cycling: "Cycling"
        // case .hiking: "Hiking"
        default: "Workout"
        }
    }

    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        let colors = RouteColors.colors(for: routeColorTheme)
        switch type {
        case .walking: return colors.walking
        case .running: return colors.running
        case .cycling: return colors.cycling
        // case .hiking: return colors.hiking
        default: return .gray
        }
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

    /// Calculates the total distance of the route in miles.
    private func calculateDistance() -> String {
        guard route.locations.count > 1 else {
            return "0.0"
        }
        var totalDistanceMeters: CLLocationDistance = 0
        for i in 0..<(route.locations.count - 1) {
            let current = route.locations[i]
            let next = route.locations[i + 1]
            totalDistanceMeters += current.distance(from: next)
        }
        let distanceInMiles = totalDistanceMeters / 1609.34
        return String(format: "%.1f", distanceInMiles)
    }

    /// Initiates snapshot generation and sharing.
    private func shareRoute() {
        isGeneratingSnapshot = true
        let mapTypeForSnapshot: MKMapType = isStandardMap ? .standard : .hybrid

        MapSnapshotGenerator.generateRouteSnapshot(
            route: route,
            mapType: mapTypeForSnapshot
        ) { image in
            DispatchQueue.main.async {
                isGeneratingSnapshot = false
                if let generatedImage = image {
                    self.shareImage = generatedImage
                    self.isShareSheetPresented = true
                } else {
                    print("Error generating map snapshot for sharing.")
                    // Optionally, show an alert to the user here
                }
            }
        }
    }
}

// MARK: - View Modifier for Map Buttons

struct MapControlButtonStyling: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
            .padding(10)
            .background(Material.regularMaterial)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

extension View {
    func mapControlButtonStyling() -> some View {
        self.modifier(MapControlButtonStyling())
    }
}

// MARK: - Preview

struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RouteDetailView(route: mockRouteInfo)
                .environment(\.routeColorTheme, .vibrant)
        }
    }

    static var mockRouteInfo: RouteInfo {
        let locations = [
            CLLocation(latitude: 37.7749, longitude: -122.4194),
            CLLocation(latitude: 37.7755, longitude: -122.4205),
            CLLocation(latitude: 37.7760, longitude: -122.4220),
            CLLocation(latitude: 37.7770, longitude: -122.4230),
            CLLocation(latitude: 37.7785, longitude: -122.4245),
            CLLocation(latitude: 37.7790, longitude: -122.4260)
        ]
        
        return RouteInfo(
            id: UUID(),
            name: "City Stroll Adventure",
            type: .walking,
            date: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
            locations: locations
        )
    }
}
