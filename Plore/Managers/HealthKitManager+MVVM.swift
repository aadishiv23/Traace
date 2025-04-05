//
//  HealthKitManager+MVVM.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import HealthKit
import MapKit
import os

/// Manager class for interacting with HealthKit in the MVVM architecture
class MVVMHealthKitManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = MVVMHealthKitManager()
    
    // MARK: - Properties
    
    /// The HealthKit store
    private let healthStore = HKHealthStore()
    
    /// Logger for operations
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.aadishivmalhotra.Plore",
        category: "MVVMHealthKitManager"
    )
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Authorization
    
    /// Requests authorization for HealthKit data
    /// - Returns: Boolean indicating whether authorization was successful
    func requestAuthorization() async throws -> Bool {
        // Define the types we need to read
        let typesToRead: Set<HKObjectType> = [
            .workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        // No writing for now
        let typesToWrite: Set<HKSampleType> = []
        
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            throw HealthKitError.notAvailable
        }
        
        // Request authorization
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
                if let error = error {
                    self.logger.error("Error requesting HealthKit authorization: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                self.logger.info("HealthKit authorization request completed: \(success ? "Success" : "Failed")")
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Fetch Workouts
    
    /// Fetches workouts with routes from HealthKit
    /// - Parameters:
    ///   - startDate: The start date for the query
    ///   - endDate: The end date for the query
    /// - Returns: Array of WorkoutRoute objects
    func fetchWorkoutsWithRoutes(startDate: Date, endDate: Date) async throws -> [WorkoutRoute] {
        // Ensure authorization first
        let isAuthorized = try await requestAuthorization()
        guard isAuthorized else {
            logger.error("Not authorized to access HealthKit data")
            throw HealthKitError.notAuthorized
        }
        
        // Create the workout query
        let workoutPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Use individual workout activity type predicates and combine them
        let walkingPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let cyclingPredicate = HKQuery.predicateForWorkouts(with: .cycling)
        let hikingPredicate = HKQuery.predicateForWorkouts(with: .hiking)
        
        // Combine all activity type predicates with OR
        let workoutActivityPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            walkingPredicate, runningPredicate, cyclingPredicate, hikingPredicate
        ])
        
        // Combine date and activity predicates with AND
        let routesPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, workoutActivityPredicate])
        
        // Query workouts
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: routesPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { (_, samples, error) in
                if let error = error {
                    self.logger.error("Error querying workouts: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    self.logger.error("Could not cast samples to HKWorkout")
                    continuation.resume(throwing: HealthKitError.dataTypeMismatch)
                    return
                }
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
        
        // For each workout, get the route data
        var workoutRoutes: [WorkoutRoute] = []
        
        for workout in workouts {
            do {
                let routeData = try await fetchRouteData(for: workout)
                if !routeData.isEmpty {
                    let workoutRoute = WorkoutRoute(workout: workout, coordinates: routeData)
                    workoutRoutes.append(workoutRoute)
                }
            } catch {
                self.logger.error("Error fetching route data for workout: \(error.localizedDescription)")
                // Continue with the next workout
                continue
            }
        }
        
        return workoutRoutes
    }
    
    // MARK: - Helper Methods
    
    /// Fetches route data (coordinates) for a specific workout
    /// - Parameter workout: The workout to fetch route data for
    /// - Returns: Array of coordinates making up the route
    private func fetchRouteData(for workout: HKWorkout) async throws -> [CLLocationCoordinate2D] {
        let routeType = HKSeriesType.workoutRoute()
        
        // First, query for route samples associated with this workout
        let routeSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkoutRoute], Error>) in
            let predicate = HKQuery.predicateForObjects(from: workout)
            
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { (_, samples, error) in
                if let error = error {
                    self.logger.error("Error querying route samples: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let routes = samples as? [HKWorkoutRoute] else {
                    self.logger.error("Could not cast samples to HKWorkoutRoute")
                    continuation.resume(throwing: HealthKitError.dataTypeMismatch)
                    return
                }
                
                continuation.resume(returning: routes)
            }
            
            healthStore.execute(query)
        }
        
        // If there are no routes, return an empty array
        guard let routeSample = routeSamples.first else {
            return []
        }
        
        // Now query for the locations in this route
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocationCoordinate2D], Error>) in
            var locations: [CLLocationCoordinate2D] = []
            
            let query = HKWorkoutRouteQuery(route: routeSample) { (_, locationData, done, error) in
                if let error = error {
                    self.logger.error("Error querying route locations: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let locationData = locationData else {
                    if done {
                        continuation.resume(returning: locations)
                    }
                    return
                }
                
                // Add these locations to our array
                let newLocations = locationData.map { $0.coordinate }
                locations.append(contentsOf: newLocations)
                
                // If we're done, return the locations
                if done {
                    continuation.resume(returning: locations)
                }
            }
            
            healthStore.execute(query)
        }
    }
}
