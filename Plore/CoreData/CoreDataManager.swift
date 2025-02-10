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

/// A singleton that manages the Core Data stack and provides an interface for saving/fetching  data.
final class CoreDataManager {

    // MARK: Properties

    /// The static shared instance.
    static let shared = CoreDataManager()

    // MARK: Persistence Container

    lazy var persistenceContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HealthRoutes")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    /// A convenient main-thread context for quick reads/writes
    var mainContext: NSManagedObjectContext {
        persistenceContainer.viewContext
    }

    // MARK: Save Context

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
    func fetchOrCreateWorkout(from hkWorkout: HKWorkout, in context: NSManagedObjectContext) -> CDWorkout {
        // pkey
        let workoutId = hkWorkout.uuid.uuidString

        let fetchRequest: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", workoutId)

        do {
            let results = try context.fetch(fetchRequest)
            if let existingWorkout = results.first {
                return existingWorkout
            }
        } catch {
            print("❌ Error fetching workout: \(error.localizedDescription)")
        }

        let newWorkout = CDWorkout(context: context)
        newWorkout.id = workoutId
        newWorkout.startDate = hkWorkout.startDate
        newWorkout.endDate = hkWorkout.endDate
        newWorkout.type = String(hkWorkout.workoutActivityType.rawValue)
        newWorkout.isIndoor = (hkWorkout.metadata?["HKWorkoutMetadataIndoor"] as? Bool) ?? false
        return newWorkout
    }

    // MARK: Add RoutePoints

    /// Creates and inserts CDRoutePoint objects for the provided locations, linking them to the parent workout.
    func addRoutePoints(_ locations: [CLLocation], to cdWorkout: CDWorkout, in context: NSManagedObjectContext) {
        for loc in locations {
            let cdPoint = CDRoutePoint(context: context)
            cdPoint.latitude = loc.coordinate.latitude
            cdPoint.longitude = loc.coordinate.longitude
            cdPoint.timestamp = loc.timestamp
            cdPoint.workout = cdWorkout
        }
    }

    // MARK: Fetch All Workouts from Core Data

    /// Returns all workouts stored in Core Data (with prefetching routePoints if desired).
    func fetchAllWorkouts() -> [CDWorkout] {
        let context = mainContext
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        // Optionally prefetch routePoints to avoid multiple round-trips:
        request.relationshipKeyPathsForPrefetching = ["routePoints"]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch workouts: \(error.localizedDescription)")
            return []
        }
    }

    func clearAllData() {
        let entities = persistenceContainer.managedObjectModel.entities

        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try persistenceContainer.viewContext.execute(deleteRequest)
                print("✅ Cleared Core Data for entity: \(entity.name!)")
            } catch {
                print("❌ Error clearing Core Data: \(error.localizedDescription)")
            }
        }

        saveContext()
    }

}
