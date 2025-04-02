//
//  CoreDataManager.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import CoreData
import CoreLocation
import Foundation
import HealthKit
import os

/// A singleton that manages the Core Data stack and provides an interface for saving/fetching  data.
final class CoreDataManager {

    // MARK: Properties

    /// The static shared instance.
    static let shared = CoreDataManager()

    /// Logger obj to log shit.
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "com.aadishivmalhotra.Plore.CoreDataManager"
    )

    // MARK: Persistence Container

    lazy var persistenceContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HealthRoutes")
        // Load stores asynchronously to avoid blocking
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Consider more robust error handling than fatalError in production
                self.logger.critical("Unable to load persistent stores: \(error), \(error.userInfo)")
                fatalError("Unable to load persistent stores: \(error), \(error.userInfo)")
            } else {
                self.logger.info("Persistent store loaded: \(storeDescription.url?.lastPathComponent ?? "N/A")")
                // Ensure main context automatically merges changes from background contexts
                container.viewContext.automaticallyMergesChangesFromParent = true
            }
        }
        return container
    }()

    /// A convenient main-thread context for quick reads/writes
    /// need to use sparingly for writes
    var mainContext: NSManagedObjectContext {
        persistenceContainer.viewContext
    }

    /// Creates a new background context for performing Core Data operations off the main thread.
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistenceContainer.newBackgroundContext()

        // Merging policy for bg saves if needed (often set where the context is used)
        // context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: Save Context

    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else {
            return
        }

        context.performAndWait { // use if sync save needed or peform for async
            do {
                try context.save()
                logger.debug("Context saved successfully.")
            } catch {
                logger.error("❌ Error saving context: \(error.localizedDescription)")
                // Optionally roll back or handle the error more gracefully
                // context.rollback()
            }
        }
    }

    /// Convenience method to save the main context (use carefully)
    func saveContext() {
        let context = mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Error saving context: \(error.localizedDescription)")
            }
        }
    }

    // MARK: Create or Fetch CDWorkout

    /// Returns an existing CDWorkout if it exists (by matching the HKWorkout's UUID),
    /// or creates a new one if not found.
    func fetchOrCreateWorkout(from hkWorkout: HKWorkout, in context: NSManagedObjectContext) -> CDWorkout? {
        // pkey
        let workoutId = hkWorkout.uuid.uuidString
        var resultWorkout: CDWorkout?

        context.performAndWait { // ensure ops happen on correct context que
            let fetchRequest: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", workoutId)

            fetchRequest.fetchLimit = 1 // only need 1 or none

            do {
                let results = try context.fetch(fetchRequest)
                if let existingWorkout = results.first {
                    logger.debug("Fetched existing workout: \(workoutId)")
                    resultWorkout = existingWorkout
                } else {
                    logger.debug("Creating new workout: \(workoutId)")
                    let newWorkout = CDWorkout(context: context)
                    newWorkout.id = workoutId
                    newWorkout.startDate = hkWorkout.startDate
                    newWorkout.endDate = hkWorkout.endDate
                    // Store the raw value safely
                    newWorkout.type = String(hkWorkout.workoutActivityType.rawValue)
                    // Check metadata for indoor status
                    newWorkout.isIndoor = (hkWorkout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool) ?? false
                    resultWorkout = newWorkout
                }
            } catch {
                logger.error("❌ Error fetching or creating workout \(workoutId): \(error.localizedDescription)")
                resultWorkout = nil // Ensure nil is returned on error
            }
        }

        return resultWorkout
    }

    // MARK: Add RoutePoints (Operates on the provided context)

    /// Creates and inserts CDRoutePoint objects within the specified context.
    func addRoutePoints(_ locations: [CLLocation], to cdWorkout: CDWorkout, in context: NSManagedObjectContext) {
        context.performAndWait { // Ensure Core Data operations happen on the context's queue
            guard cdWorkout.managedObjectContext == context else {
                logger.error("❌ Mismatched context for workout and route points.")
                return // Avoid cross-context issues
            }

            logger.debug("Adding \(locations.count) route points to workout \(cdWorkout.id ?? "N/A")")
            for loc in locations {
                let cdPoint = CDRoutePoint(context: context)
                cdPoint.latitude = loc.coordinate.latitude
                cdPoint.longitude = loc.coordinate.longitude
                cdPoint.timestamp = loc.timestamp
                // Link the point to the workout. Ensure cdWorkout is managed by the same context.
                cdPoint.workout = cdWorkout
                // Consider adding to the workout's relationship set as well if needed immediately,
                // but Core Data manages the inverse relationship automatically.
                // cdWorkout.addToRoutePoints(cdPoint)
            }
        }
    }

    /// **[NEW - Example]** Fetches specific route points for a given workout ID.
    /// - Parameters:
    ///   - workoutID: The UUID string of the CDWorkout.
    ///   - context: The context to fetch from.
    /// - Returns: An array of CDRoutePoint objects.
    func fetchRoutePoints(for workoutID: String, context: NSManagedObjectContext) async -> [CDRoutePoint] {
        let fetchContext = context
        let request: NSFetchRequest<CDRoutePoint> = CDRoutePoint.fetchRequest()
        // Filter points belonging to the specific workout
        request.predicate = NSPredicate(format: "workout.id == %@", workoutID)
        // Sort points by timestamp
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDRoutePoint.timestamp, ascending: true)]

        return await fetchContext.perform {
            do {
                let points = try fetchContext.fetch(request)
                self.logger.info("Fetched \(points.count) route points for workout \(workoutID).")
                return points
            } catch {
                self.logger
                    .error("❌ Failed to fetch route points for workout \(workoutID): \(error.localizedDescription)")
                return []
            }
        }
    }

    // MARK: Fetching (Refined/Added Methods)

    /// **[REFINED]** Fetches CDWorkout objects from Core Data based on optional criteria.
    /// Performs fetch asynchronously on the specified context's queue.
    /// - Parameters:
    ///   - predicate: An NSPredicate to filter the results.
    ///   - sortDescriptors: An array of NSSortDescriptors to sort the results.
    ///   - fetchLimit: The maximum number of objects to return (0 for no limit).
    ///   - context: The NSManagedObjectContext to perform the fetch on (defaults to mainContext).
    /// - Returns: An array of CDWorkout objects matching the criteria.
    func fetchWorkouts(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int = 0, // Added fetchLimit parameter
        context: NSManagedObjectContext? = nil
    ) async -> [CDWorkout] {
        let fetchContext = context ?? mainContext
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = fetchLimit

        // Always prefetch routePoints for efficiency when accessing them later
        request.relationshipKeyPathsForPrefetching = ["routePoints"]

        // Use perform for safe asynchronous fetching on the context's queue
        return await fetchContext.perform {
            do {
                let workouts = try fetchContext.fetch(request)
                self.logger.info("Fetched \(workouts.count) workouts matching criteria.")
                return workouts
            } catch {
                self.logger.error("❌ Failed to fetch workouts with criteria: \(error.localizedDescription)")
                return []
            }
        }
    }

    // MARK: Fetch All Workouts from Core Data

    // Returns all workouts stored in Core Data (with prefetching routePoints if desired).
//    func fetchAllWorkouts(context: NSManagedObjectContext? = nil) async -> [CDWorkout] {
//        let fetchContext = context ?? mainContext
//        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
//        // Optionally prefetch routePoints to avoid multiple round-trips:
//        request.relationshipKeyPathsForPrefetching = ["routePoints"]
//
//        // Optional: Sort descriptors if needed
//        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkout.startDate, ascending: false)]
//
//        return await fetchContext.perform { // Use perform for async fetch
//            do {
//                let workouts = try fetchContext.fetch(request)
//                self.logger.info("Fetched \(workouts.count) workouts from context.")
//                return workouts
//            } catch {
//                self.logger.error("❌ Failed to fetch workouts: \(error.localizedDescription)")
//                return []
//            }
//        }
//    }

    /// **[ORIGINAL - Kept for reference/convenience]** Returns all workouts stored in Core Data.
    /// Uses the refined `fetchWorkouts` internally.
    func fetchAllWorkouts(context: NSManagedObjectContext? = nil) async -> [CDWorkout] {
        // Default sort: newest first
        let defaultSort = [NSSortDescriptor(keyPath: \CDWorkout.startDate, ascending: false)]
        // Call the more generic fetch function
        return await fetchWorkouts(sortDescriptors: defaultSort, context: context)
    }

    func clearAllData() async {
        let backgroundContext = newBackgroundContext()
        let entities = persistenceContainer.managedObjectModel.entities

        await backgroundContext.perform { // deletion on bg context
            for entity in entities {
                guard let entityName = entity.name else {
                    continue
                }
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                // Set delete result type to count the num of deleted objs, not rlly needed but may be useful at some
                // point
                deleteRequest.resultType = .resultTypeCount

                do {
                    let result = try backgroundContext.execute(deleteRequest) as? NSBatchDeleteResult
                    let count = result?.result as? Int ?? 0
                    self.logger.info("✅ Cleared \(count) objects for entity: \(entityName)")
                } catch {
                    self.logger
                        .error(
                            "❌ Error clearing Core Data for entity \(entityName): \(error.localizedDescription)"
                        )
                }
            }

            // After batch delete, the main context won't know about the changes unless merged.
            // Since we're clearing everything, maybe resetting the main context is simpler,
            // or refetching data after clearing.
            // However, saving the background context should be sufficient if
            // automaticallyMergesChangesFromParent is true on the main context.
            self.saveContext(backgroundContext) // Save changes made by batch delete
        }

        // Consider explicitly resetting the main context if needed after a full clear
        // Or ensure UI reloads data after clearing.
        await MainActor.run {
            // mainContext.reset() // uncomment if needed
            logger.info("Core Data clearing complete.")
        }
    }
}
