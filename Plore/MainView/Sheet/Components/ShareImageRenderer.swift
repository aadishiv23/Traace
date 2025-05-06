//
//  ShareImageRenderer.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/5/25.
//

import Foundation
import Foundation
import UIKit
import MapKit
import HealthKit

/// Utility class to generate different template images for route sharing
import Foundation
import UIKit
import MapKit
import HealthKit

/// Utility class to generate different template images for route sharing
class ShareImageRenderer {
    
    // MARK: - Template Generators
    
    /// Creates a standard template with route and statistics
    /// - Parameters:
    ///   - baseImage: The base map image with the route
    ///   - route: The route information
    ///   - routeColor: The color for the route
    ///   - customizations: Customization options for the image
    /// - Returns: A rendered UIImage
    static func createStandardTemplate(
        baseImage: UIImage,
        route: RouteInfo,
        routeColor: UIColor,
        customizations: ShareCustomizations
    ) -> UIImage {
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(baseImage.size, true, baseImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return baseImage
        }
        
        // Draw the base image
        baseImage.draw(at: .zero)
        
        // Add info card at the bottom
        let cardHeight: CGFloat = 180
        let cardWidth = baseImage.size.width
        let cardY = baseImage.size.height - cardHeight
        
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
        
        // Calculate distance in miles
        let distanceInMiles = calculateDistanceInMiles(for: route)
        
        if customizations.showDistance {
            // Add distance with large stylish font
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
                y: distanceTextRect.midY - unitTextSize.height / 2 + 10, // align with middle of distance
                width: unitTextSize.width,
                height: unitTextSize.height
            )
            
            (unitText as NSString).draw(in: unitTextRect, withAttributes: unitAttributes)
        }
        
        // Add route name if available and if customization is enabled
        if customizations.showRouteName {
            let routeName = route.name ?? routeTypeName(for: route.type)
            let routeNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let routeNameRect = CGRect(
                x: 40,
                y: customizations.showDistance ? cardY + 120 : cardY + 60,
                width: cardWidth - 80,
                height: 30
            )
            
            (routeName as NSString).draw(in: routeNameRect, withAttributes: routeNameAttributes)
        }
        
        // Add date if customization is enabled
        if customizations.showDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: route.date)
            
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.lightGray
            ]
            
            let yPosition: CGFloat
            if customizations.showRouteName {
                yPosition = customizations.showDistance ? cardY + 155 : cardY + 95
            } else {
                yPosition = customizations.showDistance ? cardY + 120 : cardY + 60
            }
            
            let dateRect = CGRect(
                x: 40,
                y: yPosition,
                width: cardWidth - 80,
                height: 25
            )
            
            (dateString as NSString).draw(in: dateRect, withAttributes: dateAttributes)
        }
        
        // Add app logo and branding if customization is enabled
        if customizations.showBranding {
            let logoText = "TRAACE"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .black),
                .foregroundColor: UIColor.white
            ]
            
            let logoTextSize = (logoText as NSString).size(withAttributes: logoAttributes)
            let logoTextRect = CGRect(
                x: cardWidth - logoTextSize.width - 40,
                y: cardY + cardHeight / 2 - logoTextSize.height / 2,
                width: logoTextSize.width,
                height: logoTextSize.height
            )
            
            // Draw a subtle accent behind the logo
            context.saveGState()
            context.setShadow(offset: .zero, blur: 15, color: routeColor.withAlphaComponent(0.6).cgColor)
            (logoText as NSString).draw(in: logoTextRect, withAttributes: logoAttributes)
            context.restoreGState()
        }
        
        // Return the final image
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            return finalImage
        } else {
            return baseImage
        }
    }
    
    /// Creates a minimal template with just the route map and minimal info
    /// - Parameters:
    ///   - baseImage: The base map image with the route
    ///   - route: The route information
    ///   - routeColor: The color for the route
    ///   - customizations: Customization options for the image
    /// - Returns: A rendered UIImage
    static func createMinimalTemplate(
        baseImage: UIImage,
        route: RouteInfo,
        routeColor: UIColor,
        customizations: ShareCustomizations
    ) -> UIImage {
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(baseImage.size, true, baseImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return baseImage
        }
        
        // Extract just the map portion from the base image
        // to avoid showing any info panels from the original image
        let mapSourceRect = CGRect(
            x: 0,
            y: 0,
            width: baseImage.size.width,
            height: baseImage.size.height
        )
        
        if let cgImage = baseImage.cgImage?.cropping(to: mapSourceRect.applying(CGAffineTransform(scaleX: baseImage.scale, y: baseImage.scale))) {
            let mapOnlyImage = UIImage(cgImage: cgImage, scale: baseImage.scale, orientation: baseImage.imageOrientation)
            mapOnlyImage.draw(at: .zero)
        } else {
            // Fallback if we can't crop the image
            baseImage.draw(at: .zero)
        }
        
        // Add a subtle gradient overlay at the bottom for text legibility
        let gradientHeight: CGFloat = 150
        let gradientWidth = baseImage.size.width
        let gradientY = baseImage.size.height - gradientHeight
        
        // Create gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor
        ]
        let locations: [CGFloat] = [0.0, 1.0]
        
        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: gradientWidth / 2, y: gradientY),
                end: CGPoint(x: gradientWidth / 2, y: gradientY + gradientHeight),
                options: []
            )
        }
        
        // Add minimal info at the bottom right
        let padding: CGFloat = 30
        let bottomY = baseImage.size.height - padding
        
        if customizations.showDistance {
            // Add distance
            let distanceInMiles = calculateDistanceInMiles(for: route)
            let distanceText = String(format: "%.1f MI", distanceInMiles)
            
            let distanceAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let distanceTextSize = (distanceText as NSString).size(withAttributes: distanceAttributes)
            let distanceTextRect = CGRect(
                x: baseImage.size.width - distanceTextSize.width - padding,
                y: bottomY - distanceTextSize.height,
                width: distanceTextSize.width,
                height: distanceTextSize.height
            )
            
            // Add a small shadow for better visibility
            context.saveGState()
            context.setShadow(offset: CGSize(width: 1, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            (distanceText as NSString).draw(in: distanceTextRect, withAttributes: distanceAttributes)
            context.restoreGState()
        }
        
        if customizations.showRouteName && customizations.showBranding {
            // Add app name and route name in small text at the bottom left
            let combinedText = "TRAACE • \(route.name ?? routeTypeName(for: route.type))"
            
            let combinedAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            
            let combinedTextRect = CGRect(
                x: padding,
                y: bottomY - 20,
                width: baseImage.size.width - (2 * padding),
                height: 20
            )
            
            // Add a small shadow for better visibility
            context.saveGState()
            context.setShadow(offset: CGSize(width: 1, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            (combinedText as NSString).draw(in: combinedTextRect, withAttributes: combinedAttributes)
            context.restoreGState()
        } else if customizations.showRouteName {
            // Just show route name
            let routeName = route.name ?? routeTypeName(for: route.type)
            
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            
            let nameTextRect = CGRect(
                x: padding,
                y: bottomY - 20,
                width: baseImage.size.width - (2 * padding),
                height: 20
            )
            
            // Add a small shadow for better visibility
            context.saveGState()
            context.setShadow(offset: CGSize(width: 1, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            (routeName as NSString).draw(in: nameTextRect, withAttributes: nameAttributes)
            context.restoreGState()
        } else if customizations.showBranding {
            // Just show app name
            let appName = "TRAACE"
            
            let appNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let appNameTextRect = CGRect(
                x: padding,
                y: bottomY - 20,
                width: baseImage.size.width - (2 * padding),
                height: 20
            )
            
            // Add a small shadow for better visibility
            context.saveGState()
            context.setShadow(offset: CGSize(width: 1, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            (appName as NSString).draw(in: appNameTextRect, withAttributes: appNameAttributes)
            context.restoreGState()
        }
        
        // Return the final image
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            return finalImage
        } else {
            return baseImage
        }
    }
    
    /// Creates a statistics-focused template with detailed stats about the route
    /// - Parameters:
    ///   - baseImage: The base map image with the route
    ///   - route: The route information
    ///   - routeColor: The color for the route
    ///   - customizations: Customization options for the image
    /// - Returns: A rendered UIImage
    static func createStatisticsTemplate(
        baseImage: UIImage,
        route: RouteInfo,
        routeColor: UIColor,
        customizations: ShareCustomizations
    ) -> UIImage {
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(baseImage.size, true, baseImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return baseImage
        }
        
        // Calculate dimensions for the map area
        let imageHeight = baseImage.size.height * 0.7 // Use top 70% for map
        let imageRect = CGRect(x: 0, y: 0, width: baseImage.size.width, height: imageHeight)
        
        // Extract just the map portion from the base image
        let mapSourceRect = CGRect(
            x: 0,
            y: 0,
            width: baseImage.size.width,
            height: baseImage.size.height * 0.85 // Top 85% of the image (avoiding info panel at bottom)
        )
        
        if let cgImage = baseImage.cgImage?.cropping(to: mapSourceRect.applying(CGAffineTransform(scaleX: baseImage.scale, y: baseImage.scale))) {
            let mapOnlyImage = UIImage(cgImage: cgImage, scale: baseImage.scale, orientation: baseImage.imageOrientation)
            mapOnlyImage.draw(in: imageRect)
        } else {
            // Fallback if we can't crop the image
            baseImage.draw(in: imageRect)
        }
        
        // Fill the bottom 30% with a background
        let statsHeight = baseImage.size.height - imageHeight
        let statsRect = CGRect(x: 0, y: imageHeight, width: baseImage.size.width, height: statsHeight)
        
        // Create a gradient background for stats
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [
            routeColor.withAlphaComponent(0.9).cgColor,
            routeColor.withAlphaComponent(0.8).cgColor
        ]
        let locations: [CGFloat] = [0.0, 1.0]
        
        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: statsRect.midX, y: statsRect.minY),
                end: CGPoint(x: statsRect.midX, y: statsRect.maxY),
                options: []
            )
        }
        
        // Add route name as a title
        if customizations.showRouteName {
            let routeName = route.name ?? routeTypeName(for: route.type)
            let routeNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let routeNameRect = CGRect(
                x: 30,
                y: imageHeight + 20,
                width: baseImage.size.width - 60,
                height: 34
            )
            
            (routeName as NSString).draw(in: routeNameRect, withAttributes: routeNameAttributes)
        }
        
        // Add date if requested
        if customizations.showDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: route.date)
            
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            
            let dateRect = CGRect(
                x: 30,
                y: customizations.showRouteName ? imageHeight + 60 : imageHeight + 25,
                width: baseImage.size.width - 60,
                height: 20
            )
            
            (dateString as NSString).draw(in: dateRect, withAttributes: dateAttributes)
        }
        
        // Calculate vertical position for stats
        let statsStartY: CGFloat
        if customizations.showRouteName && customizations.showDate {
            statsStartY = imageHeight + 90
        } else if customizations.showRouteName || customizations.showDate {
            statsStartY = imageHeight + 55
        } else {
            statsStartY = imageHeight + 20
        }
        
        // Add detailed stats in a grid layout
        if customizations.showDistance {
            // Distance stat
            let distanceInMiles = calculateDistanceInMiles(for: route)
            drawStatItem(
                in: context,
                title: "DISTANCE",
                value: String(format: "%.2f", distanceInMiles),
                unit: "MI",
                rect: CGRect(
                    x: 30,
                    y: statsStartY,
                    width: (baseImage.size.width - 90) / 2,
                    height: 60
                )
            )
            
            // Pace stat (placeholder)
            drawStatItem(
                in: context,
                title: "AVG. PACE",
                value: "8:42",
                unit: "MIN/MI",
                rect: CGRect(
                    x: baseImage.size.width / 2 + 15,
                    y: statsStartY,
                    width: (baseImage.size.width - 90) / 2,
                    height: 60
                )
            )
            
            // Calories stat (placeholder)
            drawStatItem(
                in: context,
                title: "CALORIES",
                value: "389",
                unit: "KCAL",
                rect: CGRect(
                    x: 30,
                    y: statsStartY + 70,
                    width: (baseImage.size.width - 90) / 2,
                    height: 60
                )
            )
            
            // Duration stat (placeholder)
            drawStatItem(
                in: context,
                title: "DURATION",
                value: "42:18",
                unit: "MIN",
                rect: CGRect(
                    x: baseImage.size.width / 2 + 15,
                    y: statsStartY + 70,
                    width: (baseImage.size.width - 90) / 2,
                    height: 60
                )
            )
        }
        
        // Add app branding if requested
        if customizations.showBranding {
            let appName = "TRAACE"
            let appNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            
            let appNameRect = CGRect(
                x: baseImage.size.width - 80,
                y: baseImage.size.height - 30,
                width: 70,
                height: 20
            )
            
            (appName as NSString).draw(in: appNameRect, withAttributes: appNameAttributes)
        }
        
        // Return the final image
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            return finalImage
        } else {
            return baseImage
        }
    }
    
    /// Creates a vintage/retro styled template
    /// - Parameters:
    ///   - baseImage: The base map image with the route
    ///   - route: The route information
    ///   - routeColor: The color for the route
    ///   - customizations: Customization options for the image
    /// - Returns: A rendered UIImage
    static func createVintageTemplate(
        baseImage: UIImage,
        route: RouteInfo,
        routeColor: UIColor,
        customizations: ShareCustomizations
    ) -> UIImage {
        // We need to extract just the map with route from the baseImage
        // For this, we'll create a fresh snapshot with only the map data
        let originalImageSize = baseImage.size
        
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(originalImageSize, true, baseImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return baseImage
        }
        
        // Fill background with a vintage paper color
        context.setFillColor(UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0).cgColor)
        context.fill(CGRect(origin: .zero, size: originalImageSize))
        
        // Draw a border
        let borderWidth: CGFloat = 15
        let innerRect = CGRect(
            x: borderWidth,
            y: borderWidth,
            width: originalImageSize.width - (borderWidth * 2),
            height: originalImageSize.height - (borderWidth * 2)
        )
        
        // Create a vintage frame look
        context.setStrokeColor(UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0).cgColor)
        context.setLineWidth(2)
        context.stroke(innerRect)
        
        // Get just the core map area from the base image
        // We assume the map is the upper part of the image, above any info panels
        // We'll extract from the original image to avoid any overlaid content
        let mapRect = CGRect(
            x: 0,
            y: 0,
            width: baseImage.size.width,
            height: baseImage.size.height * 0.85 // Top 85% of the image (avoiding info panel at bottom)
        )
        
        if let cgImage = baseImage.cgImage?.cropping(to: mapRect.applying(CGAffineTransform(scaleX: baseImage.scale, y: baseImage.scale))) {
            let mapOnlyImage = UIImage(cgImage: cgImage, scale: baseImage.scale, orientation: baseImage.imageOrientation)
            
            // Draw the map inside the frame with a paper texture overlay
            mapOnlyImage.draw(in: CGRect(
                x: borderWidth + 10,
                y: borderWidth + 10,
                width: originalImageSize.width - (borderWidth * 2) - 20,
                height: originalImageSize.height - (borderWidth * 2) - 120 // Leave space at bottom for text
            ))
        } else {
            // Fallback if we can't crop the image
            baseImage.draw(in: CGRect(
                x: borderWidth + 10,
                y: borderWidth + 10,
                width: originalImageSize.width - (borderWidth * 2) - 20,
                height: originalImageSize.height - (borderWidth * 2) - 120 // Leave space at bottom for text
            ))
        }
        
        // Add a sepia filter effect (simulated here)
        context.setFillColor(UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 0.2).cgColor)
        context.fill(CGRect(
            x: borderWidth + 10,
            y: borderWidth + 10,
            width: originalImageSize.width - (borderWidth * 2) - 20,
            height: originalImageSize.height - (borderWidth * 2) - 120
        ))
        
        // Add a title section at the bottom
        let titleY = baseImage.size.height - borderWidth - 110
        
        if customizations.showRouteName {
            let routeName = route.name ?? routeTypeName(for: route.type)
            
            // Add a vintage-styled title
            let routeNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia", size: 28) ?? UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
            ]
            
            let routeNameRect = CGRect(
                x: borderWidth + 10,
                y: titleY,
                width: baseImage.size.width - (borderWidth * 2) - 20,
                height: 34
            )
            
            (routeName as NSString).draw(in: routeNameRect, withAttributes: routeNameAttributes)
        }
        
        if customizations.showDistance {
            // Show distance in vintage style
            let distanceInMiles = calculateDistanceInMiles(for: route)
            let distanceText = String(format: "Distance: %.1f miles", distanceInMiles)
            
            let distanceAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia", size: 18) ?? UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
            ]
            
            let distanceRect = CGRect(
                x: borderWidth + 10,
                y: customizations.showRouteName ? titleY + 40 : titleY,
                width: baseImage.size.width - (borderWidth * 2) - 20,
                height: 20
            )
            
            (distanceText as NSString).draw(in: distanceRect, withAttributes: distanceAttributes)
        }
        
        if customizations.showDate {
            // Show date in vintage style
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Recorded on " + dateFormatter.string(from: route.date)
            
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia-Italic", size: 16) ?? UIFont.italicSystemFont(ofSize: 16),
                .foregroundColor: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.8)
            ]
            
            let yPosition: CGFloat
            if customizations.showRouteName && customizations.showDistance {
                yPosition = titleY + 65
            } else if customizations.showRouteName || customizations.showDistance {
                yPosition = titleY + 40
            } else {
                yPosition = titleY
            }
            
            let dateRect = CGRect(
                x: borderWidth + 10,
                y: yPosition,
                width: baseImage.size.width - (borderWidth * 2) - 20,
                height: 20
            )
            
            (dateString as NSString).draw(in: dateRect, withAttributes: dateAttributes)
        }
        
        // Add branding if requested
        if customizations.showBranding {
            let appName = "TRAACE"
            let appNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.7)
            ]
            
            let appNameSize = (appName as NSString).size(withAttributes: appNameAttributes)
            let appNameRect = CGRect(
                x: baseImage.size.width - borderWidth - appNameSize.width - 20,
                y: baseImage.size.height - borderWidth - 30,
                width: appNameSize.width,
                height: appNameSize.height
            )
            
            (appName as NSString).draw(in: appNameRect, withAttributes: appNameAttributes)
        }
        
        // Return the final image
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            return finalImage
        } else {
            return baseImage
        }
    }
    
    /// Creates a dark themed template
    /// - Parameters:
    ///   - baseImage: The base map image with the route
    ///   - route: The route information
    ///   - routeColor: The color for the route
    ///   - customizations: Customization options for the image
    /// - Returns: A rendered UIImage
    static func createDarkTemplate(
        baseImage: UIImage,
        route: RouteInfo,
        routeColor: UIColor,
        customizations: ShareCustomizations
    ) -> UIImage {
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(baseImage.size, true, baseImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return baseImage
        }
        
        // Fill with dark background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: baseImage.size))
        
        // Draw the map image in a rounded rectangle with inset
        let padding: CGFloat = 20
        let mapRect = CGRect(
            x: padding,
            y: padding,
            width: baseImage.size.width - (padding * 2),
            height: baseImage.size.height - (padding * 2) - 100 // Leave space for info
        )
        
        // Extract just the map portion from the base image
        // We'll extract from the original image to avoid any overlaid content
        let mapSourceRect = CGRect(
            x: 0,
            y: 0,
            width: baseImage.size.width,
            height: baseImage.size.height * 0.85 // Top 85% of the image (avoiding info panel at bottom)
        )
        
        // Create a rounded rect path for clipping
        let roundedRectPath = UIBezierPath(
            roundedRect: mapRect,
            cornerRadius: 20
        )
        
        // Clip to the rounded rect
        roundedRectPath.addClip()
        
        // Draw the map image
        if let cgImage = baseImage.cgImage?.cropping(to: mapSourceRect.applying(CGAffineTransform(scaleX: baseImage.scale, y: baseImage.scale))) {
            let mapOnlyImage = UIImage(cgImage: cgImage, scale: baseImage.scale, orientation: baseImage.imageOrientation)
            mapOnlyImage.draw(in: mapRect)
        } else {
            // Fallback if we can't crop the image
            baseImage.draw(in: mapRect)
        }
        
        // Reset clipping
        context.resetClip()
        
        // Draw a glow around the map
        context.saveGState()
        context.setShadow(
            offset: .zero,
            blur: 15,
            color: routeColor.withAlphaComponent(0.8).cgColor
        )
        context.setStrokeColor(routeColor.cgColor)
        context.setLineWidth(3)
        context.stroke(roundedRectPath.cgPath as! CGRect)
        context.restoreGState()
        
        // Add info section at the bottom
        let infoY = baseImage.size.height - 100 + padding / 2
        
        // Draw horizontal divider
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: 40, y: infoY))
        dividerPath.addLine(to: CGPoint(x: baseImage.size.width - 40, y: infoY))
        
        context.saveGState()
        context.setShadow(
            offset: .zero,
            blur: 5,
            color: routeColor.withAlphaComponent(0.6).cgColor
        )
        context.setStrokeColor(routeColor.cgColor)
        context.setLineWidth(2)
        context.addPath(dividerPath.cgPath)
        context.strokePath()
        context.restoreGState()
        
        if customizations.showRouteName {
            // Add route name
            let routeName = route.name ?? routeTypeName(for: route.type)
            let routeNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let routeNameRect = CGRect(
                x: 40,
                y: infoY + 15,
                width: baseImage.size.width - 80,
                height: 30
            )
            
            (routeName as NSString).draw(in: routeNameRect, withAttributes: routeNameAttributes)
        }
        
        if customizations.showDistance {
            // Format distance
            let distanceInMiles = calculateDistanceInMiles(for: route)
            
            // Layout depends on whether we're showing the route name
            if customizations.showRouteName {
                // Distance on right side
                let distanceText = String(format: "%.1f MI", distanceInMiles)
                let distanceAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .semibold),
                    .foregroundColor: routeColor
                ]
                
                let distanceSize = (distanceText as NSString).size(withAttributes: distanceAttributes)
                let distanceRect = CGRect(
                    x: baseImage.size.width - distanceSize.width - 40,
                    y: infoY + 15,
                    width: distanceSize.width,
                    height: 30
                )
                
                (distanceText as NSString).draw(in: distanceRect, withAttributes: distanceAttributes)
            } else {
                // Distance centered
                let distanceText = String(format: "%.1f", distanceInMiles)
                let unitText = "MI"
                
                let distanceAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                
                let unitAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                    .foregroundColor: routeColor
                ]
                
                let distanceSize = (distanceText as NSString).size(withAttributes: distanceAttributes)
                let unitSize = (unitText as NSString).size(withAttributes: unitAttributes)
                
                let totalWidth = distanceSize.width + unitSize.width + 8
                let startX = (baseImage.size.width - totalWidth) / 2
                
                let distanceRect = CGRect(
                    x: startX,
                    y: infoY + 15,
                    width: distanceSize.width,
                    height: 36
                )
                
                let unitRect = CGRect(
                    x: startX + distanceSize.width + 8,
                    y: infoY + 25, // Vertically aligned with distance
                    width: unitSize.width,
                    height: 20
                )
                
                (distanceText as NSString).draw(in: distanceRect, withAttributes: distanceAttributes)
                (unitText as NSString).draw(in: unitRect, withAttributes: unitAttributes)
            }
        }
        
        if customizations.showDate {
            // Format date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: route.date)
            
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.lightGray
            ]
            
            let dateRect = CGRect(
                x: 40,
                y: infoY + 50,
                width: baseImage.size.width - 80,
                height: 20
            )
            
            (dateString as NSString).draw(in: dateRect, withAttributes: dateAttributes)
        }
        
        if customizations.showBranding {
            // Add app branding
            let appName = "TRAACE"
            let appNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .black),
                .foregroundColor: routeColor.withAlphaComponent(0.8)
            ]
            
            let appNameSize = (appName as NSString).size(withAttributes: appNameAttributes)
            let appNameRect = CGRect(
                x: baseImage.size.width - appNameSize.width - 40,
                y: customizations.showDate ? infoY + 50 : infoY + 55,
                width: appNameSize.width,
                height: 20
            )
            
            (appName as NSString).draw(in: appNameRect, withAttributes: appNameAttributes)
        }
        
        // Return the final image
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            return finalImage
        } else {
            return baseImage
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper function to draw stat items for the statistics template
    private static func drawStatItem(
        in context: CGContext,
        title: String,
        value: String,
        unit: String,
        rect: CGRect
    ) {
        // Draw stat title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        let titleRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: 15
        )
        
        (title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw stat value
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let valueRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y + 20,
            width: rect.width,
            height: 26
        )
        
        (value as NSString).draw(in: valueRect, withAttributes: valueAttributes)
        
        // Draw unit
        let unitAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        
        let unitRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y + 48,
            width: rect.width,
            height: 14
        )
        
        (unit as NSString).draw(in: unitRect, withAttributes: unitAttributes)
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
