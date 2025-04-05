//
//  PolylineFactory.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import MapKit
import CoreLocation
import os

/// Service responsible for creating and simplifying map polylines from location data
class PolylineFactory {
    // MARK: - Properties
    
    /// Logger for logging operations
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "com.aadishivmalhotra.Plore.PolylineFactory"
    )
    
    // MARK: - Polyline Creation
    
    /// Creates an MKPolyline from an array of CLLocation objects
    /// - Parameter locations: Array of CLLocation points
    /// - Returns: An MKPolyline representing the route
    func createPolyline(from locations: [CLLocation]) -> MKPolyline {
        let coordinates = locations.map { $0.coordinate }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    /// Simplifies a route by removing points that are within a specified tolerance
    /// - Parameters:
    ///   - locations: The original array of CLLocation points
    ///   - tolerance: The minimum distance between points (in meters)
    /// - Returns: A simplified array of CLLocation points
    func simplifyRoute(locations: [CLLocation], tolerance: CLLocationDistance = 10) -> [CLLocation] {
        guard let first = locations.first else {
            logger.debug("Cannot simplify empty route")
            return []
        }
        
        var simplified = [first]
        for loc in locations.dropFirst() {
            if loc.distance(from: simplified.last!) > tolerance {
                simplified.append(loc)
            }
        }
        
        let reductionPercentage = (1.0 - Double(simplified.count) / Double(locations.count)) * 100.0
        logger.debug("Route simplified from \(locations.count) to \(simplified.count) points (\(reductionPercentage)% reduction)")
        
        return simplified
    }
    
    /// Advanced route simplification using the Ramer-Douglas-Peucker algorithm
    /// - Parameters:
    ///   - locations: The original array of CLLocation points
    ///   - epsilon: The maximum distance from a point to a line segment
    /// - Returns: A simplified array of CLLocation points
    func simplifyRouteRDP(locations: [CLLocation], epsilon: Double = 20.0) -> [CLLocation] {
        guard locations.count > 2 else {
            return locations
        }
        
        // Find the point with the maximum distance
        var dmax = 0.0
        var index = 0
        
        let first = locations.first!
        let last = locations.last!
        
        for i in 1..<locations.count-1 {
            let d = perpendicularDistance(from: locations[i], to: first, and: last)
            if d > dmax {
                index = i
                dmax = d
            }
        }
        
        // If max distance is greater than epsilon, recursively simplify
        if dmax > epsilon {
            // Recursive call
            let firstPart = simplifyRouteRDP(locations: Array(locations[0...index]), epsilon: epsilon)
            let secondPart = simplifyRouteRDP(locations: Array(locations[index..<locations.count]), epsilon: epsilon)
            
            // Build the result list
            return Array(firstPart.dropLast()) + secondPart
        } else {
            // Return start and end points only
            return [first, last]
        }
    }
    
    // MARK: - Helpers
    
    /// Calculates the perpendicular distance from a point to a line defined by two points
    private func perpendicularDistance(from point: CLLocation, to lineStart: CLLocation, and lineEnd: CLLocation) -> Double {
        let x = point.coordinate.longitude
        let y = point.coordinate.latitude
        let x1 = lineStart.coordinate.longitude
        let y1 = lineStart.coordinate.latitude
        let x2 = lineEnd.coordinate.longitude
        let y2 = lineEnd.coordinate.latitude
        
        // Line equation Ax + By + C = 0
        let A = y2 - y1
        let B = x1 - x2
        let C = x2 * y1 - x1 * y2
        
        // Distance formula d = |Ax + By + C| / sqrt(A² + B²)
        return abs(A * x + B * y + C) / sqrt(A * A + B * B)
    }
} 