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

    /// RouteInfo objects with names and metadata
    @Published var walkingRouteInfos: [RouteInfo] = []
    @Published var runningRouteInfos: [RouteInfo] = []
    @Published var cyclingRouteInfos: [RouteInfo] = []

    /// Cached polylines.
    @Published var walkingPolylines: [MKPolyline] = []
    @Published var runningPolylines: [MKPolyline] = []
    @Published var cyclingPolylines: [MKPolyline] = []

    /// Whether we’re currently loading/syncing routes.
    @Published var isLoadingRoutes: Bool = false

    /// How many workouts have finished loading so far.
    @Published var loadedRouteCount: Int = 0

    /// Total number of workouts we expect to load.
    @Published var totalRouteCount: Int = 0

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
                    await MainActor.run {
                        self.isLoadingRoutes = false
                        self.loadedRouteCount = 0
                        self.totalRouteCount = 0
                    }
                    return
                }

                print(
                    "[HealthKitManager] syncData() - Found \(newWorkouts.count) new workouts to sync. Starting background sync..."
                )

                await MainActor.run {
                    self.isLoadingRoutes = true
                    self.loadedRouteCount = 0
                    self.totalRouteCount = newWorkouts.count
                }

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

                        await MainActor.run {
                            self.loadedRouteCount += 1
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

        var walkingInfos = [RouteInfo]()
        var runningInfos = [RouteInfo]()
        var cyclingInfos = [RouteInfo]()

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

            // Create a RouteInfo object with date from the workout
            let routeDate = cdWorkout.startDate ?? Date()
            let routeName = cdWorkout.name
            let routeInfo = RouteInfo(name: routeName, type: typeEnum, date: routeDate, locations: locations)

            switch typeEnum {
            case .walking:
                walking.append(locations)
                walkingInfos.append(routeInfo)
            case .running:
                running.append(locations)
                runningInfos.append(routeInfo)
            case .cycling:
                cycling.append(locations)
                cyclingInfos.append(routeInfo)
            default:
                break
            }
        }

        Task { @MainActor in
            self.walkingRoutes = walking
            self.runningRoutes = running
            self.cyclingRoutes = cycling

            self.walkingRouteInfos = walkingInfos
            self.runningRouteInfos = runningInfos
            self.cyclingRouteInfos = cyclingInfos

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
            // 🚩 initialize progress for initial load
            await MainActor.run {
                self.isLoadingRoutes = true
                self.loadedRouteCount = 0
                // estimate total by summing counts of each type
                Task {
                    let walking = try? await self.fetchWorkouts(of: .walking)
                    let running = try? await self.fetchWorkouts(of: .running)
                    let cycling = try? await self.fetchWorkouts(of: .cycling)
                    await MainActor.run {
                        self.totalRouteCount = (walking?.count ?? 0)
                            + (running?.count ?? 0)
                            + (cycling?.count ?? 0)
                    }
                }
            }

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

                        await MainActor.run {
                            self.loadedRouteCount += 1
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

            await MainActor.run {
                self.isLoadingRoutes = false
            }
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
        guard let date else {
            return (walkingPolylines, runningPolylines, cyclingPolylines)
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return filterRoutesByDateRange(start: startOfDay, end: endOfDay)
    }

    func filterRoutesByDateRange(
        start: Date,
        end: Date
    ) -> (walking: [MKPolyline], running: [MKPolyline], cycling: [MKPolyline]) {
        let filteredWalking = filterRoutes(routes: walkingRoutes, polylines: walkingPolylines, start: start, end: end)
        let filteredRunning = filterRoutes(routes: runningRoutes, polylines: runningPolylines, start: start, end: end)
        let filteredCycling = filterRoutes(routes: cyclingRoutes, polylines: cyclingPolylines, start: start, end: end)

        return (filteredWalking, filteredRunning, filteredCycling)
    }

    private func filterRoutes(routes: [[CLLocation]], polylines: [MKPolyline], start: Date, end: Date) -> [MKPolyline] {
        var filteredPolylines: [MKPolyline] = []

        for (index, route) in routes.enumerated() {
            if index < polylines.count, let firstLocation = route.first,
               firstLocation.timestamp >= start, firstLocation.timestamp < end
            {
                filteredPolylines.append(polylines[index])
            }
        }

        return filteredPolylines
    }

    // New methods for working with named routes

    /// Updates the name of a route
    func updateRouteName(id: UUID, newName: String) {
        var updated = false

        // Update walking routes
        if let index = walkingRouteInfos.firstIndex(where: { $0.id == id }) {
            walkingRouteInfos[index].name = newName
            updated = true

            // Find the equivalent workout in Core Data by comparing dates
            // This is a simplification - ideally we'd have a direct reference
            let date = walkingRouteInfos[index].date
            saveRouteNameToCore(type: .walking, date: date, name: newName)
        }

        // Update running routes
        if let index = runningRouteInfos.firstIndex(where: { $0.id == id }) {
            runningRouteInfos[index].name = newName
            updated = true

            let date = runningRouteInfos[index].date
            saveRouteNameToCore(type: .running, date: date, name: newName)
        }

        // Update cycling routes
        if let index = cyclingRouteInfos.firstIndex(where: { $0.id == id }) {
            cyclingRouteInfos[index].name = newName
            updated = true

            let date = cyclingRouteInfos[index].date
            saveRouteNameToCore(type: .cycling, date: date, name: newName)
        }

        if updated {
            // Notify observers that the data has changed
            objectWillChange.send()
        }
    }

    /// Saves a route name to Core Data
    private func saveRouteNameToCore(type: HKWorkoutActivityType, date: Date, name: String) {
        Task {
            let workouts = await coreDataManager.fetchAllWorkouts()

            // Find matching workout by type and date
            let typeString = String(type.rawValue)

            let calendar = Calendar.current
            for workout in workouts {
                if workout.type == typeString,
                   let workoutDate = workout.startDate,
                   let workoutId = workout.id,
                   calendar.isDate(workoutDate, inSameDayAs: date)
                {
                    // Found a match, update the name
                    coreDataManager.updateWorkoutName(id: workoutId, newName: name)
                    break
                }
            }
        }
    }

    /// Gets all routes filtered by date range
    func getAllRouteInfosByDateRange(start: Date, end: Date) -> [RouteInfo] {
        let walkingFiltered = walkingRouteInfos.filter { $0.date >= start && $0.date < end }
        let runningFiltered = runningRouteInfos.filter { $0.date >= start && $0.date < end }
        let cyclingFiltered = cyclingRouteInfos.filter { $0.date >= start && $0.date < end }

        return walkingFiltered + runningFiltered + cyclingFiltered
    }

    /// Gets all routes for a specific date
    func getAllRouteInfosByDate(date: Date?) -> [RouteInfo] {
        guard let date else {
            return walkingRouteInfos + runningRouteInfos + cyclingRouteInfos
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return getAllRouteInfosByDateRange(start: startOfDay, end: endOfDay)
    }
}
