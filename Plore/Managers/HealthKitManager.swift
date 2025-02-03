//
//  HealthKitManager.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/30/25.
//

import CoreLocation
import Foundation
import HealthKit

class HealthKitManager: ObservableObject {

    /// Access point for all data manager by Health Kit.
    private let healthStore = HKHealthStore()

    /// The list of routes representing the different walks a user had done.
    @Published var walkingRoutes: [[CLLocation]] = []
    @Published var runningRoutes: [[CLLocation]] = []
    @Published var cyclingRoutes: [[CLLocation]] = []

    /// This function requests the HealthKit permissions from the user.
    func requestHKPermissions() async {
        let typesToRequest: Set = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.heartRate)
        ]

        do {
            // Check that Health data is available on the device.
            if HKHealthStore.isHealthDataAvailable() {
                // Asynchronously requests access to data
                try await healthStore.requestAuthorization(toShare: typesToRequest, read: typesToRequest)
            }
        } catch {
            // Typically, authorization requests only fail if you haven't set the
            // usage and share descriptions in your app's Info.plist, or if
            // Health data isn't available on the current device.
            fatalError(
                "*** An unexpected error occurred while requesting authorization: \(error.localizedDescription) ***"
            )
        }
    }

    /// [Testing] This function fetches workout and routes async.
    func fetchWorkoutRoutesConcurrently() {
        Task(priority: .background) {
            var walkingResult: [[CLLocation]] = []
            var runningResult: [[CLLocation]] = []
            var cyclingResult: [[CLLocation]] = []

            let workoutTypes: [HKWorkoutActivityType] = [.walking, .running, .cycling]

            for type in workoutTypes {
                do {
                    let workouts = try await self.fetchWorkouts(of: type)
                    for workout in workouts {
                        if type == .walking || type == .running,
                           workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true
                        {
                            continue
                        }
                        let routes = try await self.fetchRoutes(for: workout)
                        for route in routes {
                            let simplified = simplifyRoute(locations: route, tolerance: 10)
                            if !simplified.isEmpty {
                                switch type {
                                case .walking:
                                    walkingResult.append(simplified)
                                case .running:
                                    runningResult.append(simplified)
                                case .cycling:
                                    cyclingResult.append(simplified)
                                default: break
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }

            let finalWalkingRoutes = walkingResult
            let finalRunningRoutes = runningResult
            let finalCyclingRoutes = cyclingResult

            await MainActor.run {
                self.walkingRoutes = finalWalkingRoutes
                self.runningRoutes = finalRunningRoutes
                self.cyclingRoutes = finalCyclingRoutes
            }
        }
    }

    /// This function fetches workouts and routes.
    func fetchWorkoutRoutes() {
        let workoutTypes: [HKWorkoutActivityType] = [.walking, .running, .cycling]

        for type in workoutTypes {
            let predicate = HKQuery.predicateForWorkouts(with: type)

            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                guard let workouts = samples as? [HKWorkout], error == nil else {
                    print("Error fetching workouts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                print("Found \(workouts.count) \(type) workouts.")

                for workout in workouts {
                    // Filter out indoor workouts
                    if workout.workoutActivityType == .running || workout.workoutActivityType == .cycling {
                        if workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true {
                            print("Skipping indoor \(type) workout at \(workout.startDate)")
                            continue
                        }
                    }

                    self.fetchWorkoutRoute(for: workout, type: type)
                }
            }

            healthStore.execute(query)
        }
    }

    // MARK: Private Methods

    /// Asynchronously fetch an array of HKWorkouts for a specific activity type.
    private func fetchWorkouts(of type: HKWorkoutActivityType) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let predicate = HKQuery.predicateForWorkouts(with: type)
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
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

    private func loadRouteData(_ route: HKWorkoutRoute, type: HKWorkoutActivityType) {
        var locations: [CLLocation] = []

        let query = HKWorkoutRouteQuery(route: route) { _, routeData, done, error in
            guard let routeData, error == nil else {
                print("Error fetching route data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            locations.append(contentsOf: routeData)

            if done {
                DispatchQueue.main.async {
                    print("✅ Route for \(type) has \(locations.count) locations.")

                    if locations.isEmpty {
                        print("⚠️ Skipping empty route for \(type)")
                        return
                    }

                    switch type {
                    case .walking:
                        self.walkingRoutes.append(locations)
                    case .running:
                        self.runningRoutes.append(locations)
                    case .cycling:
                        self.cyclingRoutes.append(locations)
                    default:
                        break
                    }
                    print("✅ Stored \(locations.count) locations in \(type) routes.")
                }
            }
        }
        healthStore.execute(query)
    }

    private func fetchWorkoutRoute(for workout: HKWorkout, type: HKWorkoutActivityType) {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        let query = HKSampleQuery(
            sampleType: routeType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            guard let routes = samples as? [HKWorkoutRoute], error == nil else {
                return
            }

            print("Found \(routes.count) routes for \(type) workout at \(workout.startDate)")

            for route in routes {
                self.loadRouteData(route, type: type)
            }
        }

        healthStore.execute(query)
    }

    /// Asynchronously fetch all the HKWorkoutRoutes for a given workout, returning an array of arrays of CLLocation.
    private func fetchRoutes(for workout: HKWorkout) async throws -> [[CLLocation]] {
        try await withCheckedThrowingContinuation { continuation in
            let routeType = HKSeriesType.workoutRoute()
            let predicate = HKQuery.predicateForObjects(from: workout)

            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let routes = samples as? [HKWorkoutRoute] else {
                    continuation.resume(returning: [])
                    return
                }
                // For each HKWorkoutRoute, we need to read out the actual CLLocation data.
                self.loadRoutesData(routes) { locationsArrays in
                    continuation.resume(returning: locationsArrays)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Helper to load location data from multiple HKWorkoutRoutes asynchronously.
    private func loadRoutesData(_ routes: [HKWorkoutRoute], completion: @escaping ([[CLLocation]]) -> Void) {
        var routeLocations: [[CLLocation]] = []
        let group = DispatchGroup()

        for route in routes {
            group.enter()
            var locations: [CLLocation] = []
            let routeQuery = HKWorkoutRouteQuery(route: route) { _, newData, done, error in
                if let error {
                    print("Error fetching route data: \(error.localizedDescription)")
                } else if let newData {
                    locations.append(contentsOf: newData)
                }

                if done {
                    routeLocations.append(locations)
                    group.leave()
                }
            }
            healthStore.execute(routeQuery)
        }

        // When all routes have been processed, call completion.
        group.notify(queue: .global()) {
            completion(routeLocations)
        }
    }

    /// Removes points that are too close to the last accepted point.
    /// This greatly reduces the strain when rendering on the map.
    func simplifyRoute(locations: [CLLocation], tolerance: CLLocationDistance = 10) -> [CLLocation] {
        guard let first = locations.first else {
            return []
        }
        var simplified = [first]
        for loc in locations.dropFirst() {
            if loc.distance(from: simplified.last!) > tolerance {
                simplified.append(loc)
            }
        }
        return simplified
    }

}
