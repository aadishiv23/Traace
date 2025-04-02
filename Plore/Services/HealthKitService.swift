//
//  HealthKitService.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/1/25.
//

import Foundation
import HealthKit
import CoreLocation
import os // For logging

// MARK: - Protocols for Mocking

/// Protocol mirroring HKHealthStore methods used by HealthKitService for testability.
protocol HKHealthStoreProtocol {
    static func isHealthDataAvailable() -> Bool
    func requestAuthorization(toShare shareTypes: Set<HKSampleType>?, read readTypes: Set<HKObjectType>?) async throws -> Bool
    func execute(_ query: HKQuery)
    // Add other methods if needed in the future
}

/// Make HKHealthStore conform to the protocol
extension HKHealthStore: HKHealthStoreProtocol {}

// MARK: - HealthKitService

/// A service dedicated to handling all interactions with Apple HealthKit.
final class HealthKitService {

    // MARK: Properties

    private let healthStore: HKHealthStoreProtocol // Use protocol for injection
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "HealthKitService")

    // Define the types of data we want to read/write
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute()
    ]
    // If you needed to write data, define shareTypes similarly

    // MARK: Initialization

    /// Initializes the service with a health store instance.
    /// - Parameter healthStore: An object conforming to HKHealthStoreProtocol (defaults to HKHealthStore()).
    init(healthStore: HKHealthStoreProtocol = HKHealthStore()) {
        self.healthStore = healthStore
    }

    // MARK: - Authorization

    /// Requests authorization from the user to read specified HealthKit data types.
    /// Throws an error if HealthKit data is unavailable or authorization fails.
    func requestAuthorization() async throws {
        guard type(of: healthStore).isHealthDataAvailable() else {
            logger.error("HealthKit data is not available on this device.")
            throw HealthKitError.healthDataUnavailable
        }

        do {
            // Using `requestAuthorization(toShare:read:)` returns Bool, but throws on error.
            // We don't strictly need the Bool return if we just care about catching errors.
            let success = try await healthStore.requestAuthorization(toShare: nil, read: readTypes)
            if success {
                 logger.info("HealthKit authorization request successful (or already granted).")
            } else {
                 logger.warning("HealthKit authorization request denied or pending.")
                 // You might choose to throw an error here if denial needs specific handling
                 // throw HealthKitError.authorizationDenied
            }
        } catch {
            logger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
            throw HealthKitError.authorizationFailed(error)
        }
    }

    // MARK: - Fetching Workouts

    /// Fetches HKWorkouts from HealthKit based on optional criteria.
    /// - Parameters:
    ///   - startDate: Only fetch workouts starting on or after this date.
    ///   - endDate: Only fetch workouts starting before this date.
    ///   - workoutType: Filter by a specific HKWorkoutActivityType.
    /// - Returns: An array of HKWorkout objects matching the criteria.
    /// - Throws: HealthKitError if the query fails.
    func fetchWorkouts(
        startDate: Date? = nil,
        endDate: Date? = nil,
        workoutType: HKWorkoutActivityType? = nil
    ) async throws -> [HKWorkout] {

        // Build the predicate
        var predicates: [NSPredicate] = []

        if let workoutType = workoutType {
            predicates.append(HKQuery.predicateForWorkouts(with: workoutType))
        }

        // Use .strictStartDate and .strictEndDate to avoid partial overlaps if needed
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
        predicates.append(datePredicate)

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        // Define sort descriptor (optional, newest first is common)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // Use continuation for the async/await pattern with HKSampleQuery
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    self.logger.error("Failed to fetch workouts: \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    // This case should ideally not happen if error is nil, but good to handle
                    self.logger.warning("Fetched samples were not HKWorkout type or nil.")
                    continuation.resume(returning: [])
                    return
                }
                 self.logger.info("Successfully fetched \(workouts.count) workouts.")
                continuation.resume(returning: workouts)
            }
            // Execute the query
            healthStore.execute(query)
        }
    }

    // MARK: - Fetching Route Locations

    /// Fetches all CLLocation points for the route(s) associated with a specific HKWorkout.
    /// - Parameter workout: The HKWorkout for which to fetch route data.
    /// - Returns: An array of CLLocation objects representing the route points.
    /// - Throws: HealthKitError if fetching routes or route data fails.
    func fetchRouteLocations(for workout: HKWorkout) async throws -> [CLLocation] {
        // First, query for the HKWorkoutRoute samples associated with the workout
        let routeType = HKSeriesType.workoutRoute()
        let workoutPredicate = HKQuery.predicateForObjects(from: workout)

        let routeSamples = try await fetchRouteSamples(predicate: workoutPredicate)

        guard !routeSamples.isEmpty else {
            logger.info("No HKWorkoutRoute samples found for workout \(workout.uuid).")
            return [] // No routes associated with this workout
        }

        logger.info("Found \(routeSamples.count) HKWorkoutRoute samples for workout \(workout.uuid). Fetching locations...")

        // Use a TaskGroup to fetch locations for all routes concurrently (though usually there's only one)
        return try await withThrowingTaskGroup(of: [CLLocation].self) { group in
            var allLocations: [CLLocation] = []

            for routeSample in routeSamples {
                group.addTask {
                    try await self.fetchLocations(for: routeSample)
                }
            }

            // Collect results from all tasks
            for try await locations in group {
                allLocations.append(contentsOf: locations)
            }

            // Sort by timestamp, as TaskGroup doesn't guarantee order
            allLocations.sort { $0.timestamp < $1.timestamp }
            logger.info("Fetched a total of \(allLocations.count) locations for workout \(workout.uuid).")
            return allLocations
        }
    }

    // Helper to fetch HKWorkoutRoute samples
    private func fetchRouteSamples(predicate: NSPredicate) async throws -> [HKWorkoutRoute] {
        let routeType = HKSeriesType.workoutRoute()

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil // No specific sort needed here
            ) { _, samples, error in
                if let error = error {
                    self.logger.error("Failed to fetch HKWorkoutRoute samples: \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                guard let routes = samples as? [HKWorkoutRoute] else {
                     self.logger.warning("Fetched samples were not HKWorkoutRoute type or nil.")
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: routes)
            }
            healthStore.execute(query)
        }
    }

    // Helper to fetch CLLocations for a single HKWorkoutRoute
    private func fetchLocations(for route: HKWorkoutRoute) async throws -> [CLLocation] {
        return try await withCheckedThrowingContinuation { continuation in
            var collectedLocations: [CLLocation] = []
            let query = HKWorkoutRouteQuery(route: route) { _, locationsOrNil, done, errorOrNil in
                if let error = errorOrNil {
                    self.logger.error("Error during HKWorkoutRouteQuery for route \(route.uuid): \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return // Need to return explicitly after resuming
                }

                if let locations = locationsOrNil {
                    collectedLocations.append(contentsOf: locations)
                }

                if done {
                    continuation.resume(returning: collectedLocations)
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Error Handling

    enum HealthKitError: Error, LocalizedError {
        case healthDataUnavailable
        case authorizationFailed(Error?)
        case authorizationDenied // Specific case if needed
        case queryFailed(Error)

        var errorDescription: String? {
            switch self {
            case .healthDataUnavailable:
                return NSLocalizedString("Health data is not available on this device.", comment: "HealthKit Error")
            case .authorizationFailed(let underlyingError):
                let baseMessage = NSLocalizedString("Failed to request HealthKit authorization.", comment: "HealthKit Error")
                if let underlyingError = underlyingError {
                    return "\(baseMessage) Error: \(underlyingError.localizedDescription)"
                }
                return baseMessage
             case .authorizationDenied:
                 return NSLocalizedString("HealthKit authorization was denied.", comment: "HealthKit Error")
            case .queryFailed(let underlyingError):
                return NSLocalizedString("HealthKit query failed: \(underlyingError.localizedDescription)", comment: "HealthKit Error")
            }
        }
    }
}
