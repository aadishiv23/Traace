import Foundation
import HealthKit
import MapKit
import SwiftUI
import UIKit

// MARK: - Map Snapshot Generator

/// Helper class to generate visually appealing map snapshots
class MapSnapshotGenerator {

    struct SnapshotConfig {
        var drawRoutePolyline: Bool = true
        var routePolylineUIColor: UIColor? // Specific UIColor for polyline
        var routePolylineWidth: CGFloat = 7.0 // Slightly thicker for share
        var includeGlowEffect: Bool = true

        var drawStartMarker: Bool = true
        var startMarkerStyle: MarkerDrawingStyle = .defaultStart // Using a simplified style enum
        var drawEndMarker: Bool = true
        var endMarkerStyle: MarkerDrawingStyle = .defaultEnd

        var drawInfoCard: Bool = false
        var infoCardRouteName: String?
        var infoCardDistance: String?
        var infoCardDateString: String?
        var infoCardAppName: String? = "TRAACE" // Customizable

        var mapType: MKMapType = .standard
        var imageSize: CGSize = .init(width: 1200, height: 1200) // Default high-res for sharing
        var showsBuildings: Bool = true
        var paddingMultiplier: CGFloat = 0.25 // Increased padding for share context
    }

    enum MarkerDrawingStyle {
        case defaultStart
        case defaultEnd
        // Could add .customImage(UIImage) if needed
    }

    static func generateSnapshot(
        route: RouteInfo,
        config: SnapshotConfig,
        routeColorTheme: RouteColorTheme = .defaultTheme, // Provide a default or ensure it's passed
        completion: @escaping (UIImage?) -> Void
    ) {
        let rect = route.polyline.boundingMapRect
        let padding = max(rect.size.width, rect.size.height) * config
            .paddingMultiplier // Use max for better square fitting
        let paddedRect = MKMapRect(
            x: rect.origin.x - padding,
            y: rect.origin.y - padding,
            width: rect.size.width + (padding * 2),
            height: rect.size.height + (padding * 2)
        )

        let options = MKMapSnapshotter.Options()
        options.mapRect = paddedRect // Use mapRect for more precise control with padding
        options.mapType = config.mapType
        options.size = config.imageSize
        options.showsBuildings = config.showsBuildings
        options.scale = UIScreen.main.scale // Use screen scale for crispness

        let snapshotter = MKMapSnapshotter(options: options)

        snapshotter.start { snapshot, error in
            guard let snapshot, error == nil else {
                print("Snapshot error: \(error?.localizedDescription ?? "unknown error")")
                completion(nil)
                return
            }

            UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
            guard let context = UIGraphicsGetCurrentContext() else {
                completion(nil)
                return
            }
            defer { UIGraphicsEndImageContext() }

            snapshot.image.draw(at: .zero) // Draw the map base

            let routeUIColor = config.routePolylineUIColor ?? self.uiColor(for: route.type, theme: routeColorTheme)

            // Draw Polyline
            let coordinates = route.locations.map(\.coordinate)
            if config.drawRoutePolyline, coordinates.count > 1 {
                var points = coordinates.map { snapshot.point(for: $0) }

                if config.includeGlowEffect {
                    context.saveGState()
                    context.setShadow(offset: .zero, blur: 12, color: routeUIColor.withAlphaComponent(0.7).cgColor)
                    context.setLineWidth(config.routePolylineWidth + 2) // Glow is slightly wider
                    context.setStrokeColor(UIColor.white.withAlphaComponent(0.7).cgColor) // Whiteish glow
                    context.setLineCap(.round)
                    context.setLineJoin(.round)
                    context.addLines(between: points)
                    context.strokePath()
                    context.restoreGState()
                }

                context.setLineWidth(config.routePolylineWidth)
                context.setStrokeColor(routeUIColor.cgColor)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.addLines(between: points)
                context.strokePath()
            }

            // Draw Start Marker
            if config.drawStartMarker, let firstCoordinate = route.locations.first?.coordinate {
                drawMarker(
                    context: context,
                    snapshot: snapshot,
                    coordinate: firstCoordinate,
                    style: config.startMarkerStyle,
                    color: routeUIColor
                )
            }

            // Draw End Marker
            if config.drawEndMarker, let lastCoordinate = route.locations.last?.coordinate,
               (route.locations.count ?? 0) > 1
            {
                drawMarker(
                    context: context,
                    snapshot: snapshot,
                    coordinate: lastCoordinate,
                    style: config.endMarkerStyle,
                    color: routeUIColor
                )
            }

            // Draw Info Card (using the existing logic from the prompt, adapted)
            if config.drawInfoCard {
                drawInfoCardOnSnapshot(
                    context: context,
                    imageSize: snapshot.image.size,
                    route: route,
                    config: config,
                    routeUIColor: routeUIColor
                )
            }

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            completion(finalImage)
        }
    }

    private static func drawMarker(
        context: CGContext,
        snapshot: MKMapSnapshotter.Snapshot,
        coordinate: CLLocationCoordinate2D,
        style: MarkerDrawingStyle,
        color: UIColor
    ) {
        let point = snapshot.point(for: coordinate)
        let markerSize: CGFloat = 24 // Inner colored part
        let outerWhiteSize: CGFloat = markerSize + 12 // White background

        // Outer glow
        context.saveGState()
        context.setShadow(offset: .zero, blur: 8, color: color.withAlphaComponent(0.6).cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - outerWhiteSize / 2,
            y: point.y - outerWhiteSize / 2,
            width: outerWhiteSize,
            height: outerWhiteSize
        ))
        context.restoreGState()

        // White circle background
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(
            x: point.x - outerWhiteSize / 2,
            y: point.y - outerWhiteSize / 2,
            width: outerWhiteSize,
            height: outerWhiteSize
        ))

        switch style {
        case .defaultStart:
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(
                x: point.x - markerSize / 2,
                y: point.y - markerSize / 2,
                width: markerSize,
                height: markerSize
            ))
            // Optional: Draw 'S' or a small icon
            let sAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: markerSize * 0.6, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let sChar = "S" as NSString
            let sSize = sChar.size(withAttributes: sAttrs)
            sChar.draw(at: CGPoint(x: point.x - sSize.width / 2, y: point.y - sSize.height / 2), withAttributes: sAttrs)

        case .defaultEnd:
            // For end marker, we can draw a flag or 'F'
            let fAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: markerSize * 0.7, weight: .bold),
                .foregroundColor: color
            ]
            // Draw 'F' in the center of the white circle
            let fChar = "F" as NSString // Or use a flag emoji/image
            let fSize = fChar.size(withAttributes: fAttrs)
            fChar.draw(at: CGPoint(x: point.x - fSize.width / 2, y: point.y - fSize.height / 2), withAttributes: fAttrs)
        }
    }

    /// Original comprehensive snapshot - for "Share Default"
    static func generateRouteSnapshot( // This is the original one from the prompt, adapted
        route: RouteInfo,
        mapType: MKMapType,
        routeColorTheme: RouteColorTheme = .defaultTheme,
        completion: @escaping (UIImage?) -> Void
    ) {
        let config = SnapshotConfig(
            drawInfoCard: true, // The main difference: include the styled info card
            infoCardRouteName: route.name,
            infoCardDistance: String(format: "%.1f", calculateDistanceInMiles(for: route)),
            infoCardDateString: formattedDateMedium(route.date),
            mapType: mapType
        )
        generateSnapshot(route: route, config: config, routeColorTheme: routeColorTheme, completion: completion)
    }

    /// Base image for customizable flow (map + route line + simple markers, NO info card)
    static func generateBaseShareImage(
        route: RouteInfo,
        mapType: MKMapType,
        routeColorTheme: RouteColorTheme = .defaultTheme,
        completion: @escaping (UIImage?) -> Void
    ) {
        let config = SnapshotConfig(
            drawRoutePolyline: true,
            includeGlowEffect: true,
            drawStartMarker: true,
            startMarkerStyle: .defaultStart,
            drawEndMarker: true,
            endMarkerStyle: .defaultEnd,
            drawInfoCard: false, // Explicitly NO info card
            mapType: mapType
        )
        generateSnapshot(route: route, config: config, routeColorTheme: routeColorTheme, completion: completion)
    }

    // MARK: - Helper methods from original generator (uiColor, routeTypeName, calculateDistanceInMiles, etc.)

    /// Ensure these helpers consider the theme if necessary
    private static func uiColor(for type: HKWorkoutActivityType, theme: RouteColorTheme) -> UIColor {
        let swiftUIColor = RouteColors.color2(for: type, theme: theme)
        return UIColor(swiftUIColor)
    }

    private static func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walk"
        case .running: "Run"
        case .cycling: "Ride"
        default: "Activity"
        }
    }

    private static func calculateDistanceInMiles(for route: RouteInfo) -> Double {
        let locations = route.locations
        if locations.isEmpty { return 0.0 }

        
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(locations.count - 1) {
            totalDistance += locations[i].distance(from: locations[i + 1])
        }
        return totalDistance / 1609.34
    }

    private static func formattedDateMedium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Extracted Info Card Drawing Logic
    private static func drawInfoCardOnSnapshot(
        context: CGContext,
        imageSize: CGSize,
        route: RouteInfo,
        config: SnapshotConfig,
        routeUIColor: UIColor
    ) {
        let cardHeight: CGFloat = 180
        let cardWidth = imageSize.width
        let cardY = imageSize.height - cardHeight
        let cardRect = CGRect(x: 0, y: cardY, width: cardWidth, height: cardHeight)

        // Gradient background for card
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cardBgColors: [CGColor] = [
            UIColor.black.withAlphaComponent(0.85).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        let gradientLocations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: cardBgColors as CFArray,
            locations: gradientLocations
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: cardRect.midX, y: cardRect.minY),
                end: CGPoint(x: cardRect.midX, y: cardRect.maxY),
                options: []
            )
        }

        // Accent line
        context.setFillColor(routeUIColor.cgColor)
        context.fill(CGRect(x: 0, y: cardY, width: cardWidth, height: 5))

        let padding: CGFloat = 30

        // Distance Text
        if let distanceText = config.infoCardDistance {
            let unitText = "MI"
            let distanceAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60, weight: .black),
                .foregroundColor: UIColor.white
            ]
            let unitAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .heavy),
                .foregroundColor: routeUIColor
            ]

            let dTextSize = (distanceText as NSString).size(withAttributes: distanceAttrs)
            (distanceText as NSString).draw(at: CGPoint(x: padding, y: cardY + padding), withAttributes: distanceAttrs)
            (unitText as NSString).draw(
                at: CGPoint(
                    x: padding + dTextSize.width + 8,
                    y: cardY + padding +
                        (dTextSize.height - (unitText as NSString).size(withAttributes: unitAttrs).height) -
                        5 // adjust baseline
                ),
                withAttributes: unitAttrs
            )
        }

        // Route Name
        let routeNameText = config.infoCardRouteName ?? routeTypeName(for: route.type)
        let routeNameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        (routeNameText as NSString).draw(
            in: CGRect(
                x: padding,
                y: cardY + padding + 70,
                width: cardWidth - padding * 2 - 150 /* space for logo */,
                height: 30
            ),
            withAttributes: routeNameAttrs
        )

        // Date
        if let dateStr = config.infoCardDateString {
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.lightGray
            ]
            (dateStr as NSString).draw(
                in: CGRect(x: padding, y: cardY + padding + 70 + 30, width: cardWidth - padding * 2, height: 25),
                withAttributes: dateAttrs
            )
        }

        // App Logo/Branding
        if let appName = config.infoCardAppName {
            let logoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .black),
                .foregroundColor: UIColor.white
            ]
            let logoSize = (appName as NSString).size(withAttributes: logoAttrs)
            context.saveGState()
            context.setShadow(offset: .zero, blur: 10, color: routeUIColor.withAlphaComponent(0.5).cgColor)
            (appName as NSString).draw(
                at: CGPoint(
                    x: cardWidth - logoSize.width - padding,
                    y: cardY + cardHeight / 2 - logoSize.height / 2 + 10 // slight offset
                ),
                withAttributes: logoAttrs
            )
            context.restoreGState()
        }
    }
}

/// Placeholder for RouteColors and theme interaction
/// Assume RouteColors.colors(for: theme).color(for: type: HKWorkoutActivityType) -> Color exists
/// And Color extension for UIColor init
extension Color {
    /// If you don't have this already
    init(uiColor: UIColor) {
        self.init(UIColor(cgColor: uiColor.cgColor))
    }
}

/// And RouteColors.color(for type: HKWorkoutActivityType)
/// This needs to be adapted to your actual RouteColors structure
extension RouteColors { // Your actual RouteColors struct/enum
    func color(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking: ActivityColors.MapStyle.walking
        case .running: ActivityColors.MapStyle.running
        case .cycling: ActivityColors.MapStyle.cycling
        default: .gray
        }
    }
}

/// Assume defaultTheme exists
extension RouteColorTheme {
    static var defaultTheme: RouteColorTheme {
        .default
    }
}
