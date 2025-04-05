//
//  ServiceFactory.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation

/// Factory class that provides access to all services using a singleton pattern
/// This helps with dependency injection and testability
class ServiceFactory {
    // MARK: - Singleton
    
    /// The shared instance of the service factory
    static let shared = ServiceFactory()
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // No-op
    }
    
    // MARK: - Services
    
    /// The CoreDataManager instance
    private(set) lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared
    }()
    
    /// The HealthKitService instance
    private(set) lazy var healthKitService: HealthKitService = {
        return HealthKitService()
    }()
    
    /// The PolylineFactory instance
    private(set) lazy var polylineFactory: PolylineFactory = {
        return PolylineFactory()
    }()
    
    /// The RouteRepository instance
    private(set) lazy var routeRepository: RouteRepository = {
        return RouteRepository(
            coreDataManager: coreDataManager,
            healthKitService: healthKitService,
            polylineFactory: polylineFactory
        )
    }()
    
    // MARK: - Reset (for testing)
    
    /// Resets all services (useful for testing)
    func resetAllServices() {
        // Reset any instances that need resetting
        // This is a hook for future testing support
    }
} 