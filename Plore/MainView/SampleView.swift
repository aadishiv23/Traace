//
//  SampleView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import Foundation
import SwiftUI
import HealthKit

// MARK: - SampleView (Main Bottom Sheet)

/// A bottom sheet view with tabs and improved UI using ClaudeButton components.
struct SampleView: View {
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

    /// Whether the Settings panel is showing.
    @State private var isShowingSettingsPanel = false

    /// Whether the search overlay is active (3D pop).
    @State private var isSearchBarActive = false

    /// Matched geometry namespace for the search bar transition.
    @Namespace private var searchBarNamespace

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager: HealthKitManager

    /// Bindings that toggle whether walking routes should be shown.
    @Binding var showWalkingRoutes: Bool

    /// Bindings that toggle whether running routes should be shown.
    @Binding var showRunningRoutes: Bool

    /// Bindings that toggle whether cycling routes should be shown.
    @Binding var showCyclingRoutes: Bool

    @Binding var selectedFilterDate: Date?

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void

    let onDateFilterChanged: (() -> Void)?

    let sampleData = ["Running Route", "Walking Route", "Cycling Route"] // Placeholder data

    @State private var filteredRoutes: [RouteInfo] = []
    @State private var isEditingRouteName: UUID? = nil
    @State private var editingName: String = ""

    /// Tab sections
    enum TabSection: String, CaseIterable {
        case routes = "Routes"
        // case shortcuts = "Shortcuts"
        //  case explore = "Explore"
        // case settings = "Settings"

        var icon: String {
            switch self {
            case .routes: "map"
                // case .shortcuts: "square.grid.2x2"
                // case .explore: "safari"
                // case .settings: "gear"
            }
        }
    }

    var filteredItems: [String] {
        searchText.isEmpty ? sampleData : sampleData.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 1) The main sheet content, blurred when the search overlay is active.
            mainContent
                .blur(radius: isSearchBarActive ? 20 : 0)

            // 2) Floating search bar
            if isSearchBarActive {
                searchOverlay
                    .zIndex(1)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.0).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }

            // 3) The settings overlay, if needed
            if isShowingSettingsPanel {
                settingsOverlay
                    .zIndex(2)
                    .transition(.move(edge: .trailing))
            }
        }
        // A single, more "bouncy" spring animation for both states:
        .animation(
            .interactiveSpring(
                response: 0.45, // how quickly the spring "responds"
                dampingFraction: 0.65, // how bouncy vs. damped
                blendDuration: 0.2
            ),
            value: isSearchBarActive || isShowingSettingsPanel
        )
    }

    // MARK: - Main Content (Sheet)

    /// The main content of the sheet, including a compact search bar, toggles, etc.
    private var mainContent: some View {
        VStack(spacing: 0) {
            // A "compact" search bar in the sheet.
            if !isSearchBarActive {
                compactSearchBar
                    .padding(.top, 15)
                    .padding(.bottom, 5)
            } else {
                Color.clear.frame(height: 0)
            }

            // Main tab content section
            tabContentSection
        }
    }

    /// A compact search bar that sits in the sheet. When tapped, it triggers the overlay.
    private var compactSearchBar: some View {
        HStack {
            SearchBarView(
                searchText: $searchText,
                selectedDate: $selectedDate, isInteractive: false
            )
            .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)
            .onChange(of: selectedFilterDate) { _, _ in
                onDateFilterChanged?()
            }
            .onTapGesture {
                withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.2)) {
                    isSearchBarActive = true
                }
            }

            // Gear button
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

    // MARK: Search Overlay

    /// A "floating" overlay that appears with a 3D pop, showing a fully interactive search bar + results.
    private var searchOverlay: some View {
        ZStack(alignment: .top) {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.2)) {
                        isSearchBarActive = false
                    }
                }

            // A floating card that holds the search bar + search results
            VStack(spacing: 0) {
                // The fully interactive search bar, matched geometry
                SearchBarView(
                    searchText: $searchText,
                    selectedDate: $selectedFilterDate,
                    isInteractive: true
                )
                .shadow(radius: 3, x: 0, y: 2)
                .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)
                .padding(.top, 20)
                .onChange(of: selectedFilterDate) { _ in
                    onDateFilterChanged?()
                }

                Divider()
                    .padding(.horizontal)
                    .padding(.top, 5)

                // The scrollable list of filtered items
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredItems, id: \.self) { item in
                            HStack {
                                Circle()
                                    .fill(colorForRoute(item))
                                    .frame(width: 12, height: 12)

                                Text(item)
                                    .font(.system(size: 16, weight: .medium))

                                Spacer()

                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .shadow(radius: 3, x: 0, y: 2)
                        }

                        if filteredItems.isEmpty {
                            Text("No routes found")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 5)
            // Slight 3D scale + rotation for the "pop" effect
            .scaleEffect(1.03)
            .rotation3DEffect(
                .degrees(4),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.7
            )
        }
    }

    private var settingsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        isShowingSettingsPanel = false
                    }
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

                    Toggle("Show Walking Routes", isOn: $showWalkingRoutes)
                    Toggle("Show Running Routes", isOn: $showRunningRoutes)
                    Toggle("Show Cycling Routes", isOn: $showCyclingRoutes)
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
        .background(.ultraThinMaterial)
        .transition(.move(edge: .trailing))
        .animation(.easeInOut(duration: 0.2), value: isShowingSettingsPanel)
        .zIndex(1)
    }

    /// The tab content section for the main views.
    private var tabContentSection: some View {
        VStack(spacing: 0) {
            // SECTION: Routes list
            routesTabContent
        }
        .padding(.top, 10)
    }

    // MARK: - Tab Contents

    /// Routes tab content
    private var routesTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sync status section
                syncStatusSection

                // Route toggles
                routeToggleSection

                // Route list
                routeListSection
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }

    /// Shortcuts tab content
    private var shortcutsTabContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Shortcuts Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ShortcutCard(
                        title: "Open App...",
                        icon: "square.dashed",
                        gradient: Gradient(colors: [.blue, .cyan]),
                        action: onOpenAppTap
                    )
                    ShortcutCard(
                        title: "Call Favorites",
                        icon: "phone.fill",
                        gradient: Gradient(colors: [.green, .mint]),
                        action: onPetalTap
                    )
                    ShortcutCard(
                        title: "Recently Played",
                        icon: "music.note",
                        gradient: Gradient(colors: [.red, .orange])
                    )
                    ShortcutCard(
                        title: "Set Timer",
                        icon: "timer",
                        gradient: Gradient(colors: [.yellow, .orange])
                    )
                    ShortcutCard(
                        title: "New Note",
                        icon: "note.text",
                        gradient: Gradient(colors: [.orange, .yellow]),
                        action: onNoteTap
                    )
                    ShortcutCard(
                        title: "Voice Memo",
                        icon: "waveform",
                        gradient: Gradient(colors: [.purple, .indigo])
                    )
                }
                .padding(.top, 8)

                // Quick actions section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.leading, 4)

                    VStack(spacing: 12) {
                        ForEach(
                            ["Check Weather", "Track Package", "Start Workout", "Find Transit"],
                            id: \.self
                        ) { action in
                            ClaudeButton(
                                action,
                                color: .gray,
                                size: .medium,
                                rounded: true,
                                icon: Image(systemName: iconForAction(action)),
                                style: .modernAqua
                            ) {}
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    /// Explore tab content
    private var exploreTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Nearby section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Explore Nearby")
                        .font(.headline)

                    // Cards for nearby locations
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(["Restaurant", "Coffee", "Park", "Shopping"], id: \.self) { category in
                                VStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(gradientForCategory(category))
                                        .frame(width: 150, height: 100)
                                        .overlay(
                                            Image(systemName: iconForCategory(category))
                                                .font(.system(size: 30))
                                                .foregroundColor(.white)
                                        )

                                    Text(category)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }

                // Recent locations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Locations")
                        .font(.headline)

                    VStack(spacing: 12) {
                        ForEach(["Home", "Work", "Gym", "Coffee Shop"], id: \.self) { location in
                            HStack {
                                Image(systemName: iconForLocation(location))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)

                                Text(location)
                                    .font(.system(size: 16, weight: .medium))

                                Spacer()

                                Text("Navigate")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }

    /// Settings tab content
    private var settingsTabContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sync frequency settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sync Settings")
                        .font(.headline)

                    VStack(spacing: 16) {
                        // Sync frequency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sync Frequency")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Picker("Sync Interval", selection: $selectedSyncInterval) {
                                Text("30 Minutes").tag(TimeInterval(30 * 60))
                                Text("1 Hour").tag(TimeInterval(60 * 60))
                                Text("2 Hours").tag(TimeInterval(120 * 60))
                                Text("4 Hours").tag(TimeInterval(240 * 60))
                            }
                            .pickerStyle(.segmented)
                        }

                        // Sync button using ClaudeButton
                        HStack {
                            ClaudeButton(
                                isSyncing ? "Syncing..." : "Sync Now",
                                color: .blue,
                                size: .medium,
                                rounded: true,
                                icon: Image(systemName: "arrow.triangle.2.circlepath"),
                                style: .modernAqua
                            ) {
                                performSync()
                            }
                            .disabled(isSyncing)
                            .opacity(isSyncing ? 0.7 : 1.0)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        // Last sync info
                        if let lastSync = lastSyncTime {
                            Text("Last synced: \(timeAgoString(from: lastSync))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }

                // Appearance settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.headline)

                    VStack(spacing: 16) {
                        Toggle("Show Walking Routes", isOn: $showWalkingRoutes)
                        Toggle("Show Running Routes", isOn: $showRunningRoutes)
                        Toggle("Show Cycling Routes", isOn: $showCyclingRoutes)
                        Toggle("Dark Mode", isOn: .constant(false))
                        Toggle("Show Distance", isOn: .constant(true))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }

                // About section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)

                    VStack(spacing: 16) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Text("Build")
                            Spacer()
                            Text("2025.03.23")
                                .foregroundColor(.gray)
                        }

                        ClaudeButton(
                            "Privacy Policy",
                            color: .gray,
                            size: .medium,
                            rounded: true,
                            icon: Image(systemName: "lock.shield"),
                            style: .modernAqua
                        ) {
                            // Action for privacy policy
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }

    // MARK: - Route Tab Subviews

    private var syncStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Data")
                    .font(.headline)
                Spacer()

                // Sync button using ClaudeButton
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

            // Summary counts with improved styling
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

            // Last sync info
            if let lastSync = lastSyncTime {
                Text("Last synced: \(timeAgoString(from: lastSync))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var routeToggleSection: some View {
        HStack(spacing: 12) {
            // Streamlined, more elegant toggle buttons
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
            
            // Routes list - Improved from original design
            if filteredRoutes.isEmpty {
                emptyRoutesView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRoutes) { route in
                        EnhancedRouteRow(
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
        .onChange(of: showWalkingRoutes) { _, _ in
            updateFilteredRoutes()
        }
        .onChange(of: showRunningRoutes) { _, _ in
            updateFilteredRoutes()
        }
        .onChange(of: showCyclingRoutes) { _, _ in
            updateFilteredRoutes()
        }
    }
    
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
            
            if selectedFilterDate != nil {
                Text("Try selecting a different date or adjusting your filters")
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

    // MARK: - RouteCountCard

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
                .animation(.spring(response: 0.25), value: count)

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
        // Simple, clean shadow
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        // Subtle scale animation on appearance
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                // Animation happens automatically
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(title)")
    }

    // MARK: - RouteToggleButton

    private func routeToggleButton(title: String, isOn: Binding<Bool>, color: Color, icon: String) -> some View {
        Button {
            // Haptic feedback when pressed
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            // Toggle with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.wrappedValue.toggle()
            }
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
            // Simple shadow for depth
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
            // Scale down slightly when pressed
            .scaleEffect(isOn.wrappedValue ? 1 : 0.97)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn.wrappedValue)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
    }

    // MARK: - Helper Functions

    private func performSync() {
        // Start the sync process
        isSyncing = true

        // Using Task to properly handle async operations
        Task {
            do {
                // Simulate network request with better performance
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

                // Use the main thread for UI updates
                Task { @MainActor in
                    // Load routes more efficiently
                    await healthKitManager.loadRoutes()

                    // Update state
                    lastSyncTime = Date()
                    isSyncing = false
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

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

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

    private func iconForAction(_ action: String) -> String {
        switch action {
        case "Check Weather": "cloud.sun"
        case "Track Package": "shippingbox"
        case "Start Workout": "figure.run"
        case "Find Transit": "bus"
        default: "star"
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Restaurant": "fork.knife"
        case "Coffee": "cup.and.saucer"
        case "Park": "leaf"
        case "Shopping": "bag"
        default: "mappin"
        }
    }

    private func gradientForCategory(_ category: String) -> LinearGradient {
        switch category {
        case "Restaurant":
            LinearGradient(
                gradient: Gradient(colors: [.orange, .red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Coffee":
            LinearGradient(
                gradient: Gradient(colors: [.brown, .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Park":
            LinearGradient(
                gradient: Gradient(colors: [.green, .mint]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Shopping":
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                gradient: Gradient(colors: [.blue, .teal]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func iconForLocation(_ location: String) -> String {
        switch location {
        case "Home": "house"
        case "Work": "briefcase"
        case "Gym": "dumbbell"
        case "Coffee Shop": "cup.and.saucer"
        default: "mappin"
        }
    }

    /// Updates the filtered routes based on selection criteria
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
    }
}

// MARK: - Filter Pill

/// A pill-style filter button for route types.
struct FilterPill: View {
    @Binding var isSelected: Bool
    let label: String
    let icon: String
    let color: Color
    var onToggle: (() -> Void)?
    
    var body: some View {
        Button {
            isSelected.toggle()
            onToggle?()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? color : .gray)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Route Row

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
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        default: return "mappin.and.ellipse"
        }
    }
    
    /// Returns the display name for a route type.
    private func routeTypeName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        default: return "Unknown"
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
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SampleView(
        healthKitManager: HealthKitManager(), // Replace with a mock if needed
        showWalkingRoutes: .constant(true),
        showRunningRoutes: .constant(true),
        showCyclingRoutes: .constant(true),
        selectedFilterDate: .constant(nil),
        onOpenAppTap: {},
        onNoteTap: {},
        onPetalTap: {},
        onDateFilterChanged: nil
    )
}

#Preview {
    SampleView(
        healthKitManager: HealthKitManager(), // Replace with a mock if needed
        showWalkingRoutes: .constant(true),
        showRunningRoutes: .constant(true),
        showCyclingRoutes: .constant(true),
        selectedFilterDate: .constant(nil),
        onOpenAppTap: {},
        onNoteTap: {},
        onPetalTap: {},
        onDateFilterChanged: nil
    )
    .preferredColorScheme(.dark)
}

import SwiftUI
import HealthKit
import MapKit

/// A beautifully designed row displaying a route's information with editable name.
struct EnhancedRouteRow: View {
    // MARK: - Properties
    let route: RouteInfo
    let isEditing: Bool
    @Binding var editingName: String
    let onEditComplete: () -> Void
    let onEditStart: () -> Void
    
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
                routePreviewMap
                    .frame(height: 150)
                    .cornerRadius(12)
                    .padding(.top, 8)
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
                
                // Distance or other metrics could go here
                // This is a placeholder for future implementation
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("2.3 mi")
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
}

// MARK: - Preview
#Preview {
    let locations = [
        CLLocation(latitude: 37.7749, longitude: -122.4194),
        CLLocation(latitude: 37.7750, longitude: -122.4195),
        CLLocation(latitude: 37.7751, longitude: -122.4196)
    ]
    
    let routeInfo = RouteInfo(
        name: "Morning Run",
        type: .running,
        date: Date(),
        locations: locations
    )
    
    return VStack {
        EnhancedRouteRow(
            route: routeInfo,
            isEditing: false,
            editingName: .constant(""),
            onEditComplete: {},
            onEditStart: {}
        )
        
        EnhancedRouteRow(
            route: RouteInfo(
                name: "Evening Walk",
                type: .walking,
                date: Date().addingTimeInterval(-3600 * 5),
                locations: locations
            ),
            isEditing: false,
            editingName: .constant(""),
            onEditComplete: {},
            onEditStart: {}
        )
        
        EnhancedRouteRow(
            route: RouteInfo(
                name: "Weekend Bike Ride",
                type: .cycling,
                date: Date().addingTimeInterval(-3600 * 24),
                locations: locations
            ),
            isEditing: false,
            editingName: .constant(""),
            onEditComplete: {},
            onEditStart: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
