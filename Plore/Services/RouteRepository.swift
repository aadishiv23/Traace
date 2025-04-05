//
//  RouteRepository.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import CoreData
import Combine
import HealthKit
import os
import MapKit
import CoreLocation

/// Repository class that acts as the single source of truth for route data
/// Orchestrates fetching from CoreData and syncing with HealthKit
class RouteRepository {
    // MARK: - Properties
    
    /// The CoreDataManager instance
    private let coreDataManager: CoreDataManager
    
    /// The HealthKitService instance
    private let healthKitService: HealthKitService
    
    /// The PolylineFactory instance
    private let polylineFactory: PolylineFactory
    
    /// Logger for logging operations
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "com.aadishivmalhotra.Plore.RouteRepository"
    )
    
    /// Published property to track the last sync date
    @Published private(set) var lastSyncDate: Date {
        didSet {
            UserDefaults.standard.set(lastSyncDate, forKey: Self.lastSyncDateKey)
        }
    }
    
    /// UserDefaults key for storing the last sync date
    private static let lastSyncDateKey = "com.aadishivmalhotra.Plore.lastSyncDate"
    
    // MARK: - Initialization
    
    /// Initializes a new RouteRepository with the given dependencies
    /// - Parameters:
    ///   - coreDataManager: The CoreDataManager to use for persistence
    ///   - healthKitService: The HealthKitService to use for fetching HealthKit data
    ///   - polylineFactory: The PolylineFactory to use for processing route data
    init(coreDataManager: CoreDataManager, 
         healthKitService: HealthKitService,
         polylineFactory: PolylineFactory) {
        self.coreDataManager = coreDataManager
        self.healthKitService = healthKitService
        self.polylineFactory = polylineFactory
        
        // Load last sync date from UserDefaults
        self.lastSyncDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date ?? .distantPast
    }
    
    // MARK: - Data Fetching
    
    /// Fetches routes from CoreData based on the provided filter criteria
    /// - Parameter filter: The criteria to filter routes by (optional)
    /// - Returns: Array of CDWorkout objects matching the criteria
    func getRoutes(filter: RouteFilterCriteria? = nil) async -> [CDWorkout] {
        let context = coreDataManager.mainContext
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        
        // Apply filter predicate if provided
        if let predicate = filter?.predicate {
            request.predicate = predicate
        }
        
        // Set sort descriptors (most recent first)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkout.startDate, ascending: false)]
        
        // Prefetch route points for better performance
        request.relationshipKeyPathsForPrefetching = ["routePoints"]
        
        return await context.perform {
            do {
                let workouts = try context.fetch(request)
                self.logger.debug("Fetched \(workouts.count) workouts from CoreData")
                return workouts
            } catch {
                self.logger.error("Error fetching workouts: \(error.localizedDescription)")
                return []
            }
        }
    }
    
    /// Fetches routes and converts them to RouteDisplayInfo objects for displaying on the map
    /// - Parameter filter: The criteria to filter routes by (optional)
    /// - Returns: Array of RouteDisplayInfo objects
    func getRouteDisplayInfo(filter: RouteFilterCriteria? = nil) async -> [RouteDisplayInfo] {
        let workouts = await getRoutes(filter: filter)
        var routeDisplayInfos: [RouteDisplayInfo] = []
        
        for workout in workouts {
            guard let activityType = workout.activityType,
                  let id = workout.id else { continue }
            
            let routePoints = (workout.routePoints?.allObjects as? [CDRoutePoint]) ?? []
            
            // Sort the route points by timestamp
            let sortedPoints = routePoints.sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
            
            // Convert to CLLocation array
            let locations = sortedPoints.map { 
                CLLocation(
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    altitude: 0,
                    horizontalAccuracy: 0,
                    verticalAccuracy: 0,
                    timestamp: $0.timestamp ?? Date()
                )
            }
            
            // Skip if no locations
            guard !locations.isEmpty else { continue }
            
            // Create polyline
            let polyline = polylineFactory.createPolyline(from: locations)
            
            // Create RouteDisplayInfo
            let displayInfo = RouteDisplayInfo(
                id: id,
                activityType: activityType,
                polyline: polyline
            )
            
            routeDisplayInfos.append(displayInfo)
        }
        
        return routeDisplayInfos
    }
    
    /// Fetches routes and converts them to RouteSummaryInfo objects for displaying in lists
    /// - Parameter filter: The criteria to filter routes by (optional)
    /// - Returns: Array of RouteSummaryInfo objects
    func getRouteSummaryInfo(filter: RouteFilterCriteria? = nil) async -> [RouteSummaryInfo] {
        let workouts = await getRoutes(filter: filter)
        var routeSummaries: [RouteSummaryInfo] = []
        
        for workout in workouts {
            guard let activityType = workout.activityType,
                  let id = workout.id,
                  let startDate = workout.startDate else { continue }
            
            // Create RouteSummaryInfo
            let summaryInfo = RouteSummaryInfo(
                id: id,
                activityType: activityType,
                date: startDate,
                isIndoor: workout.isIndoor
            )
            
            routeSummaries.append(summaryInfo)
        }
        
        // Sort by date (newest first)
        return routeSummaries.sorted { $0.date > $1.date }
    }
    
    // MARK: - Sync with HealthKit
    
    /// Syncs data from HealthKit since the last sync date
    /// - Parameter minSyncInterval: Minimum time interval between syncs (default: 1 hour)
    /// - Returns: Boolean indicating whether new data was synced
    func syncWithHealthKit(minSyncInterval: TimeInterval = 3600) async throws -> Bool {
        let now = Date()
        
        // Skip sync if less than minSyncInterval has passed
        guard now.timeIntervalSince(lastSyncDate) > minSyncInterval else {
            logger.info("Skipping sync as less than \(minSyncInterval) seconds have passed since last sync")
            return false
        }
        
        logger.info("Starting sync with HealthKit since \(lastSyncDate)")
        
        // Fetch workouts from HealthKit since last sync date
        let newWorkouts = try await healthKitService.fetchWorkouts(since: lastSyncDate)
        
        if newWorkouts.isEmpty {
            logger.info("No new workouts found since last sync")
            // Update last sync date even if no workouts found
            lastSyncDate = now
            return false
        }
        
        logger.info("Found \(newWorkouts.count) new workouts to sync")
        
        // Create a background context for processing
        let bgContext = coreDataManager.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Process workouts concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for workout in newWorkouts {
                group.addTask {
                    // Only process walking, running, or cycling workouts
                    guard [HKWorkoutActivityType.walking, .running, .cycling].contains(workout.workoutActivityType) else {
                        return
                    }
                    
                    // Skip indoor workouts
                    if workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true {
                        return
                    }
                    
                    // Get or create CDWorkout in CoreData
                    let cdWorkout = self.coreDataManager.fetchOrCreateWorkout(from: workout, in: bgContext)
                    guard let cdWorkout = cdWorkout else { return }
                    
                    // Fetch route locations
                    let routeLocations = try await self.healthKitService.fetchRouteLocations(for: workout)
                    
                    // Process each route
                    for locations in routeLocations {
                        if !locations.isEmpty {
                            // Simplify route and add to CoreData
                            let simplified = self.polylineFactory.simplifyRoute(locations: locations)
                            self.coreDataManager.addRoutePoints(simplified, to: cdWorkout, in: bgContext)
                        }
                    }
                }
            }
            
            // Wait for all tasks to complete
            try await group.waitForAll()
        }
        
        // Save context
        await bgContext.perform {
            do {
                try bgContext.save()
                self.logger.info("Successfully saved \(newWorkouts.count) new workouts to CoreData")
            } catch {
                self.logger.error("Error saving workouts to CoreData: \(error.localizedDescription)")
                // Even if there's an error, we update the sync date to avoid repeatedly
                // trying to sync the same problematic data
            }
        }
        
        // Update last sync date
        lastSyncDate = now
        return true
    }
    
    // MARK: - Initial Data Load
    
    /// Ensures that the app has data by checking CoreData and syncing with HealthKit if needed
    /// - Returns: Boolean indicating whether the operation was successful
    func ensureInitialData() async throws -> Bool {
        // Check if we have any workouts in CoreData
        let existingWorkouts = await getRoutes()
        
        if existingWorkouts.isEmpty {
            // No workouts in CoreData, perform initial fetch from HealthKit
            logger.info("No workouts found in CoreData, performing initial load from HealthKit")
            return try await loadInitialDataFromHealthKit()
        } else {
            logger.info("Found \(existingWorkouts.count) existing workouts in CoreData")
            return true
        }
    }
    
    /// Loads initial workout data from HealthKit for all workout types
    /// - Returns: Boolean indicating whether the operation was successful
    private func loadInitialDataFromHealthKit() async throws -> Bool {
        let workoutTypes: [HKWorkoutActivityType] = [.walking, .running, .cycling]
        var success = false
        
        let bgContext = coreDataManager.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        for type in workoutTypes {
            let workouts = try await healthKitService.fetchWorkouts(of: type)
            
            for workout in workouts {
                // Skip indoor workouts
                if workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool == true {
                    continue
                }
                
                // Get or create CDWorkout
                let cdWorkout = coreDataManager.fetchOrCreateWorkout(from: workout, in: bgContext)
                guard let cdWorkout = cdWorkout else { continue }
                
                // Fetch and process routes
                let routes = try await healthKitService.fetchRouteLocations(for: workout)
                
                for route in routes {
                    let simplified = polylineFactory.simplifyRoute(locations: route)
                    coreDataManager.addRoutePoints(simplified, to: cdWorkout, in: bgContext)
                }
                
                success = true
            }
        }
        
        // Save context
        await bgContext.perform {
            do {
                try bgContext.save()
                self.logger.info("Successfully saved initial data to CoreData")
            } catch {
                self.logger.error("Error saving initial data to CoreData: \(error.localizedDescription)")
                success = false
            }
        }
        
        // Update last sync date
        if success {
            lastSyncDate = Date()
        }
        
        return success
    }
} 