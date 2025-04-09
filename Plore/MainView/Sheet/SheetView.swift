//
//  SheetView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import Foundation
import HealthKit
import SwiftUI

// MARK: - SampleView (Main Bottom Sheet)

/// A bottom sheet view with tabs and improved UI using ClaudeButton components.
///
/// This view displays user's workout routes with filtering capabilities by:
/// - Route type (walking, running, cycling)
/// - Date
/// - Text search
///
/// The view also allows for focused viewing of individual routes and editing route names.
struct SheetView: View {
    // MARK: - Properties

    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600

    /// The search text.
    @State private var searchText: String = ""

    /// Indicates if sync is in progress
    @State private var isSyncing = false

    /// Last sync time
    @State private var lastSyncTime: Date? = nil

    /// The date selected to be filtered by.
    @State private var selectedDate: Date? = nil

    /// The currently selected route for focusing on the map
    @State private var selectedRoute: RouteInfo? = nil
    
    /// Control for route detail sheet
    @State private var showRouteDetailSheet = false
    
    /// Controls whether map preview is shown in route cards
    @State private var showPreview: Bool = false
    
    /// Whether the search is active/interactive.
    @State private var isSearchActive = false
    
    /// Whether the Settings panel is showing.
    @State private var isShowingSettingsPanel = false

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager: HealthKitManager

    /// Bindings that toggle whether walking routes should be shown.
    @Binding var showWalkingRoutes: Bool

    /// Bindings that toggle whether running routes should be shown.
    @Binding var showRunningRoutes: Bool

    /// Bindings that toggle whether cycling routes should be shown.
    @Binding var showCyclingRoutes: Bool

    @Binding var selectedFilterDate: Date?
    
    @Binding var focusedRoute: RouteInfo?

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void
    let showRouteDetailView: () -> Void

    let onRouteSelected: (RouteInfo) -> Void
    let onDateFilterChanged: (() -> Void)?

    @State private var filteredRoutes: [RouteInfo] = []
    @State private var isEditingRouteName: UUID? = nil
    @State private var editingName: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top search bar
            searchBarHeader
                .padding(.top, 15)
                .padding(.bottom, 5)
            
            // Filter chips when search is active
            if isSearchActive {
                filterChipsRow
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
            
            // Main tab content
            tabContentSection
        }
        .sheet(isPresented: $showRouteDetailSheet) {
            if let route = selectedRoute {
                RouteDetailView(route: route)
            }
        }
        .onAppear {
            // Fix for routes not appearing on initial load
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // Half second delay
                updateFilteredRoutes()
            }
        }
    }
    
    // MARK: - Search Bar Header
    
    /// The search bar header at the top of the view.
    private var searchBarHeader: some View {
        HStack {
            // Search bar that stays in place
            ImprovedSearchBarView(
                searchText: $searchText,
                selectedDate: $selectedDate,
                isInteractive: $isSearchActive,
                onFilterChanged: {
                    updateFilteredRoutes()
                }
            )
            .onTapGesture {
                if !isSearchActive {
                    isSearchActive = true
                }
            }

            // Settings button
            Button {
                isShowingSettingsPanel.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Filter Chips Row
    
    /// Row of filter chips for route types
    private var filterChipsRow: some View {
        HStack(spacing: 10) {
            // Done button
            Button {
                isSearchActive = false
                // Apply current filters
                updateFilteredRoutes()
            } label: {
                Text("Done")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            Spacer()
            

            
            // Running filter
            filterChip(
                isSelected: $showRunningRoutes,
                color: .red,
                icon: "figure.run"
            )
            
            
            // Cycling filter
            filterChip(
                isSelected: $showCyclingRoutes,
                color: .green,
                icon: "figure.outdoor.cycle"
            )
            
            // Walking filter
            filterChip(
                isSelected: $showWalkingRoutes,
                color: .blue,
                icon: "figure.walk"
            )
        }
    }
    
    /// A filter chip button for route types.
    private func filterChip(isSelected: Binding<Bool>, color: Color, icon: String) -> some View {
        Button {
            isSelected.wrappedValue.toggle()
            updateFilteredRoutes()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected.wrappedValue ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected.wrappedValue ? color : .gray)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected.wrappedValue ? color : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Settings Panel

    private var settingsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                        isShowingSettingsPanel = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .padding()
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.title.bold())
                        .padding(.bottom, 10)

                    // Route visibility toggles
                    routeVisibilitySettings
                    
                    // Other settings
                    Toggle("Dark Mode", isOn: .constant(false))
                    Toggle("Show Distance", isOn: .constant(true))

                    Divider().padding(.vertical)

                    Text("Version 1.0.0 • Build 2025.03.23")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    /// Route visibility toggle settings.
    private var routeVisibilitySettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route Visibility")
                .font(.headline)
                .padding(.bottom, 4)
            
            Toggle("Show Walking Routes", isOn: $showWalkingRoutes)
                .onChange(of: showWalkingRoutes) { _, _ in
                    updateFilteredRoutes()
                }
            
            Toggle("Show Running Routes", isOn: $showRunningRoutes)
                .onChange(of: showRunningRoutes) { _, _ in
                    updateFilteredRoutes()
                }
            
            Toggle("Show Cycling Routes", isOn: $showCyclingRoutes)
                .onChange(of: showCyclingRoutes) { _, _ in
                    updateFilteredRoutes()
                }
        }
    }
    
    // MARK: - Tab Content Section
    
    /// The tab content section for the main views.
    private var tabContentSection: some View {
        VStack(spacing: 0) {
            // Routes list section
        routesTabContent
        }
        .padding(.top, 10)
    }

    // MARK: - Routes Tab Content

    /// Routes tab content with status, toggles, and route list.
    private var routesTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sync status section
                syncStatusSection

                // Only show route toggles in non-search mode for quick filtering
                if !isSearchActive {
                routeToggleSection
                }

                // Route list
                routeListSection
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
                                        .overlay(
            isShowingSettingsPanel ? settingsOverlay : nil
        )
    }
    
    // MARK: - Route Tab Subviews
    
    /// The sync status section showing route counts and sync button.
    private var syncStatusSection: some View {
                    VStack(spacing: 12) {
                            HStack {
                Text("Route Data")
                    .font(.headline)
                                Spacer()

                // Sync button
                            ClaudeButton(
                    "Sync",
                                color: .blue,
                    size: .small,
                                rounded: true,
                                icon: Image(systemName: "arrow.triangle.2.circlepath"),
                                style: .modernAqua
                            ) {
                                performSync()
                            }
                            .disabled(isSyncing)
                            .opacity(isSyncing ? 0.7 : 1.0)
                        }
            
            // Show focused route indicator or route counts
            if focusedRoute != nil {
                focusedRouteIndicator
            } else {
                routeCountsCards
            }

                        // Last sync info
                        if let lastSync = lastSyncTime {
                            Text("Last synced: \(timeAgoString(from: lastSync))")
                                .font(.caption)
                                .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    /// Focused route indicator when a specific route is selected.
    private var focusedRouteIndicator: some View {
                        HStack {
            Text("Showing only: \(focusedRoute?.name ?? "Selected Route")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
                            Spacer()
            
            Button {
                focusedRoute = nil
            } label: {
                Text("Show All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
                    .background(
            RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
    }
    
    /// Route count cards showing summary information.
    private var routeCountsCards: some View {
        HStack(spacing: 20) {
            routeCountCard(
                count: healthKitManager.runningRoutes.count,
                title: "Running",
                color: .red,
                icon: "figure.run"
            )
            routeCountCard(
                count: healthKitManager.cyclingRoutes.count,
                title: "Cycling",
                color: .green,
                icon: "figure.outdoor.cycle"
            )
            routeCountCard(
                count: healthKitManager.walkingRoutes.count,
                title: "Walking",
                    color: .blue,
                icon: "figure.walk"
            )
        }
    }
    
    /// Quick toggle buttons for route types.
    private var routeToggleSection: some View {
        HStack(spacing: 12) {
            // Streamlined, elegant toggle buttons
            routeToggleButton(
                title: "Running",
                isOn: $showRunningRoutes,
                color: .red,
                icon: "figure.run"
            )
            routeToggleButton(
                title: "Cycling",
                isOn: $showCyclingRoutes,
                color: .green,
                icon: "figure.outdoor.cycle"
            )
            routeToggleButton(
                title: "Walking",
                isOn: $showWalkingRoutes,
                color: .blue,
                icon: "figure.walk"
            )
        }
    }
    
    /// The list of routes section, or empty view if no routes match filters.
    private var routeListSection: some View {
                VStack(spacing: 10) {
            // Title and count
                        HStack {
                Text("Routes")
                    .font(.title3)
                    .fontWeight(.bold)

                            Spacer()

                Text("\(filteredRoutes.count) routes")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            // Routes list or empty state
            if filteredRoutes.isEmpty {
                emptyRoutesView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRoutes) { route in
                        CollapsibleRouteRow(
                            route: route,
                            isEditing: isEditingRouteName == route.id,
                            editingName: $editingName,
                            onEditComplete: {
                                if !editingName.isEmpty {
                                    healthKitManager.updateRouteName(id: route.id, newName: editingName)
                                }
                                isEditingRouteName = nil
                            },
                            onEditStart: {
                                editingName = route.name ?? ""
                                isEditingRouteName = route.id
                            },
                            onRouteSelected: { selectedRoute in
                                handleRouteSelection(selectedRoute)
                            }
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            updateFilteredRoutes()
        }
        .onChange(of: selectedFilterDate) { _, _ in
            updateFilteredRoutes()
        }
    }
    
    /// Empty state view when no routes match the current filters.
    private var emptyRoutesView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 20)
            
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
                Text("No routes found")
                .font(.title3)
                .fontWeight(.medium)
            
            if selectedFilterDate != nil || !searchText.isEmpty {
                Text("Try adjusting your search or filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Start a workout to see your routes here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
                .frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Helper Views

    /// A route count card with icon, count, and title.
    private func routeCountCard(count: Int, title: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            // Icon above the count
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
                .contentTransition(.numericText())

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Base surface
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))

                // Color tint overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.08))

                // Border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(color.opacity(0.25), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(title)")
    }

    /// A route toggle button for quick filtering.
    private func routeToggleButton(title: String, isOn: Binding<Bool>, color: Color, icon: String) -> some View {
        Button {
            // Toggle with animation
                isOn.wrappedValue.toggle()
            updateFilteredRoutes() // Update routes immediately
        } label: {
            VStack(spacing: 6) {
                // Icon with circle background
                ZStack {
                Circle()
                        .fill(isOn.wrappedValue ? color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: isOn.wrappedValue ? .bold : .regular))
                        .foregroundColor(isOn.wrappedValue ? color : .gray)
                }

                // Label
                Text(title)
                    .font(.system(size: 12, weight: isOn.wrappedValue ? .medium : .regular))
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Base shape
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))

                    // Color fill when active
                    if isOn.wrappedValue {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.opacity(0.1))
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isOn.wrappedValue ? color.opacity(0.3) : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
    }

    // MARK: - Helper Functions

    /// Handle when a user selects a route from the list.
    /// - Parameter route: The route that was selected
    private func handleRouteSelection(_ route: RouteInfo) {
        // Option 1: Show route detail sheet if preview is showing
        if showPreview {
            selectedRoute = route
            showRouteDetailSheet = true
        } else {
            // Option 2: Focus on the route in the main map
            focusedRoute = route
            onRouteSelected(route)
        }
    }
    
    /// Perform synchronization with HealthKit
    private func performSync() {
        // Start the sync process
        isSyncing = true

        // Using Task to properly handle async operations
        Task {
            do {
                // Simulate network request
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

                // Use the main thread for UI updates
                Task { @MainActor in
                    // Load routes more efficiently
                    await healthKitManager.loadRoutes()

                    // Update state
                    lastSyncTime = Date()
                    isSyncing = false
                    
                    // Update filtered routes after sync
                    updateFilteredRoutes()
                }
            } catch {
                // Handle any errors
                print("Sync error: \(error)")

                await MainActor.run {
                    isSyncing = false
                }
            }
        }
    }

    /// Format a date as a relative time string (e.g., "2 hours ago")
    /// - Parameter date: The date to format
    /// - Returns: A string representing the relative time
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Returns the color associated with a route type
    private func colorForRoute(_ route: String) -> Color {
        if route.contains("Walking") {
            return .blue
        } else if route.contains("Running") {
            return .red
        } else if route.contains("Cycling") {
            return .green
        }
        return .gray
    }

    /// Determine the icon for a given action
    private func iconForAction(_ action: String) -> String {
        switch action {
        case "Check Weather": "cloud.sun"
        case "Track Package": "shippingbox"
        case "Start Workout": "figure.run"
        case "Find Transit": "bus"
        default: "star"
        }
    }

    /// Updates the filtered routes based on selection criteria
    ///
    /// This method filters routes based on:
    /// - Selected date
    /// - Route type toggles (walking, running, cycling)
    /// - Search text
    private func updateFilteredRoutes() {
        // Get all routes based on date filter
        var routeInfos = healthKitManager.getAllRouteInfosByDate(date: selectedFilterDate)
        
        // Apply activity type filters
        routeInfos = routeInfos.filter { route in
            switch route.type {
            case .walking:
                return showWalkingRoutes
            case .running:
                return showRunningRoutes
            case .cycling:
                return showCyclingRoutes
            default:
                return false
            }
        }
        
        // Apply text search if needed
        if !searchText.isEmpty {
            routeInfos = routeInfos.filter { route in
                let name = route.name ?? "Unknown Route"
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by date, newest first
        routeInfos.sort { $0.date > $1.date }
        
        filteredRoutes = routeInfos
        
        // Update the filter on the ContentView
        onDateFilterChanged?()
    }
}

// MARK: - Route Row

import SwiftUI
import HealthKit
import MapKit

/// A beautifully designed row displaying a route's information with editable name and navigation capability.
struct EnhancedRouteRow: View {
    // MARK: - Properties
    let route: RouteInfo
    let isEditing: Bool
    @Binding var editingName: String
    let onEditComplete: () -> Void
    let onEditStart: () -> Void
    let onRouteSelected: (RouteInfo) -> Void
    
    @State private var showPreview: Bool = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Route header with name and edit button
            routeHeaderView
            
            // Route details
            routeDetailsView
            
            // Map preview (conditionally shown)
            if showPreview {
                mapPreviewWithNavigation
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(routeTypeColor(for: route.type).opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle()) // Make the whole card tappable
        .onTapGesture {
            if !isEditing {
                onRouteSelected(route)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Header view with route name and edit button
    private var routeHeaderView: some View {
        HStack(spacing: 12) {
            // Route activity icon
            ZStack {
                Circle()
                    .fill(routeTypeColor(for: route.type).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: routeTypeIcon(for: route.type))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(routeTypeColor(for: route.type))
            }
            
            // Route name / Edit field
            if isEditing {
                TextField("Route name", text: $editingName)
                    .font(.headline)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onSubmit {
                        onEditComplete()
                    }
            } else {
                Text(route.name ?? routeTypeName(for: route.type))
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Edit/Save button
            Button {
                if isEditing {
                    onEditComplete()
                } else {
                    onEditStart()
                }
            } label: {
                Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil")
                    .font(.system(size: 18))
                    .foregroundColor(isEditing ? .green : .gray)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(isEditing ? Color.green.opacity(0.15) : Color(.systemGray6))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    /// Details view with metadata about the route
    private var routeDetailsView: some View {
        VStack(spacing: 10) {
            Divider()
                .padding(.vertical, 10)
            
            HStack(spacing: 16) {
                // Date info
                dateInfoView
                
                Divider()
                    .frame(height: 30)
                
                // Distance or other metrics
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(calculateDistance())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Toggle preview button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        showPreview.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showPreview ? "Hide Map" : "Show Map")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: showPreview ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    /// Date information formatted nicely
    private var dateInfoView: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(formattedDate(route.date))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(formattedTime(route.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Map preview with navigation option
    private var mapPreviewWithNavigation: some View {
        ZStack(alignment: .bottomTrailing) {
            // The map preview
            routePreviewMap
                .frame(height: 150)
                .cornerRadius(12)
                .padding(.top, 8)
            
            // Navigation button overlay
            Button {
                onRouteSelected(route)
            } label: {
                HStack(spacing: 4) {
                    Text("View Full Map")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                )
                .foregroundColor(routeTypeColor(for: route.type))
            }
            .padding(12)
        }
    }
    
    /// Map preview of the route
    private var routePreviewMap: some View {
        Map {
            MapPolyline(route.polyline)
                .stroke(routeTypeColor(for: route.type), lineWidth: 3)
                
            if let firstLocation = route.locations.first {
                Annotation("Start", coordinate: firstLocation.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(radius: 2)
                        
                        Circle()
                            .fill(routeTypeColor(for: route.type))
                            .frame(width: 16, height: 16)
                    }
                }
            }
            
            if let lastLocation = route.locations.last, route.locations.count > 1 {
                Annotation("End", coordinate: lastLocation.coordinate) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .shadow(radius: 2)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(routeTypeColor(for: route.type))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the icon name for a route type.
    private func routeTypeIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        default: return "mappin.and.ellipse"
        }
    }
    
    /// Returns the display name for a route type.
    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walking Route"
        case .running: return "Running Route"
        case .cycling: return "Cycling Route"
        default: return "Unknown Route"
        }
    }
    
    /// Returns the color for a route type.
    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking: return .blue
        case .running: return .red
        case .cycling: return .green
        default: return .gray
        }
    }
    
    /// Formats a date for display.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Formats a time for display.
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Calculate distance for the route
    private func calculateDistance() -> String {
        guard route.locations.count > 1 else {
            return "0.0 mi"
        }
        
        // Calculate total distance
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(route.locations.count - 1) {
            let current = route.locations[i]
            let next = route.locations[i + 1]
            totalDistance += current.distance(from: next)
        }
        
        // Convert to miles (or km based on locale)
        let distanceInMiles = totalDistance / 1609.34
        return String(format: "%.1f mi", distanceInMiles)
    }
}

/// A row displaying a route's information with editable name.
struct RouteRow: View {
    let route: RouteInfo
    let isEditing: Bool
    @Binding var editingName: String
    let onEditComplete: () -> Void
    let onEditStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Route name and edit button
            HStack {
                if isEditing {
                    TextField("Route name", text: $editingName)
                        .font(.headline)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .onSubmit {
                            onEditComplete()
                        }
                } else {
                    Text(route.name ?? "Unnamed Route")
                        .font(.headline)
                }

                Spacer()

                Button {
                    if isEditing {
                        onEditComplete()
                    } else {
                        onEditStart()
                    }
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(.system(size: 14))
                        .padding(6)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }

            // Route details
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: routeTypeIcon(for: route.type))
                        .font(.system(size: 14))
                        .foregroundColor(routeTypeColor(for: route.type))

                    Text(routeTypeName(for: route.type))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Format date
                Text(formattedDate(route.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }

    /// Returns the icon name for a route type.
    private func routeTypeIcon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "figure.walk"
        case .running: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        default: "mappin.and.ellipse"
        }
    }

    /// Returns the display name for a route type.
    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: "Walking"
        case .running: "Running"
        case .cycling: "Cycling"
        default: "Unknown"
        }
    }

    /// Returns the color for a route type.
    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking: .blue
        case .running: .red
        case .cycling: .green
        default: .gray
        }
    }

    /// Formats a date for display.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
//
//#Preview {
//    SampleView(
//        healthKitManager: HealthKitManager(), // Replace with a mock if needed
//        showWalkingRoutes: .constant(true),
//        showRunningRoutes: .constant(true),
//        showCyclingRoutes: .constant(true),
//        selectedFilterDate: .constant(nil),
//        onOpenAppTap: {},
//        onNoteTap: {},
//        onPetalTap: {},
//        onDateFilterChanged: nil
//    )
//}
//
//#Preview {
//    SampleView(
//        healthKitManager: HealthKitManager(), // Replace with a mock if needed
//        showWalkingRoutes: .constant(true),
//        showRunningRoutes: .constant(true),
//        showCyclingRoutes: .constant(true),
//        selectedFilterDate: .constant(nil),
//        onOpenAppTap: {},
//        onNoteTap: {},
//        onPetalTap: {},
//        onDateFilterChanged: nil
//    )
//    .preferredColorScheme(.dark)
//}


// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    let locations = [
        CLLocation(latitude: 37.7749, longitude: -122.4194),
        CLLocation(latitude: 37.7750, longitude: -122.4195),
        CLLocation(latitude: 37.7751, longitude: -122.4196),
        CLLocation(latitude: 37.7753, longitude: -122.4198),
        CLLocation(latitude: 37.7755, longitude: -122.4199)
    ]

    let routeInfo = RouteInfo(
        name: "Morning Run in Golden Gate Park",
        type: .running,
        date: Date(),
        locations: locations
    )

    return RouteDetailView(route: routeInfo)
}

