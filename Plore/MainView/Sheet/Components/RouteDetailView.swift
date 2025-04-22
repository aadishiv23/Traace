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
struct RouteDetailView: View {
    // MARK: - Properties

    let route: RouteInfo

    @Environment(\.dismiss) private var dismiss
    @State private var mapPosition: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard
    @State private var isStandardMap: Bool = true

    @State private var isShareSheetPresented = false
    @State private var shareImage: UIImage?
    @State private var isGeneratingSnapshot = false

    // MARK: - Initialization

    init(route: RouteInfo) {
        self.route = route

        // Initialize map position to fit the route
        let rect = route.polyline.boundingMapRect

        // Add some padding to the bounding rect
        let padding = rect.size.width * 0.2
        let paddedRect = MKMapRect(
            x: rect.origin.x - padding,
            y: rect.origin.y - padding,
            width: rect.size.width + (padding * 2),
            height: rect.size.height + (padding * 2)
        )

        _mapPosition = State(initialValue: .rect(paddedRect))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 0) {
                // Map view
                mapView

                // Detail panel
                detailPanel
            }

            // Custom navigation bar overlay
            HStack {
                // Back button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }

                Spacer()

                // Map style toggle button
                Button {
                    // Toggle between standard and satellite using the boolean
                    isStandardMap.toggle()
                    mapStyle = isStandardMap ? .standard : .hybrid
                } label: {
                    Image(systemName: isStandardMap ? "globe" : "map")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 50) // Adjust this based on safe area
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true) // This hides the navigation bar completely
        .sheet(isPresented: $isShareSheetPresented) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .overlay(
            Group {
                if isGeneratingSnapshot {
                    ZStack {
                        Color.black.opacity(0.4)

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Creating route image...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.systemBackground).opacity(0.8))
                        )
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
    }

    // MARK: - Subviews

    /// Full-screen map view with the route
    private var mapView: some View {
        Map(position: $mapPosition, interactionModes: .all) {
            // Route polyline
            MapPolyline(route.polyline)
                .stroke(routeTypeColor(for: route.type), lineWidth: 5)

            // Start marker
            if let firstLocation = route.locations.first {
                Annotation("Start", coordinate: firstLocation.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 3)

                        Circle()
                            .fill(routeTypeColor(for: route.type))
                            .frame(width: 20, height: 20)
                    }
                }
            }

            // End marker
            if let lastLocation = route.locations.last, route.locations.count > 1 {
                Annotation("End", coordinate: lastLocation.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 3)

                        Image(systemName: "flag.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(routeTypeColor(for: route.type))
                    }
                }
            }
        }
        .mapStyle(mapStyle)
    }

    /// Detail panel with route statistics
    private var detailPanel: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route name and type
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(route.name ?? "Unnamed Route")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            Image(systemName: routeTypeIcon(for: route.type))
                                .foregroundColor(routeTypeColor(for: route.type))

                            Text(routeTypeName(for: route.type))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Route date
                    VStack(alignment: .trailing, spacing: 5) {
                        Text(formattedDate(route.date))
                            .font(.subheadline)

                        Text(formattedTime(route.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Statistics cards
                HStack(spacing: 15) {
                    // Distance
                    StatCard(
                        value: calculateDistance(),
                        unit: "mi",
                        label: "Distance",
                        icon: "arrow.left.and.right",
                        color: routeTypeColor(for: route.type)
                    )

//                    // Duration
//                    StatCard(
//                        value: "25",
//                        unit: "min",
//                        label: "Duration",
//                        icon: "clock",
//                        color: routeTypeColor(for: route.type)
//                    )
//
//                    // Pace
//                    StatCard(
//                        value: "10:30",
//                        unit: "mi/min",
//                        label: "Pace",
//                        icon: "speedometer",
//                        color: routeTypeColor(for: route.type)
//                    )
                }

                // Elevation profile placeholder
                VStack(alignment: .leading, spacing: 10) {
                    Text("Elevation Profile")
                        .font(.headline)

                    HStack(spacing: 0) {
                        ForEach(0..<20, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(routeTypeColor(for: route.type).opacity(0.7))
                                .frame(width: 12, height: CGFloat(10 + Int.random(in: 5...50)))
                        }
                    }
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    HStack {
                        Text("Elevation Gain: 156 ft")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Elevation Loss: 142 ft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Actual elevation data coming soon...")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // Share button - Updated with functionality
                Button {
                    shareRoute()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Share Route")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(routeTypeColor(for: route.type).opacity(0.1))
                    )
                    .foregroundColor(routeTypeColor(for: route.type))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(routeTypeColor(for: route.type).opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.top, 10)
                .disabled(isGeneratingSnapshot) // Disable while generating snapshot
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(
            .rect(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16
            )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }

    // MARK: - Helper Methods

    /// Returns the icon name for a route type.
    private func routeTypeIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        default: "mappin.and.ellipse"
        }
    }

    /// Returns the display name for a route type.
    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walking Route"
        case .running: "Running Route"
        case .cycling: "Cycling Route"
        default: "Unknown Route"
        }
    }

    /// Returns the color for a route type.
    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking: .blue
        case .running: .red
        case .cycling: .green
        default: .gray
        }
    }

    /// Formats a date for display.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats a time for display.
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Calculate distance for the route
    private func calculateDistance() -> String {
        guard route.locations.count > 1 else {
            return "0.0"
        }

        // Calculate total distance
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(route.locations.count - 1) {
            let current = route.locations[i]
            let next = route.locations[i + 1]
            totalDistance += current.distance(from: next)
        }

        // Convert to miles (or km based on locale)
        let distanceInMiles = totalDistance / 1609.34
        return String(format: "%.1f", distanceInMiles)
    }

    /// Share the route with a custom map image
    private func shareRoute() {
        // Show loading indicator
        isGeneratingSnapshot = true

        // Generate map snapshot
        let mapType: MKMapType = isStandardMap ? .standard : .hybrid

        MapSnapshotGenerator.generateRouteSnapshot(route: route, mapType: mapType) { image in
            // Hide loading indicator
            DispatchQueue.main.async {
                isGeneratingSnapshot = false

                if let image {
                    // Set the share image and present share sheet
                    shareImage = image
                    isShareSheetPresented = true
                }
            }
        }
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
