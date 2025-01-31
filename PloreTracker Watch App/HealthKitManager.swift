//
//  HealthKitManager.swift
//  PloreTracker Watch App
//
//  Created by Aadi Shiv Malhotra on 1/30/25.
//

import CoreLocation
import Foundation
import HealthKit

class HealthKitManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: Properties

    /// Singleton.
    static let shared = HealthKitManager()

    /// The object acting as the access point for all HealthKit data.
    private let healthStore = HKHealthStore()

    /// The session tracking the user's workout on the Watch.
    private var workoutSession: HKWorkoutSession?

    /// The builder object that incrementally builds the workout
    private var workoutBuilder: HKWorkoutBuilder?

    /// The object used to track the user's location
    private var locationManager = CLLocationManager()

    /// A variable tracking whether the app is currently tracking the user's location/workout.
    @Published var isTracking = false

    // MARK: Initializer

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: Methods

    /// This function requests the HealthKit permissions from the user.
    func requestHKPermissions() async {
        let typesToRequest: Set = [
            HKObjectType.workoutType(),
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

    /// This function starts a walking workout.
    func startWalkWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .outdoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            guard let workoutSession = workoutSession else { return }

            workoutBuilder = workoutSession.associatedWorkoutBuilder()

            workoutSession.delegate = self

            workoutSession.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isTracking = true
                        self.startLocationUpdates()
                    }
                }
            }
        } catch {
            print("Failed to start workout: \(error.localizedDescription)")
        }
    }

    /// Stop the workout
    func stopWorkout() {
        workoutSession?.end()
        stopLocationUpdates()
        DispatchQueue.main.async {
            self.isTracking = false
        }
    }

    /// Start collecting location updates
    private func startLocationUpdates() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    /// Handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates (store them if needed)
    }
}

// MARK: - HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate

extension HealthKitManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    }
    
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
