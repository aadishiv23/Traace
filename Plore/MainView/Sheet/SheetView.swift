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
//                if !isSearchActive {
//                    routeToggleSection
//                }

                // Route list
                routeListSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
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
            Text("Showing \(focusedRoute?.name ?? "Selected Route") on map")
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
                icon: "figure.run",
                isOn: $showRunningRoutes
            )
            routeCountCard(
                count: healthKitManager.cyclingRoutes.count,
                title: "Cycling",
                color: .green,
                icon: "figure.outdoor.cycle",
                isOn: $showCyclingRoutes
            )
            routeCountCard(
                count: healthKitManager.walkingRoutes.count,
                title: "Walking",
                color: .blue,
                icon: "figure.walk",
                isOn: $showWalkingRoutes
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
                    .contentTransition(.numericText(countsDown: false))
            }

            // Routes list or empty state
            if filteredRoutes.isEmpty {
                emptyRoutesView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRoutes) { route in
                        withAnimation(.easeInOut(duration: 0.2)) {
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
                            .transition(.opacity)
                        }
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
    private func routeCountCard(
        count: Int,
        title: String,
        color: Color,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.wrappedValue.toggle()
                updateFilteredRoutes() // Update routes immediately
            }
        } label: {
            VStack(spacing: 10) {
                // Icon with 3D effect
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isOn.wrappedValue ? .bold : .regular))
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
                    .shadow(color: isOn.wrappedValue ? color.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                    .scaleEffect(isOn.wrappedValue ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn.wrappedValue)

                // Counter with animation
                Text("\(count)")
                    .font(.system(size: 22, weight: isOn.wrappedValue ? .bold : .regular))
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
                    .contentTransition(.numericText(countsDown: false))
                    .shadow(color: isOn.wrappedValue ? color.opacity(0.3) : .clear, radius: 2, x: 0, y: 0)
                    .scaleEffect(isOn.wrappedValue ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isOn.wrappedValue)

                // Title with subtle animation
                Text(title)
                    .font(.system(size: 13, weight: isOn.wrappedValue ? .medium : .regular))
                    .foregroundColor(isOn.wrappedValue ? color.opacity(0.8) : Color.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isOn.wrappedValue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Glassmorphic base effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)

                    // Dynamic glow effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isOn.wrappedValue ? color.opacity(0.12) : color.opacity(0.02))
                        .blur(radius: 2)

                    // Highlight at the top (for 3D effect)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(isOn.wrappedValue ? 0.4 : 0.2),
                                    .white.opacity(0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(1)

                    // Border with glow
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(isOn.wrappedValue ? 0.5 : 0.1),
                                    color.opacity(isOn.wrappedValue ? 0.2 : 0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(
                color: isOn.wrappedValue ? color.opacity(0.15) : Color.black.opacity(0.08),
                radius: isOn.wrappedValue ? 5 : 2.5,
                x: 0,
                y: isOn.wrappedValue ? 4 : 2
            )
            .scaleEffect(isOn.wrappedValue ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn.wrappedValue)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(count) \(title)")
            .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
            .accessibilityHint("Double tap to toggle")
        }
        .buttonStyle(ScaleButtonStyle()) // Custom button style for press animation
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
                showWalkingRoutes
            case .running:
                showRunningRoutes
            case .cycling:
                showCyclingRoutes
            default:
                false
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

//
// #Preview {
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
// }
//
// #Preview {
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
// }

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

/// Add this custom button style for better press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
