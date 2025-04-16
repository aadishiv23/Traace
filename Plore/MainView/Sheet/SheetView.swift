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

    /// Show first-time user tips
    @State private var showFirstTimeTips = false

    /// Whether to show the loading bar in the sheet.
    @State private var showLoadingProgress: Bool = false

    // Whether the Settings panel is showing.
    // @State private var isShowingSettingsPanel = false

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

    /// Binding to hasCompletedOnboarding from ContentView
    @Binding var hasCompletedOnboarding: Bool

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void
    let showRouteDetailView: () -> Void

    let onRouteSelected: (RouteInfo) -> Void
    let onDateFilterChanged: (() -> Void)?

    @State private var filteredRoutes: [RouteInfo] = []
    @State private var isEditingRouteName: UUID? = nil
    @State private var editingName: String = ""
    
    @State private var loadingRotation: Double = 0


    @AppStorage("hasSeenTips") private var hasSeenTips: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top search bar
            searchBarHeader
                .padding(.top, 15)
                .padding(.bottom, 5)

            // MARK: Loading progress bar + counter

            if showLoadingProgress {
                loadingProgressView
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
            updateFilteredRoutes()
            performSync()
            if hasCompletedOnboarding, !hasSeenTips {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showFirstTimeTips = true
                    hasSeenTips = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                updateFilteredRoutes()
            }
        }
        // Listen to loading state so we can show/hide the bar.
        .onReceive(healthKitManager.$isLoadingRoutes) { isLoading in
            if isLoading {
                withAnimation(.spring(response: 0.3)) {
                    showLoadingProgress = true
                }
            } else {
                // Give user time to see completion state before hiding
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLoadingProgress = false
                    }
                }
            }
        }
    }

    // MARK: - Search Bar Header

    /// The search bar header at the top of the view.
    private var searchBarHeader: some View {
        HStack {
            // Search bar that stays in place
            MinimalSearchBarView(
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
        }
        .padding(.horizontal)
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

                // First-time tips (conditionally shown)
                if showFirstTimeTips, filteredRoutes.isEmpty {
                    firstTimeTipsSection
                }

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
    }

    // MARK: - First-Time Tips Section

    /// Tips section shown to first-time users
    private var firstTimeTipsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tips for Getting Started")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        showFirstTimeTips = false
                    }
                    updateFilteredRoutes()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "figure.walk", text: "Toggle route types using the filter buttons")
                tipRow(icon: "arrow.triangle.2.circlepath", text: "Sync with HealthKit to see your workout routes")
                tipRow(icon: "calendar", text: "Filter routes by name or date using the search bar")
                tipRow(icon: "hand.tap", text: "Tap on a route to see it on the map")
                tipRow(icon: "arrow.clockwise", text: "Tap route toggles to refresh the UI")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .padding(.vertical, 8)
        .transition(.opacity)
    }

    /// Individual tip row
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 24, height: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    // MARK: - Route Tab Subviews

    /// The sync status section showing route counts and sync button.
    private var syncStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Toggles")
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
                color: ActivityColors.color(for: .running, style: .standard),
                icon: "figure.run",
                isOn: $showRunningRoutes
            )
            routeCountCard(
                count: healthKitManager.cyclingRoutes.count,
                title: "Cycling",
                color: ActivityColors.color(for: .cycling, style: .standard),
                icon: "figure.outdoor.cycle",
                isOn: $showCyclingRoutes
            )
            routeCountCard(
                count: healthKitManager.walkingRoutes.count,
                title: "Walking",
                color: ActivityColors.color(for: .walking, style: .standard),
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
                // Icon with more subtle effect
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isOn.wrappedValue ? .bold : .regular))
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
                    .shadow(
                        color: isOn.wrappedValue ? color.opacity(0.3) : .clear,
                        radius: 2,
                        x: 0,
                        y: 0
                    ) // Reduced shadow
                    .scaleEffect(isOn.wrappedValue ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn.wrappedValue)

                // Counter with animation
                Text("\(count)")
                    .font(.system(size: 22, weight: isOn.wrappedValue ? .bold : .regular))
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
                    .contentTransition(.numericText(countsDown: false))
                    .shadow(
                        color: isOn.wrappedValue ? color.opacity(0.2) : .clear,
                        radius: 1,
                        x: 0,
                        y: 0
                    ) // Reduced shadow
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

                    // More subtle glow effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isOn.wrappedValue ? color.opacity(0.08) : color.opacity(0.01)) // Reduced opacity
                        .blur(radius: 1) // Reduced blur

                    // Subtle highlight at the top (for 3D effect)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(isOn.wrappedValue ? 0.25 : 0.15), // Reduced opacity
                                    .white.opacity(0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(1)

                    // Lighter border with reduced glow
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(isOn.wrappedValue ? 0.3 : 0.08), // Reduced opacity
                                    color.opacity(isOn.wrappedValue ? 0.1 : 0.03) // Reduced opacity
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1 // Thinner border
                        )
                }
            )
            .shadow(
                color: isOn.wrappedValue ? color.opacity(0.1) : Color.black.opacity(0.06), // Reduced shadow
                radius: isOn.wrappedValue ? 3 : 2, // Reduced radius
                x: 0,
                y: isOn.wrappedValue ? 2 : 1 // Reduced offset
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

    // MARK: - Loading Progress UI Component

    /// Improved loading progress UI component with animation, better visual feedback,
    /// and a more polished appearance
    private var loadingProgressView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with loading status and count
            HStack {
                HStack(spacing: 4) {
                    // Animated loading indicator
                    if healthKitManager.isLoadingRoutes {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 14, height: 14)
                            .rotationEffect(Angle(degrees: loadingRotation))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    loadingRotation = 360
                                }
                            }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                    }

                    Text(healthKitManager.isLoadingRoutes ? "Loading routes..." : "Routes loaded")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(healthKitManager.isLoadingRoutes ? .primary : .green)
                        .animation(.easeInOut, value: healthKitManager.isLoadingRoutes)
                }

                Spacer()

                // Loading count with animated transition
                Text("\(healthKitManager.loadedRouteCount) of \(healthKitManager.totalRouteCount)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.easeInOut, value: healthKitManager.loadedRouteCount)
            }

            // Progress bar with gradient and animated fill
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)

                // Filled portion with gradient
                let progress = min(
                    CGFloat(healthKitManager.loadedRouteCount) /
                        max(CGFloat(healthKitManager.totalRouteCount), 1),
                    1.0
                )

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(progress * UIScreen.main.bounds.width - 40, 0), height: 6)
                    .animation(.spring(response: 0.4), value: progress)
            }

            // Optional status message
            if healthKitManager.isLoadingRoutes {
                Text("Retrieving your workout location data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            )
        )
        .onAppear {
            // Reset rotation when view appears
            loadingRotation = 0
        }
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
        print("🔄 [SheetView] Starting manual sync...") // Add log

        healthKitManager.syncData()

        // Using Task to properly handle async operations
        Task {
            do {
                // *** THE KEY CHANGE: Call syncData instead of loadRoutes ***

                // The Task.sleep was likely just for simulation, can be removed
                // try await Task.sleep(nanoseconds: 1_000_000_000)

                // Use await MainActor.run for clarity and safety
                await MainActor.run {
                    // Update state
                    lastSyncTime = Date() // Update last sync time display
                    isSyncing = false
                    print("✅ [SheetView] Manual sync complete. Refreshing filtered routes.") // Add log

                    // Update filtered routes AFTER syncData has finished and potentially
                    // updated the HealthKitManager's published properties
                    updateFilteredRoutes()

                    // Hide first-time tips after successful sync
                    if showFirstTimeTips {
                        withAnimation {
                            showFirstTimeTips = false
                        }
                    }
                }
            } catch {
                // Handle any errors from syncData
                print("❌ [SheetView] Sync error: \(error)")
                await MainActor.run {
                    isSyncing = false
                    // Optionally show an error alert to the user
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

import SwiftUI

/// A custom button style that scales the button slightly when pressed
/// for a satisfying tactile feel.
struct ScaleButtonStyle: ButtonStyle {
    /// The amount to scale down when pressed (default is 0.96)
    var scaleFactor: CGFloat = 0.96

    /// The animation duration for the press effect (default is 0.2 seconds)
    var duration: Double = 0.2

    /// The animation damping for the press effect (default is 0.7)
    var dampingFraction: Double = 0.7

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleFactor : 1)
            .animation(.spring(response: duration, dampingFraction: dampingFraction), value: configuration.isPressed)
    }
}

// MARK: - Usage Examples

extension ScaleButtonStyle {
    /// A subtle scale effect
    static var subtle: ScaleButtonStyle {
        ScaleButtonStyle(scaleFactor: 0.98, duration: 0.15, dampingFraction: 0.8)
    }

    /// A more pronounced scale effect
    static var pronounced: ScaleButtonStyle {
        ScaleButtonStyle(scaleFactor: 0.92, duration: 0.25, dampingFraction: 0.6)
    }
}

// MARK: - View Extension

extension View {
    /// Apply the scale button style with custom parameters
    /// - Parameters:
    ///   - scaleFactor: The amount to scale down when pressed
    ///   - duration: The animation duration for the press effect
    ///   - dampingFraction: The animation damping for the press effect
    /// - Returns: A view with the scale button style applied
    func scaleButtonStyle(
        scaleFactor: CGFloat = 0.96,
        duration: Double = 0.2,
        dampingFraction: Double = 0.7
    ) -> some View {
        buttonStyle(ScaleButtonStyle(
            scaleFactor: scaleFactor,
            duration: duration,
            dampingFraction: dampingFraction
        ))
    }
}
