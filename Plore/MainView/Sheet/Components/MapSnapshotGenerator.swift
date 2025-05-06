import Foundation
import MapKit
import SwiftUI
import UIKit
import HealthKit

// MARK: - Map Snapshot Generator

/// Helper class to generate visually appealing map snapshots
import Foundation
import MapKit
import SwiftUI
import UIKit
import HealthKit

// MARK: - Map Snapshot Generator

/// Helper class to generate visually appealing map snapshots
class MapSnapshotGenerator {
    
    /// Generate a snapshot with just the route map (no overlay)
    /// - Parameters:
    ///   - route: The route information
    ///   - mapType: The type of map to display
    ///   - completion: Callback with the generated image
    static func generateCleanRouteSnapshot(
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
        options.size = CGSize(width: 1200, height: 1200) // High resolution for sharing
        options.showsBuildings = true

        // Create the snapshotter
        let snapshotter = MKMapSnapshotter(options: options)

        // Start taking the snapshot
        snapshotter.start { snapshot, error in
            guard let snapshot, error == nil else {
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
                    x: startPoint.x - startTextSize.width / 2,
                    y: startPoint.y - startTextSize.height / 2,
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
                    x: endPoint.x - finishTextSize.width / 2,
                    y: endPoint.y - finishTextSize.height / 2,
                    width: finishTextSize.width,
                    height: finishTextSize.height
                )

                (finishText as NSString).draw(in: finishTextRect, withAttributes: finishAttributes)
            }

            // Get the final image with just the map and route
            if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
                completion(finalImage)
            } else {
                completion(snapshot.image)
            }
        }
    }
    
    /// Generate a stylish snapshot of a route with the standard overlay
    /// - Parameters:
    ///   - route: The route information
    ///   - mapType: The type of map to display
    ///   - completion: Callback with the generated image
    static func generateRouteSnapshot(
        route: RouteInfo,
        mapType: MKMapType,
        completion: @escaping (UIImage?) -> Void
    ) {
        // First get a clean snapshot with just the map
        generateCleanRouteSnapshot(route: route, mapType: mapType) { mapImage in
            guard let mapImage else {
                completion(nil)
                return
            }
            
            // Now we'll pass this clean map image to create templates
            completion(mapImage)
        }
    }

    /// Returns the UIColor for a route type
    static func uiColor(for type: HKWorkoutActivityType) -> UIColor {
        switch type {
        case .walking: UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0) // Vibrant blue
        case .running: UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0) // Vibrant red
        case .cycling: UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0) // Vibrant green
        default: UIColor.gray
        }
    }

    /// Returns the display name for a route type
    static func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walking Route"
        case .running: "Running Route"
        case .cycling: "Cycling Route"
        default: "Activity Route"
        }
    }

    /// Calculate distance in miles for a route
    static func calculateDistanceInMiles(for route: RouteInfo) -> Double {
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
