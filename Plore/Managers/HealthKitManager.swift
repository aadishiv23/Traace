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
}
