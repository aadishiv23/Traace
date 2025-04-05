//
//  HealthKitService.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import HealthKit
import CoreLocation
import os

/// Service responsible for all HealthKit interactions, providing raw data to higher level components
class HealthKitService {
    // MARK: - Properties
    
    /// The object acting as access point for all HealthKit data
    private let healthStore = HKHealthStore()
    
    /// Logger object for logging operations
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "com.aadishivmalhotra.Plore.HealthKitService"
    )
    
    // MARK: - Permissions
    
    /// Requests authorization to access HealthKit data
    /// - Returns: Success status of the authorization request
    func requestAuthorization() async throws {
        let typesToRequest: Set = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            throw HealthKitServiceError.healthKitNotAvailable
        }
        
        // Request authorization
        try await healthStore.requestAuthorization(toShare: typesToRequest, read: typesToRequest)
        logger.info("HealthKit authorization successfully requested")
    }
    
    // MARK: - Workout Fetching
    
    /// Fetches workouts of a specific activity type
    /// - Parameter type: The HealthKit workout activity type to fetch
    /// - Returns: Array of HKWorkout objects
    func fetchWorkouts(of type: HKWorkoutActivityType) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForWorkouts(with: type)
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetches workouts that have occurred since a specified date
    /// - Parameter since: Date to fetch workouts from
    /// - Returns: Array of HKWorkout objects
    func fetchWorkouts(since date: Date) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: date,
                end: Date(),
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Route Fetching
    
    /// Fetches all route data for a specific workout
    /// - Parameter workout: The HKWorkout to fetch routes for
    /// - Returns: Array of location arrays, each representing a route
    func fetchRouteLocations(for workout: HKWorkout) async throws -> [[CLLocation]] {
        // First, fetch the route objects
        let routes = try await fetchRoutes(for: workout)
        
        // Then fetch the locations for each route
        var allLocations: [[CLLocation]] = []
        for route in routes {
            let locations = try await loadLocationsFromRoute(route)
            allLocations.append(locations)
        }
        
        return allLocations
    }
    
    /// Fetches HKWorkoutRoute objects for a specific workout
    private func fetchRoutes(for workout: HKWorkout) async throws -> [HKWorkoutRoute] {
        try await withCheckedThrowingContinuation { continuation in
            let routeType = HKSeriesType.workoutRoute()
            let predicate = HKQuery.predicateForObjects(from: workout)
            
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let routes = samples as? [HKWorkoutRoute] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: routes)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Loads location data from a single route
    private func loadLocationsFromRoute(_ route: HKWorkoutRoute) async throws -> [CLLocation] {
        try await withCheckedThrowingContinuation { continuation in
            var locations: [CLLocation] = []
            
            let query = HKWorkoutRouteQuery(route: route) { _, newLocations, done, error in
                if let error = error {
                    self.logger.error("Error loading route data: \(error.localizedDescription)")
                    if done {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                
                if let newLocations = newLocations {
                    locations.append(contentsOf: newLocations)
                }
                
                if done {
                    continuation.resume(returning: locations)
                }
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

/// Errors that can occur in HealthKitService
enum HealthKitServiceError: Error {
    case healthKitNotAvailable
    case authorizationDenied
    case noDataAvailable
} 