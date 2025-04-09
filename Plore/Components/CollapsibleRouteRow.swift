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

            // Route details - always visible
            routeDetailsView
                .padding(.top, 10)

            // Collapsible content
            if isExpanded {
                Divider()
                    .padding(.vertical, 10)

                // Map preview
                mapPreviewWithNavigation
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
            ZStack {
                Circle()
                    .fill(routeTypeColor(for: route.type).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: routeTypeIcon(for: route.type))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(routeTypeColor(for: route.type))
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
        HStack(spacing: 16) {
            // Date info
            dateInfoView

            Divider()
                .frame(height: 30)

            // Distance or other metrics
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text(calculateDistance())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Toggle expand button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Hide Map" : "Show Map")
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
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    /// Date information formatted nicely
    private var dateInfoView: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

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
            return "0.0 mi"
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
        return String(format: "%.1f mi", distanceInMiles)
    }
}
