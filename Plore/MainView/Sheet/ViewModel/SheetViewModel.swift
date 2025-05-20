//
//  SheetViewModel.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/19/25.
//

import Combine
import Foundation
import SwiftUI

/// ViewModel for SheetView, managing state, filtering logic, and interactions with HealthKit.
final class SheetViewModel: ObservableObject {
    // MARK: - Dependencies

    /// The object that interfaces with HealthKit regarding route data.
    @Published var healthKitManager: HealthKitManager

    // MARK: - Filtering State

    @Published var searchText: String = ""

    @Published var selectedDate: Date? = nil

    @Published var selectedRoute: RouteInfo? = nil

    /// Bindings that toggle whether walking routes should be shown.
    @Published var showWalkingRoutes: Bool

    /// Bindings that toggle whether running routes should be shown.
    @Published var showRunningRoutes: Bool

    /// Bindings that toggle whether cycling routes should be shown.
    @Published var showCyclingRoutes: Bool

    // MARK: - Routing/UI State

    /// The currently focused / selected route shown on the map.
    @Published var focusedRoute: RouteInfo?

    /// Controls route detail modal presentation.
    @Published var showRouteDetailSheet: Bool = false

    /// Controls whether route preview is shown in cards.
    @Published var showPreview: Bool = false

    /// Indicates if a search field is active/interactive.
    @Published var isSearchActive: Bool = false

    /// Shows first-time user tips section.
    @Published var showFirstTimeTips: Bool = false

    // MARK: - Sync/Progress State

    /// Whether a sync is currently in progress.
    @Published var isSyncing: Bool = false

    /// The time of last successful sync.
    @Published var lastSyncTime: Date? = nil

    /// Shows progress/loading bar.
    @Published var showLoadingProgress: Bool = false

    // MARK: - Route Editing State

    /// The route ID currently being edited, if any.
    @Published var isEditingRouteName: UUID? = nil

    /// The editing name value for renaming a route.
    @Published var editingName: String = ""

    /// For spinner rotation animation.
    @Published var loadingRotation: Double = 0

    /// Tracks if user has seen tips before (persisted).
    @AppStorage("hasSeenTips") var hasSeenTips: Bool = false

    // MARK: - Filtered Routes

    /// The list of filtered routes, updated by filters/search.
    @Published private(set) var filteredRoutes: [RouteInfo] = []

    // MARK: - Combine

    @Published var cancellables = Set<AnyPublisher>()

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager

        setupBindings()
        updateFilteredRoutes()
    }

    // MARK: - Bindings

    /// Sets up Combine pipelines to update filters when dependencies change.
    func setupBindings() {
        Publishers.CombineLatest4(
            $searchText,
            $selectedDate,
            $showWalkingRoutes,
            $showRunningRoutes
        )
        .combineLatest($showCyclingRoutes)
        .sink { [weak self] _, _ in
            self?.updateFilteredRoutes()
        }
        .store(in: &cancellables)

        // Sync loading state for showing progress
        healthKitManager.$isLoadingRoutes
            .assign(to: $showLoadingProgress)

        // Reload on HealthKit route changes
        healthKitManager.$runningRouteInfos
            .sink { [weak self] _ in self?.updateFilteredRoutes() }
            .store(in: &cancellables)

        healthKitManager.$walkingRouteInfos
            .sink { [weak self] _ in self?.updateFilteredRoutes() }
            .store(in: &cancellables)

        healthKitManager.$cyclingRouteInfos
            .sink { [weak self] _ in self?.updateFilteredRoutes() }
            .store(in: &cancellables)
    }

    // MARK: - Route Filtering Logic

    /// Updates the filteredRoutes list based on selected filters and search.
    func updateFilteredRoutes() {
        var routes = healthKitManager.getAllRouteInfosByDate(date: selectedDate)
        routes = routes.filter { route in
            switch route.type {
            case .walking: showWalkingRoutes
            case .running: showRunningRoutes
            case .cycling: showCyclingRoutes
            default: false
            }
        }

        if !searchText.isEmpty {
            routes = routes.filter { ($0.name ?? "Unknown Route").localizedCaseInsensitiveContains(searchText) }
        }
        routes.sort { $0.date > $1.date }
        filteredRoutes = routes
    }

    // MARK: - Sync Logic

    /// Triggers HealthKit sync and updates related states.
    func performSync() {
        isSyncing = true
        print("🔄 [SheetViewModel] Starting manual sync...")
        healthKitManager.syncData()

        // If syncData is async, wrap this in a Task and await it.
        lastSyncTime = Date()
        isSyncing = false
        print("✅ [SheetViewModel] Manual sync complete.")
        updateFilteredRoutes()
        if showFirstTimeTips {
            withAnimation {
                showFirstTimeTips = false
            }
        }
    }

    // MARK: - Helpers

    /// Formats a date as a relative string (e.g. "2 hours ago")
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
