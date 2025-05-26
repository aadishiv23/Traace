//
//  CollapsibleRouteRow.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/8/25.
//

import Foundation
import HealthKit
import MapKit
import SwiftUI

/// A beautifully designed row displaying a route's information with collapsible content.
struct CollapsibleRouteRow: View {
    // MARK: - Properties

    @Environment(\.routeColorTheme) private var routeColorTheme
    let route: RouteInfo
    let isEditing: Bool
    @Binding var editingName: String
    let onEditComplete: () -> Void
    let onEditStart: () -> Void
    let onRouteSelected: (RouteInfo) -> Void

    @State private var isExpanded: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Route header with name and edit button - always visible
            routeHeaderView

            Divider()
                .padding(.top, 10)
            // Route details - always visible
            routeDetailsView
                .padding(.top, 10)

            // Collapsible content
            if isExpanded {
                Divider()
                    .padding(.vertical, 10)

                // Map preview with 3D transition
                mapPreviewWithNavigation
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(
                            insertion:
                            .scale(scale: 0.95)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: 5)),
                            removal:
                            .scale(scale: 0.95)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: 5))
                        )
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(routeTypeColor(for: route.type).opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle()) // Make the whole card tappable
        .onTapGesture {
            if !isEditing {
                onRouteSelected(route)
            }
        }
    }

    // MARK: - Subviews

    /// Header view with route name and edit button
    private var routeHeaderView: some View {
        HStack(spacing: 12) {
            // Route activity icon
            // Replace your ZStack for the route icon:
            ZStack {
                // Outer glow/shadow
                Circle()
                    .fill(routeTypeColor(for: route.type).opacity(0.2))
                    .frame(width: 46, height: 46)
                    .blur(radius: 4)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                routeTypeColor(for: route.type).opacity(0.8),
                                routeTypeColor(for: route.type).opacity(0.4),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
                    .shadow(color: .white.opacity(0.3), radius: 2, x: -1, y: -1)

                Image(systemName: routeTypeIcon(for: route.type))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Route name / Edit field
            if isEditing {
                TextField("Route name", text: $editingName)
                    .font(.headline)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onSubmit {
                        onEditComplete()
                    }
            } else {
                Text(route.name ?? routeTypeName(for: route.type))
                    .font(.headline)
                    .lineLimit(1)
            }

            Spacer()

            // Edit/Save button
            Button {
                if isEditing {
                    onEditComplete()
                } else {
                    onEditStart()
                }
            } label: {
                Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                    .font(.system(size: 18))
                    .foregroundColor(isEditing ? .green : .gray)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(isEditing ? Color.green.opacity(0.15) : Color(.systemGray6))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    /// Details view with metadata about the route
    private var routeDetailsView: some View {
        HStack(spacing: 10) {
            // Date info
            dateInfoView

            Divider()
                .frame(height: 30)

            // Distance or other metrics
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text(calculateDistance())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 18)
            }

            Spacer()

            // Toggle expand button
            // Add this to the toggle expansion button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Map")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                        .id(isExpanded ? "hide" : "show")

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                        .id(isExpanded ? "up" : "down")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 1, y: 1)
                        .shadow(color: .white.opacity(0.5), radius: 2, x: -1, y: -1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .pressedEffect(isPressed: isExpanded) // Our custom pressed effect
        }
    }

    /// Date information formatted nicely
    private var dateInfoView: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(formattedDate(route.date))
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(formattedTime(route.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Map preview with navigation option
    private var mapPreviewWithNavigation: some View {
        ZStack(alignment: .bottomTrailing) {
            // The map preview
            routePreviewMap
                .frame(height: 150)
                .cornerRadius(12)

            // Navigation button overlay
            Button {
                onRouteSelected(route)
            } label: {
                HStack(spacing: 4) {
                    Text("View Full Map")
                        .font(.caption)
                        .fontWeight(.medium)

                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .foregroundColor(routeTypeColor(for: route.type))
            }
            .padding(12)
        }
    }

    /// Map preview of the route
    private var routePreviewMap: some View {
        Map {
            MapPolyline(route.polyline)
                .stroke(routeTypeColor(for: route.type), lineWidth: 3)

            if let firstLocation = route.locations.first {
                Annotation("Start", coordinate: firstLocation.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(radius: 2)

                        Circle()
                            .fill(routeTypeColor(for: route.type))
                            .frame(width: 16, height: 16)
                    }
                }
            }

            if let lastLocation = route.locations.last, route.locations.count > 1 {
                Annotation("End", coordinate: lastLocation.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(radius: 2)

                        Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(routeTypeColor(for: route.type))
                    }
                }
            }
        }
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
        let colors = RouteColors.colors(for: routeColorTheme)
        switch type {
        case .walking: return colors.walking
        case .running: return colors.running
        case .cycling: return colors.cycling
        default: return .gray
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
            return "0.0 mi"
        }

        // Calculate total distance
        var totalDistance: CLLocationDistance = 0
        for i in 0 ..< (route.locations.count - 1) {
            let current = route.locations[i]
            let next = route.locations[i + 1]
            totalDistance += current.distance(from: next)
        }

        // Convert to miles (or km based on locale)
        let distanceInMiles = totalDistance / 1609.34
        return String(format: "%.1f mi", distanceInMiles)
    }
}

#Preview("Collapsible Route Row") {
    VStack(spacing: 20) {
        Group {
            // Running route - named - expanded - light mode
            CollapsibleRouteRow(
                route: RouteInfo(
                    name: "Morning Run",
                    type: .running,
                    date: Date().addingTimeInterval(-86400), // Yesterday
                    locations: generateLocations(count: 100, radiusFactor: 0.003)
                ),
                isEditing: false,
                editingName: .constant("Morning Run"),
                onEditComplete: {},
                onEditStart: {},
                onRouteSelected: { _ in }
            )
            .environment(\.colorScheme, .light)
            .previewDisplayName("Running - Named - Light Mode")

            // Walking route - named - collapsed - dark mode
            CollapsibleRouteRow(
                route: RouteInfo(
                    name: "Park Walk",
                    type: .walking,
                    date: Date().addingTimeInterval(-172_800), // 2 days ago
                    locations: generateLocations(count: 75, radiusFactor: 0.002)
                ),
                isEditing: false,
                editingName: .constant("Park Walk"),
                onEditComplete: {},
                onEditStart: {},
                onRouteSelected: { _ in }
            )
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Walking - Named - Dark Mode")

            // Cycling route - unnamed - expanded - dark mode
            let cyclingRoute = RouteInfo(
                name: nil,
                type: .cycling,
                date: Date().addingTimeInterval(-259_200), // 3 days ago
                locations: generateLocations(count: 150, radiusFactor: 0.005)
            )

            CollapsibleRouteRow(
                route: cyclingRoute,
                isEditing: false,
                editingName: .constant(""),
                onEditComplete: {},
                onEditStart: {},
                onRouteSelected: { _ in }
            )
            .onAppear {
                // Simulate expansion for preview
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let mirror = Mirror(reflecting: CollapsibleRouteRow(
                        route: cyclingRoute,
                        isEditing: false,
                        editingName: .constant(""),
                        onEditComplete: {},
                        onEditStart: {},
                        onRouteSelected: { _ in }
                    ))
                    if let isExpanded = mirror.descendant("_isExpanded") as? Bool {
                        // Note: This is a hack for preview only and won't work at runtime
                        // It's just to show the expanded state in preview
                    }
                }
            }
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Cycling - Unnamed - Dark Mode")

            // Running route - editing mode - light mode
            CollapsibleRouteRow(
                route: RouteInfo(
                    name: "Afternoon Jog",
                    type: .running,
                    date: Date().addingTimeInterval(-345_600), // 4 days ago
                    locations: generateLocations(count: 50, radiusFactor: 0.001)
                ),
                isEditing: true,
                editingName: .constant("Afternoon Jog"),
                onEditComplete: {},
                onEditStart: {},
                onRouteSelected: { _ in }
            )
            .environment(\.colorScheme, .light)
            .previewDisplayName("Running - Editing Mode - Light Mode")

            // Very short route - potential edge case - dark mode
            CollapsibleRouteRow(
                route: RouteInfo(
                    name: "Quick Sprint",
                    type: .running,
                    date: Date(),
                    locations: generateLocations(count: 5, radiusFactor: 0.0005)
                ),
                isEditing: false,
                editingName: .constant("Quick Sprint"),
                onEditComplete: {},
                onEditStart: {},
                onRouteSelected: { _ in }
            )
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Running - Short Route - Dark Mode")
        }
    }
    .padding()
}

/// Helper function to generate random route locations
private func generateLocations(count: Int, radiusFactor: Double) -> [CLLocation] {
    let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco
    var locations: [CLLocation] = []

    for i in 0 ..< count {
        // Create a spiral pattern
        let angle = Double(i) * 0.1
        let radius = Double(i) * radiusFactor
        let x = radius * cos(angle)
        let y = radius * sin(angle)

        let coordinate = CLLocationCoordinate2D(
            latitude: center.latitude + y,
            longitude: center.longitude + x
        )

        let location = CLLocation(
            coordinate: coordinate,
            altitude: 0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date().addingTimeInterval(-Double(count - i) * 10)
        )

        locations.append(location)
    }

    return locations
}
