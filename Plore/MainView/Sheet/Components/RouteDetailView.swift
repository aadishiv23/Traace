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
        .cornerRadius(16, corners: [.topLeft, .topRight])
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
import Foundation
import HealthKit
import MapKit
import SwiftUI
import UIKit

// MARK: - Map Snapshot Generator

/// Helper class to generate visually appealing map snapshots
class MapSnapshotGenerator {
    /// Generate a stylish snapshot of a route with all relevant markers
    static func generateRouteSnapshot(
        route: RouteInfo,
        mapType: MKMapType,
        completion: @escaping (UIImage?) -> Void
    ) {
        // Get the bounding rect of the route with some padding
        let rect = route.polyline.boundingMapRect
        let padding = rect.size.width * 0.2
        let paddedRect = MKMapRect(
            x: rect.origin.x - padding,
            y: rect.origin.y - padding,
            width: rect.size.width + (padding * 2),
            height: rect.size.height + (padding * 2)
        )
        
        // Create snapshot options
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(paddedRect)
        options.mapType = mapType
        options.size = CGSize(width: 1200, height: 1200) // Even higher resolution for sharing
        options.showsBuildings = true
        
        // Create the snapshotter
        let snapshotter = MKMapSnapshotter(options: options)
        
        // Start taking the snapshot
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion(nil)
                return
            }
            
            // Create an image context to draw on
            UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
            defer { UIGraphicsEndImageContext() }
            
            // Draw the map snapshot
            snapshot.image.draw(at: .zero)
            
            guard let context = UIGraphicsGetCurrentContext() else {
                completion(snapshot.image)
                return
            }
            
            // Get the color for the route type
            let routeColor = self.uiColor(for: route.type)
            
            // Draw the polyline with glow effect
            let coordinates = route.locations.map(\.coordinate)
            var points = [CGPoint]()
            
            for coordinate in coordinates {
                let point = snapshot.point(for: coordinate)
                points.append(point)
            }
            
            if points.count > 1 {
                // Draw glow effect first
                context.saveGState()
                context.setShadow(offset: .zero, blur: 10, color: routeColor.withAlphaComponent(0.8).cgColor)
                context.setLineWidth(7.0)
                context.setStrokeColor(UIColor.white.cgColor)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                
                context.move(to: points[0])
                for i in 1..<points.count {
                    context.addLine(to: points[i])
                }
                context.strokePath()
                context.restoreGState()
                
                // Draw the main line
                context.setLineWidth(5.0)
                context.setStrokeColor(routeColor.cgColor)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                
                context.move(to: points[0])
                for i in 1..<points.count {
                    context.addLine(to: points[i])
                }
                context.strokePath()
            }
            
            // Draw start marker
            if let firstCoordinate = coordinates.first {
                let startPoint = snapshot.point(for: firstCoordinate)
                
                // Draw outer glow
                context.saveGState()
                context.setShadow(offset: .zero, blur: 8, color: routeColor.withAlphaComponent(0.7).cgColor)
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: CGRect(x: startPoint.x - 18, y: startPoint.y - 18, width: 36, height: 36))
                context.restoreGState()
                
                // Draw white circle background
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: CGRect(x: startPoint.x - 18, y: startPoint.y - 18, width: 36, height: 36))
                
                // Draw colored circle
                context.setFillColor(routeColor.cgColor)
                context.fillEllipse(in: CGRect(x: startPoint.x - 12, y: startPoint.y - 12, width: 24, height: 24))
                
                // Optional: Add "S" for start
                let startAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                
                let startText = "S"
                let startTextSize = (startText as NSString).size(withAttributes: startAttributes)
                let startTextRect = CGRect(
                    x: startPoint.x - startTextSize.width/2,
                    y: startPoint.y - startTextSize.height/2,
                    width: startTextSize.width,
                    height: startTextSize.height
                )
                
                (startText as NSString).draw(in: startTextRect, withAttributes: startAttributes)
            }
            
            // Draw end marker
            if let lastCoordinate = coordinates.last, coordinates.count > 1 {
                let endPoint = snapshot.point(for: lastCoordinate)
                
                // Draw outer glow
                context.saveGState()
                context.setShadow(offset: .zero, blur: 8, color: routeColor.withAlphaComponent(0.7).cgColor)
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: CGRect(x: endPoint.x - 18, y: endPoint.y - 18, width: 36, height: 36))
                context.restoreGState()
                
                // Draw white circle background
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: CGRect(x: endPoint.x - 18, y: endPoint.y - 18, width: 36, height: 36))
                
                // Draw flag icon or "F" for finish
                let finishAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                    .foregroundColor: routeColor
                ]
                
                let finishText = "F"
                let finishTextSize = (finishText as NSString).size(withAttributes: finishAttributes)
                let finishTextRect = CGRect(
                    x: endPoint.x - finishTextSize.width/2,
                    y: endPoint.y - finishTextSize.height/2,
                    width: finishTextSize.width,
                    height: finishTextSize.height
                )
                
                (finishText as NSString).draw(in: finishTextRect, withAttributes: finishAttributes)
            }
            
            // Add stylish info card at the bottom
            let cardHeight: CGFloat = 180
            let cardWidth = snapshot.image.size.width
            let cardY = snapshot.image.size.height - cardHeight
            
            // Draw card background with gradient
            let cardRect = CGRect(x: 0, y: cardY, width: cardWidth, height: cardHeight)
            
            // Create gradient for card background
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors: [CGColor] = [
                UIColor.black.withAlphaComponent(0.85).cgColor,
                UIColor.black.withAlphaComponent(0.7).cgColor
            ]
            let locations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: locations
            ) {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: cardRect.midX, y: cardRect.minY),
                    end: CGPoint(x: cardRect.midX, y: cardRect.maxY),
                    options: []
                )
            }
            
            // Add a thin accent line at the top of the card
            context.setFillColor(routeColor.cgColor)
            context.fill(CGRect(x: 0, y: cardY, width: cardWidth, height: 4))
            
            // Add distance with large stylish font
            let distanceInMiles = self.calculateDistanceInMiles(for: route)
            let distanceText = String(format: "%.1f", distanceInMiles)
            let unitText = "MI"
            
            // Draw large distance number
            let distanceAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60, weight: .black),
                .foregroundColor: UIColor.white
            ]
            
            let distanceTextSize = (distanceText as NSString).size(withAttributes: distanceAttributes)
            let distanceTextRect = CGRect(
                x: 40,
                y: cardY + 40,
                width: distanceTextSize.width,
                height: distanceTextSize.height
            )
            
            (distanceText as NSString).draw(in: distanceTextRect, withAttributes: distanceAttributes)
            
            // Draw "MI" unit next to the number
            let unitAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .heavy),
                .foregroundColor: routeColor
            ]
            
            let unitTextSize = (unitText as NSString).size(withAttributes: unitAttributes)
            let unitTextRect = CGRect(
                x: distanceTextRect.maxX + 10,
                y: distanceTextRect.midY - unitTextSize.height/2 + 10, // align with middle of distance
                width: unitTextSize.width,
                height: unitTextSize.height
            )
            
            (unitText as NSString).draw(in: unitTextRect, withAttributes: unitAttributes)
            
            // Add route name if available
            let routeName = route.name ?? routeTypeName(for: route.type)
            let routeNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let routeNameRect = CGRect(
                x: 40,
                y: distanceTextRect.maxY + 5,
                width: cardWidth - 80,
                height: 30
            )
            
            (routeName as NSString).draw(in: routeNameRect, withAttributes: routeNameAttributes)
            
            // Add date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: route.date)
            
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.lightGray
            ]
            
            let dateRect = CGRect(
                x: 40,
                y: routeNameRect.maxY + 5,
                width: cardWidth - 80,
                height: 25
            )
            
            (dateString as NSString).draw(in: dateRect, withAttributes: dateAttributes)
            
            // Add app logo and branding
            let logoText = "PLORE"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .black),
                .foregroundColor: UIColor.white
            ]
            
            let logoTextSize = (logoText as NSString).size(withAttributes: logoAttributes)
            let logoTextRect = CGRect(
                x: cardWidth - logoTextSize.width - 40,
                y: cardY + cardHeight/2 - logoTextSize.height/2,
                width: logoTextSize.width,
                height: logoTextSize.height
            )
            
            // Draw a subtle accent behind the logo
            context.saveGState()
            context.setShadow(offset: .zero, blur: 15, color: routeColor.withAlphaComponent(0.6).cgColor)
            (logoText as NSString).draw(in: logoTextRect, withAttributes: logoAttributes)
            context.restoreGState()
            
            // Get the final image
            if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
                completion(finalImage)
            } else {
                completion(snapshot.image)
            }
        }
    }
    
    /// Returns the UIColor for a route type
    private static func uiColor(for type: HKWorkoutActivityType) -> UIColor {
        switch type {
        case .walking: return UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0) // Vibrant blue
        case .running: return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Vibrant red
        case .cycling: return UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0) // Vibrant green
        default: return UIColor.gray
        }
    }
    
    /// Returns the display name for a route type
    private static func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walking Route"
        case .running: return "Running Route"
        case .cycling: return "Cycling Route"
        default: return "Activity Route"
        }
    }
    
    /// Calculate distance in miles for a route
    private static func calculateDistanceInMiles(for route: RouteInfo) -> Double {
        guard route.locations.count > 1 else {
            return 0.0
        }
        
        // Calculate total distance
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(route.locations.count - 1) {
            let current = route.locations[i]
            let next = route.locations[i + 1]
            totalDistance += current.distance(from: next)
        }
        
        // Convert to miles
        return totalDistance / 1609.34
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

