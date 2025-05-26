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

    @ObservedObject var viewModel: SheetViewModel

    @Environment(\.routeColorTheme) private var routeColorTheme

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void
    let showRouteDetailView: () -> Void

    let onRouteSelected: (RouteInfo) -> Void
    let onDateFilterChanged: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top search bar
            searchBarHeader
                .padding(.top, 15)
                .padding(.bottom, 5)

            // MARK: Loading progress bar + counter

            // Main tab content
            tabContentSection
        }
        .sheet(isPresented: $viewModel.showRouteDetailSheet) {
            if let route = viewModel.selectedRoute {
                RouteDetailView(route: route)
            }
        }
        .onAppear {
            viewModel.updateFilteredRoutes()
            viewModel.performSync()
            if viewModel.hasCompletedOnboarding, !viewModel.hasSeenTips {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.showFirstTimeTips = true
                    viewModel.hasSeenTips = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                viewModel.updateFilteredRoutes()
            }
        }
    }

    // MARK: - Search Bar Header

    /// The search bar header at the top of the view.
    private var searchBarHeader: some View {
        HStack {
            // Search bar that stays in place
            MinimalSearchBarView(
                searchText: $viewModel.searchText,
                selectedDate: $viewModel.selectedDate,
                isInteractive: $viewModel.isSearchActive,
                onFilterChanged: {
                    viewModel.updateFilteredRoutes()
                }
            )
            .onTapGesture {
                if !viewModel.isSearchActive {
                    viewModel.isSearchActive = true
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
                if viewModel.showFirstTimeTips, viewModel.filteredRoutes.isEmpty {
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
                        viewModel.showFirstTimeTips = false
                    }
                    viewModel.updateFilteredRoutes()
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

                if viewModel.showLoadingProgress {
                    withAnimation {
                        HStack(spacing: 8) {
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.blue, lineWidth: 1.5)
                                .frame(width: 16, height: 16)
                                .rotationEffect(Angle(degrees: viewModel.loadingRotation))
                                .onAppear {
                                    if viewModel.showLoadingProgress, viewModel.loadingRotation == 0 {
                                        withAnimation(
                                            Animation.linear(duration: 1)
                                                .repeatForever(autoreverses: false)
                                        ) {
                                            viewModel.loadingRotation = 360
                                        }
                                    }
                                }
                            Text(
                                "Syncing \(viewModel.healthKitManager.loadedRouteCount)/\(viewModel.healthKitManager.totalRouteCount)..."
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.easeInOut, value: viewModel.healthKitManager.loadedRouteCount)
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    }
                } else {
                    ClaudeButton(
                        "Sync",
                        color: .blue,
                        size: .small,
                        rounded: true,
                        icon: Image(systemName: "arrow.triangle.2.circlepath"),
                        style: .modernAqua
                    ) {
                        viewModel.performSync()
                    }
                    .disabled(viewModel.isSyncing)
                    .opacity(viewModel.isSyncing ? 0.7 : 1.0)
                }
            }

            // Show focused route indicator or route counts
            if viewModel.focusedRoute != nil {
                focusedRouteIndicator
            } else {
                routeCountsCards
            }

            // Last sync info
            if let lastSync = viewModel.lastSyncTime {
                Text("Last synced: \(viewModel.timeAgoString(from: lastSync))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    /// Focused route indicator when a specific route is selected.
    private var focusedRouteIndicator: some View {
        HStack {
            Text("Showing \(viewModel.focusedRoute?.name ?? "Selected Route") on map")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                viewModel.focusedRoute = nil
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
        let themeColors = RouteColors.colors(for: routeColorTheme)

        return HStack(spacing: 20) {
            routeCountCard(
                count: viewModel.healthKitManager.runningRoutes.count,
                title: "Running",
                color: themeColors.running,
                icon: "figure.run",
                isOn: $viewModel.showRunningRoutes
            )
            routeCountCard(
                count: viewModel.healthKitManager.cyclingRoutes.count,
                title: "Cycling",
                color: themeColors.cycling,
                icon: "figure.outdoor.cycle",
                isOn: $viewModel.showCyclingRoutes
            )
            routeCountCard(
                count: viewModel.healthKitManager.walkingRoutes.count,
                title: "Walking",
                color: themeColors.walking,
                icon: "figure.walk",
                isOn: $viewModel.showWalkingRoutes
            )
        }
    }

    /// Quick toggle buttons for route types.
    private var routeToggleSection: some View {
        let themeColors = RouteColors.colors(for: routeColorTheme)
        return HStack(spacing: 12) {
            // Streamlined, elegant toggle buttons
            routeToggleButton(
                title: "Running",
                isOn: $viewModel.showRunningRoutes,
                color: themeColors.running,
                icon: "figure.run"
            )
            routeToggleButton(
                title: "Cycling",
                isOn: $viewModel.showCyclingRoutes,
                color: themeColors.cycling,
                icon: "figure.outdoor.cycle"
            )
            routeToggleButton(
                title: "Walking",
                isOn: $viewModel.showWalkingRoutes,
                color: themeColors.walking,
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

                Text("\(viewModel.filteredRoutes.count) routes")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .contentTransition(.numericText(countsDown: false))
            }

            // Routes list or empty state
            if viewModel.filteredRoutes.isEmpty {
                emptyRoutesView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredRoutes) { route in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            CollapsibleRouteRow(
                                route: route,
                                isEditing: viewModel.isEditingRouteName == route.id,
                                editingName: $viewModel.editingName,
                                onEditComplete: {
                                    if !viewModel.editingName.isEmpty {
                                        viewModel.healthKitManager.updateRouteName(id: route.id, newName: viewModel.editingName)
                                    }
                                    viewModel.isEditingRouteName = nil
                                },
                                onEditStart: {
                                    viewModel.editingName = route.name ?? ""
                                    viewModel.isEditingRouteName = route.id
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
            viewModel.updateFilteredRoutes()
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.updateFilteredRoutes()
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

            if viewModel.selectedDate != nil || !viewModel.searchText.isEmpty {
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
                viewModel.updateFilteredRoutes() // Update routes immediately
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
                                    .white.opacity(0),
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
                                    color.opacity(isOn.wrappedValue ? 0.1 : 0.03), // Reduced opacity
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
            viewModel.updateFilteredRoutes() // Update routes immediately
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
        if viewModel.showPreview {
            viewModel.selectedRoute = route
            viewModel.showRouteDetailSheet = true
        } else {
            // Option 2: Focus on the route in the main map
            viewModel.focusedRoute = route
            onRouteSelected(route)
        }
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

    // Filtering handled in ViewModel, so updateFilteredRoutes is not needed here.
}
