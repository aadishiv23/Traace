//
//  RouteData.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import MapKit
import HealthKit
import CoreData
import SwiftUI

/// Represents a route that can be displayed on a map
struct RouteDisplayInfo: Identifiable {
    /// Unique identifier for this route
    let id: String
    
    /// The workout activity type for this route
    let activityType: HKWorkoutActivityType
    
    /// The polyline to display on the map
    let polyline: MKPolyline
    
    /// The color to use when displaying this route
    var color: SwiftUI.Color {
        switch activityType {
        case .walking:
            return .blue
        case .running:
            return .red
        case .cycling:
            return .green
        default:
            return .gray
        }
    }
    
    /// Whether this route is a walking activity
    var isWalking: Bool {
        activityType == .walking
    }
    
    /// Whether this route is a running activity
    var isRunning: Bool {
        activityType == .running
    }
    
    /// Whether this route is a cycling activity
    var isCycling: Bool {
        activityType == .cycling
    }
}

/// Summary information about a route for display in lists
struct RouteSummaryInfo: Identifiable {
    /// Unique identifier for this route
    let id: String
    
    /// The workout activity type for this route
    let activityType: HKWorkoutActivityType
    
    /// The date the activity occurred
    let date: Date
    
    /// Whether this route is an indoor workout
    let isIndoor: Bool
    
    /// A formatted string representing the date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Returns an appropriate icon name based on the activity type
    var iconName: String {
        switch activityType {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "figure.outdoor.cycle"
        default:
            return "figure.walk"
        }
    }
    
    /// Whether this route is a walking activity
    var isWalking: Bool {
        activityType == .walking
    }
    
    /// Whether this route is a running activity
    var isRunning: Bool {
        activityType == .running
    }
    
    /// Whether this route is a cycling activity
    var isCycling: Bool {
        activityType == .cycling
    }
}

/// Criteria for filtering routes
struct RouteFilterCriteria {
    /// The date to filter by (if any)
    var date: Date?
    
    /// Whether to include walking routes
    var includeWalking: Bool = true
    
    /// Whether to include running routes
    var includeRunning: Bool = true
    
    /// Whether to include cycling routes
    var includeCycling: Bool = true
    
    /// Text to search for in route data
    var searchText: String = ""
    
    /// Returns an NSPredicate for filtering CDWorkout objects based on these criteria
    var predicate: NSPredicate? {
        var predicates: [NSPredicate] = []
        
        // Date predicate
        if let date = date {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let datePredicate = NSPredicate(format: "startDate >= %@ AND startDate < %@", startOfDay as NSDate, endOfDay as NSDate)
            predicates.append(datePredicate)
        }
        
        // Activity type predicates
        var activityTypePredicates: [NSPredicate] = []
        
        if includeWalking {
            activityTypePredicates.append(NSPredicate(format: "type == %@", String(HKWorkoutActivityType.walking.rawValue)))
        }
        
        if includeRunning {
            activityTypePredicates.append(NSPredicate(format: "type == %@", String(HKWorkoutActivityType.running.rawValue)))
        }
        
        if includeCycling {
            activityTypePredicates.append(NSPredicate(format: "type == %@", String(HKWorkoutActivityType.cycling.rawValue)))
        }
        
        // If any activity types are included, add the compound OR predicate
        if !activityTypePredicates.isEmpty {
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: activityTypePredicates))
        }
        
        // If no predicates were created, return nil
        guard !predicates.isEmpty else {
            return nil
        }
        
        // Combine all predicates with AND
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

// MARK: - SwiftUI Color Extension

import SwiftUI

extension Color {
    static var blue: Color {
        Color(red: 0.0, green: 0.48, blue: 1.0)
    }
    
    static var red: Color {
        Color(red: 1.0, green: 0.23, blue: 0.19)
    }
    
    static var green: Color {
        Color(red: 0.3, green: 0.85, blue: 0.39)
    }
} 