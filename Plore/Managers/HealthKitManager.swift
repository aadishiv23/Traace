//
//  HealthKitManager.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/30/25.
//

import CoreData
import CoreLocation
import Foundation
import HealthKit
import MapKit

class HealthKitManager: ObservableObject {

    /// Access point for all data manager by Health Kit.
    private let healthStore = HKHealthStore()

    /// Access point for all data in CoreData.
    private let coreDataManager = CoreDataManager.shared

    /// The list of routes representing the different workouts a user has done.
    @Published var walkingRoutes: [[CLLocation]] = []
    @Published var runningRoutes: [[CLLocation]] = []
    @Published var cyclingRoutes: [[CLLocation]] = []

    /// Cached polylines.
    @Published var walkingPolylines: [MKPolyline] = []
    @Published var runningPolylines: [MKPolyline] = []
    @Published var cyclingPolylines: [MKPolyline] = []

    /// Initializes HealthKitManager and loads routes.
    init() {
        Task {
            await requestHKPermissions()
            await loadRoutes()
        }
    }

    /// 1) Check Core Data first. If data is present, load it and skip HK if you like.
    ///    Otherwise, fetch from HealthKit.
    func loadRoutes() async {
        let cdWorkouts = await coreDataManager.fetchAllWorkouts()

        if !cdWorkouts.isEmpty {
            processCoreDataWorkouts(cdWorkouts)
        } else {
            fetchWorkoutRoutesConcurrently()
        }
    }

    // MARK: - Polyline

    func computePolylines() async {
        async let walkingPolylines = Task.detached(priority: .userInitiated) {
            self.walkingRoutes.map { route in
                let coordinates = route.map(\.coordinate)
                return MKPolyline(coordinates: coordinates, count: coordinates.count)
            }
        }.value

        async let runningPolylines = Task.detached(priority: .userInitiated) {
            self.runningRoutes.map { route in
                let coordinates = route.map(\.coordinate)
                return MKPolyline(coordinates: coordinates, count: coordinates.count)
            }
        }.value

        async let cyclingPolylines = Task.detached(priority: .userInitiated) {
            self.cyclingRoutes.map { route in
                let coordinates = route.map(\.coordinate)
                return MKPolyline(coordinates: coordinates, count: coordinates.count)
            }
        }.value

        let (walkingPolys, runningPolys, cyclingPolys) = await (walkingPolylines, runningPolylines, cyclingPolylines)

        Task { @MainActor in
            self.walkingPolylines = walkingPolys
            self.runningPolylines = runningPolys
            self.cyclingPolylines = cyclingPolys
        }
    }

    func syncData(interval: TimeInterval = 3600) {
        let lastSyncKey = "lastSyncDate"
        let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date ?? .distantPast

        let now = Date()

        guard now.timeIntervalSince(lastSync) > 3600 else {
            print("[HealthKitManager] syncDate() - Skipping sync as less than one hour has passed since last sync")
            return
        }

        Task {
            let bgContext = coreDataManager.persistenceContainer.newBackgroundContext()
            bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            do {
                let newWorkouts = try await fetchWorkouts(since: lastSync)

                if newWorkouts.isEmpty {
                    print("[HealthKitManager] syncData() - No new workouts find since last interval, returning.")
                    return
                }

                print(
                    "[HealthKitManager] syncData() - Found \(newWorkouts.count) new workouts to sync. Starting background sync..."
                )

                // Use TaskGroup to fetch concurrently
                try await withThrowingTaskGroup(of: (HKWorkout, [[CLLocation]]).self) { group in
                    for workout in newWorkouts {
                        group.addTask {
                            let routes = try await self.fetchRoutes(for: workout)
                            return (workout, routes)
                        }
                    }

                    for try await (workout, routes) in group {
                        let cdWorkout = coreDataManager.fetchOrCreateWorkout(from: workout, in: bgContext)

                        for route in routes {
                            let simplified = simplifyRoute(locations: route, tolerance: 10)
                            coreDataManager.addRoutePoints(simplified, to: cdWorkout!, in: bgContext)
                        }
                    }
                }

                do {
                    try bgContext.save()
                } catch {
                    print("[HealthKitManager] syncData() - Unable to save background context: \(error)")
                }

                UserDefaults.standard.set(Date(), forKey: "lastSyncDate")

                print("[HealthKitManager] syncData() - ✅ Successfully synced \(newWorkouts.count) new workouts.")

                let mainThreadWorkouts = await coreDataManager.fetchAllWorkouts()
                self.processCoreDataWorkouts(mainThreadWorkouts)
            } catch {
                print("[HealthKitManager] syncData() - Failed to sync and fetch new workouts: \(error)")
            }
        }
    }

    private func processCoreDataWorkouts(_ workouts: [CDWorkout]) {
        var walking = [[CLLocation]]()
        var running = [[CLLocation]]()
        var cycling = [[CLLocation]]()

        for cdWorkout in workouts {
            guard let typeString = cdWorkout.type else {
                print("❌ Workout type is nil for \(cdWorkout.id ?? "Unknown ID")")
                continue
            }

            print("ℹ️ Raw typeString from Core Data:", typeString)

            guard let typeInt = Int(typeString) else {
                print("❌ Failed to convert typeString to Int:", typeString)
                continue
            }

            print("ℹ️ Converting typeInt:", typeInt)

            guard let typeEnum = HKWorkoutActivityType(rawValue: UInt(typeInt)) else {
                print("❌ Invalid HKWorkoutActivityType rawValue:", typeInt)
                continue
            }

            print("✅ Successfully matched type:", typeEnum)

            let points = cdWorkout.routePoints?.allObjects as? [CDRoutePoint] ?? []

            let sortedPoints = points.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
            let locations = sortedPoints.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }

            switch typeEnum {
            case .walking:
                walking.append(locations)
            case .running:
                running.append(locations)
            case .cycling:
                cycling.append(locations)
            default:
                break
            }
        }

        Task { @MainActor in
            self.walkingRoutes = walking
            self.runningRoutes = running
            self.cyclingRoutes = cycling

            await self.computePolylines()
        }
    }

    func requestHKPermissions() async {
        let typesToRequest: Set = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        do {
            if HKHealthStore.isHealthDataAvailable() {
                try await healthStore.requestAuthorization(toShare: typesToRequest, read: typesToRequest)
            }
        } catch {
            fatalError("*** Error requesting HK authorization: \(error) ***")
        }
    }

    func fetchWorkoutRoutesConcurrently() {
        Task(priority: .high) {
            let workoutTypes: [HKWorkoutActivityType] = [.walking, .running, .cycling]

            let bgContext = coreDataManager.persistenceContainer.newBackgroundContext()
            bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            for type in workoutTypes {
                do {
                    let workouts = try await self.fetchWorkouts(of: type)
                    for workout in workouts {
                        if type == .running || type == .walking || type == .cycling,
                           workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true
                        {
                            continue
                        }

                        let cdWorkout = coreDataManager.fetchOrCreateWorkout(from: workout, in: bgContext)
                        let routes = try await self.fetchRoutes(for: workout)

                        for route in routes {
                            let simplified = simplifyRoute(locations: route, tolerance: 10)
                            coreDataManager.addRoutePoints(simplified, to: cdWorkout!, in: bgContext)
                        }
                    }
                } catch {
                    print("❌ Error fetching \(type) workouts or routes: \(error)")
                }
            }

            do {
                try bgContext.save()
            } catch {
                print("❌ Error saving background context: \(error.localizedDescription)")
            }

            let mainThreadWorkouts = await coreDataManager.fetchAllWorkouts()
            self.processCoreDataWorkouts(mainThreadWorkouts)
        }
    }

    /// Fetches workouts of a particular workout activity type.
    private func fetchWorkouts(of type: HKWorkoutActivityType) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
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

    /// Fetch workouts that have occured prior to the last saved sync.
    private func fetchWorkouts(since lastSync: Date) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: lastSync, end: Date(), options: .strictStartDate)
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
                self.loadRoutesData(routes) { locationsArrays in
                    continuation.resume(returning: locationsArrays)
                }
            }
            healthStore.execute(query)
        }
    }

    private func loadRoutesData(_ routes: [HKWorkoutRoute], completion: @escaping ([[CLLocation]]) -> Void) {
        var routeLocations: [[CLLocation]] = []
        let group = DispatchGroup()

        for route in routes {
            group.enter()
            var locations: [CLLocation] = []
            let routeQuery = HKWorkoutRouteQuery(route: route) { _, newData, done, error in
                if let error {
                    print("❌ Route data error: \(error.localizedDescription)")
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

        group.notify(queue: .global()) {
            completion(routeLocations)
        }
    }

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

// MARK: - Filtering

extension HealthKitManager {

    func filterRoutesByDate(date: Date?) -> (walking: [MKPolyline], running: [MKPolyline], cycling: [MKPolyline]) {
        guard let date = date else {
            return (walkingPolylines, runningPolylines, cyclingPolylines)
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return filterRoutesByDateRange(start: startOfDay, end: endOfDay)
    }

    func filterRoutesByDateRange(start: Date, end: Date) -> (walking: [MKPolyline], running: [MKPolyline], cycling: [MKPolyline]) {
        let filteredWalking = filterRoutes(routes: walkingRoutes, polylines: walkingPolylines, start: start, end: end)
        let filteredRunning = filterRoutes(routes: runningRoutes, polylines: runningPolylines, start: start, end: end)
        let filteredCycling = filterRoutes(routes: cyclingRoutes, polylines: cyclingPolylines, start: start, end: end)
        
        return (filteredWalking, filteredRunning, filteredCycling)
    }

    private func filterRoutes(routes: [[CLLocation]], polylines: [MKPolyline], start: Date, end: Date) -> [MKPolyline] {
        var filteredPolylines: [MKPolyline] = []
        
        for (index, route) in routes.enumerated() {
            if index < polylines.count, let firstLocation = route.first,
               firstLocation.timestamp >= start && firstLocation.timestamp < end {
                filteredPolylines.append(polylines[index])
            }
        }
        
        return filteredPolylines
    }
}
