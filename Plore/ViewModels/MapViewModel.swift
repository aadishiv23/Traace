//
//  MapViewModel.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import MapKit
import Combine
import SwiftUI
import HealthKit

/// ViewModel responsible for managing the state of the map view
class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Routes that should be displayed on the map
    @Published private(set) var displayableRoutes: [WorkoutRoute] = []
    
    /// The visible region of the map
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    /// Whether the map is currently loading data
    @Published private(set) var isLoading: Bool = false
    
    /// The currently active filter criteria
    @Published private(set) var activeFilters = FilterCriteria(
        showRunning: true, 
        showCycling: true, 
        showWalking: true,
        startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        endDate: Date(),
        searchText: ""
    )
    
    /// ID of the route currently zoomed to (if any)
    @Published var zoomedRouteID: UUID? = nil
    
    // MARK: - Private Properties
    
    /// The HealthKit manager for data access
    private let healthKitManager = HealthKitManager.shared
    
    /// All routes loaded from HealthKit (before filtering)
    private var allRoutes: [WorkoutRoute] = []
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Set up automatic reloading when filters change
        $activeFilters
            .dropFirst() // Skip initial value
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadRoutes()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    /// Loads routes from HealthKit based on the active filters
    func loadRoutes() async {
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            // Fetch routes from HealthKit using current date filters
            let routes = try await healthKitManager.fetchWorkoutsWithRoutes(
                startDate: activeFilters.startDate,
                endDate: activeFilters.endDate
            )
            
            await MainActor.run {
                // Store all routes for later filtering
                self.allRoutes = routes
                
                // Apply filters to determine which routes to display
                self.applyCurrentFilters()
                
                self.isLoading = false
            }
        } catch {
            print("Error loading routes: \(error)")
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Filtering
    
    /// Updates the active filters with the provided new filters
    /// - Parameter newFilters: The new filter criteria to apply
    func applyFilters(_ newFilters: FilterCriteria) {
        // Clear zoomed route when applying new filters
        zoomedRouteID = nil
        
        // Update active filters
        activeFilters = newFilters
        
        // Re-apply filters to existing routes
        applyCurrentFilters()
    }
    
    /// Applies the current filter settings to the loaded routes
    private func applyCurrentFilters() {
        // Start with all routes
        var filtered = allRoutes
        
        // Filter by activity type
        filtered = filtered.filter { route in
            (activeFilters.showRunning && route.workoutActivityType == .running) ||
            (activeFilters.showCycling && route.workoutActivityType == .cycling) ||
            (activeFilters.showWalking && (route.workoutActivityType == .walking || route.workoutActivityType == .hiking))
        }
        
        // Filter by search text if present
        if !activeFilters.searchText.isEmpty {
            let searchText = activeFilters.searchText.lowercased()
            filtered = filtered.filter { route in
                let searchableText = [
                    route.name,
                    route.formattedDistance,
                    route.formattedDate
                ].compactMap { $0 }.joined(separator: " ").lowercased()
                
                return searchableText.contains(searchText)
            }
        }
        
        // If zoomed to a specific route, only show that route
        if let zoomedID = zoomedRouteID {
            filtered = filtered.filter { $0.id == zoomedID }
        }
        
        // Update displayable routes
        self.displayableRoutes = filtered
        
        // Update map region
        if !filtered.isEmpty {
            if zoomedRouteID != nil, let route = filtered.first {
                // If zoomed to a route, focus on that one
                fitMapToRoute(route)
            } else {
                // Otherwise fit the map to show all routes
                fitMapToRoutes(filtered)
            }
        }
    }
    
    // MARK: - Route Zooming
    
    /// Zooms the map to show only the specified route
    /// - Parameter id: The ID of the route to zoom to
    func zoomToRoute(id: UUID) {
        // Set the zoomed route ID
        zoomedRouteID = id
        
        // Find the route in our cached routes
        if let route = allRoutes.first(where: { $0.id == id }) {
            // Update the map region to fit this route
            fitMapToRoute(route)
        }
        
        // Re-apply filters to update the display
        applyCurrentFilters()
    }
    
    /// Clears the zoomed route and shows all routes again
    func clearZoom() {
        // Clear the zoomed route ID
        zoomedRouteID = nil
        
        // Re-apply filters
        applyCurrentFilters()
    }
    
    // MARK: - Map Region Helpers
    
    /// Fits the map to a single route
    /// - Parameter route: The route to fit
    private func fitMapToRoute(_ route: WorkoutRoute) {
        guard let polyline = route.polyline else { return }
        
        // Get the bounding map rect for the polyline
        let rect = polyline.boundingMapRect
        
        // Add some padding
        let insetRect = rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
        
        // Convert to a region
        var region = MKCoordinateRegion(insetRect)
        
        // Ensure reasonable zoom level
        region.span.latitudeDelta = max(region.span.latitudeDelta, 0.005)
        region.span.longitudeDelta = max(region.span.longitudeDelta, 0.005)
        
        // Update the map region
        self.mapRegion = region
    }
    
    /// Fits the map to show all the provided routes
    /// - Parameter routes: The routes to fit
    private func fitMapToRoutes(_ routes: [WorkoutRoute]) {
        guard !routes.isEmpty else { return }
        
        // Get all polylines that exist
        let polylines = routes.compactMap { $0.polyline }
        guard !polylines.isEmpty else { return }
        
        // If we only have one polyline, use the simpler method
        if polylines.count == 1, let polyline = polylines.first {
            // Get the bounding map rect for the polyline
            let rect = polyline.boundingMapRect
            
            // Add some padding
            let insetRect = rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
            
            // Convert to a region
            var region = MKCoordinateRegion(insetRect)
            
            // Ensure reasonable zoom level
            region.span.latitudeDelta = max(region.span.latitudeDelta, 0.005)
            region.span.longitudeDelta = max(region.span.longitudeDelta, 0.005)
            
            // Update the map region
            self.mapRegion = region
            return
        }
        
        // Start with the first polyline's bounding rect
        var boundingRect = polylines.first!.boundingMapRect
        
        // Union with all other routes' rects
        for polyline in polylines.dropFirst() {
            boundingRect = boundingRect.union(polyline.boundingMapRect)
        }
        
        // Add some padding
        let insetRect = boundingRect.insetBy(dx: -boundingRect.width * 0.1, dy: -boundingRect.height * 0.1)
        
        // Convert to a region
        var region = MKCoordinateRegion(insetRect)
        
        // Ensure reasonable zoom level
        region.span.latitudeDelta = max(region.span.latitudeDelta, 0.005)
        region.span.longitudeDelta = max(region.span.longitudeDelta, 0.005)
        
        // Update the map region
        self.mapRegion = region
    }
}

// MARK: - MKCoordinateRegion Extension

extension MKCoordinateRegion {
    /// Initialize an MKCoordinateRegion from an MKMapRect
    /// - Parameter mapRect: The MKMapRect to convert
    init(_ mapRect: MKMapRect) {
        let center = mapRect.midCoordinate
        let span = MKCoordinateSpan(
            latitudeDelta: mapRect.coordinateSpan.latitudeDelta,
            longitudeDelta: mapRect.coordinateSpan.longitudeDelta
        )
        self.init(center: center, span: span)
    }
}

// MARK: - MKMapRect Extensions

extension MKMapRect {
    /// Get the coordinate at the center of the map rect
    var midCoordinate: CLLocationCoordinate2D {
        let midPoint = MKMapPoint(x: midX, y: midY)
        return midPoint.coordinate
    }
    
    /// Get the coordinate span of the map rect
    var coordinateSpan: MKCoordinateSpan {
        let topLeft = MKMapPoint(x: minX, y: minY).coordinate
        let bottomRight = MKMapPoint(x: maxX, y: maxY).coordinate
        
        return MKCoordinateSpan(
            latitudeDelta: abs(bottomRight.latitude - topLeft.latitude),
            longitudeDelta: abs(bottomRight.longitude - topLeft.longitude)
        )
    }
} 