//
//  RouteListViewModel.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import Combine
import SwiftUI
import HealthKit
import os
import CoreLocation

/// ViewModel responsible for managing the state of the route list view (bottom sheet)
class RouteListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All routes loaded from HealthKit
    @Published private(set) var routes: [WorkoutRoute] = []
    
    /// Routes filtered by current search/filter criteria
    @Published private(set) var filteredRoutes: [WorkoutRoute] = []
    
    /// Whether we're currently syncing routes from HealthKit
    @Published var isSyncing: Bool = false
    
    /// Controls which types of routes are shown
    @Published var showRunning: Bool = true {
        didSet { applyFilters() }
    }
    
    @Published var showCycling: Bool = true {
        didSet { applyFilters() }
    }
    
    @Published var showWalking: Bool = true {
        didSet { applyFilters() }
    }
    
    /// The text entered in the search bar
    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }
    
    /// Whether the detailed search UI is shown
    @Published var isSearching: Bool = false
    
    /// Whether the settings UI is shown
    @Published var isShowingSettings: Bool = false
    
    /// Start date for filtering routes
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date() {
        didSet { applyFilters() }
    }
    
    /// End date for filtering routes
    @Published var endDate: Date = Date() {
        didSet { applyFilters() }
    }
    
    /// Time interval for syncing (3 months, 6 months, 1 year, or all)
    @Published var selectedSyncInterval: SyncInterval = .threeMonths {
        didSet {
            updateDateRangeFromSyncInterval()
            applyFilters()
        }
    }
    
    /// Selected route for detailed view
    @Published var selectedRoute: WorkoutRoute?
    
    // MARK: - Callback Closures
    
    /// Called when filter criteria change
    var onFilterChange: ((_ criteria: FilterCriteria) -> Void)?
    
    /// Called when a route is selected
    var onRouteSelect: ((_ routeId: UUID) -> Void)?
    
    /// Called when zoom should be cleared
    var onClearZoom: (() -> Void)?
    
    /// Called when the Open App button is tapped
    var onOpenAppTap: (() -> Void)?
    
    /// Called when the Note button is tapped
    var onNoteTap: (() -> Void)?
    
    /// Called when the Petal button is tapped
    var onPetalTap: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// The HealthKit manager instance
    private let healthKitManager = HealthKitManager.shared
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Load initial data
        Task {
            await loadRoutes()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads routes from HealthKit
    func loadRoutes() async {
        await MainActor.run {
            self.isSyncing = true
        }
        
        do {
            // Use the date range for fetching workouts
            let fetchedRoutes = try await healthKitManager.fetchWorkoutsWithRoutes(
                startDate: startDate,
                endDate: endDate
            )
            
            await MainActor.run {
                self.routes = fetchedRoutes
                self.applyFilters()
                self.isSyncing = false
            }
        } catch {
            print("Error loading routes: \(error)")
            await MainActor.run {
                self.isSyncing = false
            }
        }
    }
    
    /// Selects a route for detailed view or zooming on map
    func selectRoute(_ route: WorkoutRoute) {
        self.selectedRoute = route
        onRouteSelect?(route.id)
    }
    
    /// Clears the currently selected route
    func clearSelectedRoute() {
        self.selectedRoute = nil
        onClearZoom?()
    }
    
    /// Updates the sync interval and refreshes routes
    func updateSyncInterval(_ interval: SyncInterval) {
        self.selectedSyncInterval = interval
        Task {
            await loadRoutes()
        }
    }
    
    /// Handles the Open App button tap
    func handleOpenAppTap() {
        onOpenAppTap?()
    }
    
    /// Handles the Note button tap
    func handleNoteTap() {
        onNoteTap?()
    }
    
    /// Handles the Petal button tap
    func handlePetalTap() {
        onPetalTap?()
    }
    
    // MARK: - Private Methods
    
    /// Updates the date range based on the selected sync interval
    private func updateDateRangeFromSyncInterval() {
        let now = Date()
        switch selectedSyncInterval {
        case .threeMonths:
            startDate = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            startDate = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            startDate = Calendar.current.date(byAdding: .year, value: -10, to: now) ?? now
        }
        endDate = now
    }
    
    /// Applies the current filter criteria to the routes
    private func applyFilters() {
        var filtered = routes
        
        // Filter by activity type
        filtered = filtered.filter { route in
            (showRunning && route.workoutActivityType == .running) ||
            (showCycling && route.workoutActivityType == .cycling) ||
            (showWalking && (route.workoutActivityType == .walking || route.workoutActivityType == .hiking))
        }
        
        // Filter by date range
        filtered = filtered.filter { route in
            if let date = route.startDate {
                return date >= startDate && date <= endDate
            }
            return false
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { route in
                let searchableText = [
                    route.name,
                    route.formattedDistance,
                    route.formattedDate
                ].compactMap { $0 }.joined(separator: " ").lowercased()
                
                return searchableText.contains(searchText.lowercased())
            }
        }
        
        // Sort by date, most recent first
        filtered.sort { (route1, route2) -> Bool in
            guard let date1 = route1.startDate, let date2 = route2.startDate else {
                return false
            }
            return date1 > date2
        }
        
        self.filteredRoutes = filtered
        
        // Notify of filter changes
        let criteria = FilterCriteria(
            showRunning: showRunning,
            showCycling: showCycling,
            showWalking: showWalking,
            startDate: startDate,
            endDate: endDate,
            searchText: searchText
        )
        onFilterChange?(criteria)
    }
}

// MARK: - Supporting Types

/// Filter criteria for routes
struct FilterCriteria {
    let showRunning: Bool
    let showCycling: Bool
    let showWalking: Bool
    let startDate: Date
    let endDate: Date
    let searchText: String
}

/// Time intervals for syncing routes
enum SyncInterval: String, CaseIterable, Identifiable {
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    case all = "All Time"
    
    var id: String { self.rawValue }
} 