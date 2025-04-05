//
//  WorkoutRoute.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import HealthKit
import MapKit

/// Represents a workout route with its associated data
class WorkoutRoute: Identifiable {
    /// Unique identifier
    let id: UUID
    
    /// Reference to the original HealthKit workout
    private let workout: HKWorkout
    
    /// Coordinates that make up the route
    private let coordinates: [CLLocationCoordinate2D]
    
    /// Activity type of the workout
    let workoutActivityType: HKWorkoutActivityType
    
    /// Date the workout started
    let startDate: Date?
    
    /// Date the workout ended
    let endDate: Date?
    
    /// Total distance in meters
    let distance: Double?
    
    /// Duration in seconds
    let duration: TimeInterval?
    
    /// Total calories burned (if available)
    let calories: Double?
    
    /// User-provided name (or auto-generated based on location/activity)
    var name: String?
    
    /// Derived polyline for map display
    lazy var polyline: MKPolyline? = {
        guard !coordinates.isEmpty else { return nil }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }()
    
    /// Formatted display distance (e.g., "2.5 km" or "800 m")
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        
        let distanceMeasurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: distanceMeasurement)
    }
    
    /// Formatted display date (e.g., "June 24, 2025")
    var formattedDate: String? {
        guard let date = startDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: date)
    }
    
    /// Formatted display time (e.g., "3:45 PM")
    var formattedTime: String? {
        guard let date = startDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
    
    /// Formatted duration (e.g., "32m 15s")
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        
        return formatter.string(from: duration)
    }
    
    /// Initializes a WorkoutRoute from HealthKit data
    /// - Parameters:
    ///   - workout: The HKWorkout with route data
    ///   - coordinates: The coordinates for the route
    ///   - name: Optional custom name
    init(workout: HKWorkout, coordinates: [CLLocationCoordinate2D], name: String? = nil) {
        self.id = UUID()
        self.workout = workout
        self.coordinates = coordinates
        self.workoutActivityType = workout.workoutActivityType
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.duration = workout.duration
        self.distance = workout.totalDistance?.doubleValue(for: .meter())
        self.calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        
        // Set name from parameter or generate one
        if let providedName = name {
            self.name = providedName
        } else {
            // Generate a name based on activity type and date
            let activityName: String
            switch workout.workoutActivityType {
            case .running:
                activityName = "Run"
            case .cycling:
                activityName = "Ride"
            case .walking:
                activityName = "Walk"
            case .hiking:
                activityName = "Hike"
            default:
                activityName = "Workout"
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dateString = dateFormatter.string(from: workout.startDate)
            
            self.name = "\(activityName) on \(dateString)"
        }
    }
}

// MARK: - Hashable Conformance

extension WorkoutRoute: Hashable {
    static func == (lhs: WorkoutRoute, rhs: WorkoutRoute) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 