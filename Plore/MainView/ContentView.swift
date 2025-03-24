//
//  ContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import MapKit
import PhotosUI
import SwiftUI

/// The main view displaying a Map and handling sheet presentations & navigation.
/// Ensures that `SampleView` reappears when returning to this screen.
struct ContentView: View {
    // MARK: Properties

    /// Controls when the SampleView sheet is shown.
    @State private var showExampleSheet = false

    /// Controls when the OpenAppView sheet is shown.
    @State private var showOpenAppSheet = false

    /// Controls navigation to the NoteView.
    @State private var navigateToNote = false

    @State private var navigateToPetal = false

    /// Tracks if ExampleSheet was dismissed when navigating away.
    @State private var wasExampleSheetDismissed = false

    /// Tracks if walking routes should be shown.
    @State private var showWalkingRoutes = true

    /// Tracks if running routes should be shown.
    @State private var showRunningRoutes = true

    /// Tracks if cycling routes should be shown
    @State private var showCyclingRoutes = true

    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager = HealthKitManager()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Map {
                    // 🟦 Walking Routes
                    if showWalkingRoutes {
                        ForEach(healthKitManager.walkingPolylines, id: \.self) { polyline in
                            MapPolyline(polyline)
                                .stroke(Color.blue, lineWidth: 3)
                        }
                    }

                    // 🟥 Running Routes
                    if showRunningRoutes {
                        ForEach(healthKitManager.runningPolylines, id: \.self) { polyline in
                            MapPolyline(polyline)
                                .stroke(Color.red, lineWidth: 3)
                        }
                    }

                    // 🟩 Cycling Routes
                    if showCyclingRoutes {
                        ForEach(healthKitManager.cyclingPolylines, id: \.self) { polyline in
                            MapPolyline(polyline)
                                .stroke(Color.green, lineWidth: 3)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)

                // Hidden navigation link for programmatic navigation.
                NavigationLink(
                    destination: Aqua(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }

                NavigationLink(
                    destination: PetalAssistantView(),
                    isActive: $navigateToPetal
                ) {
                    EmptyView()
                }
            }
            // Primary sheet – SampleView.
            .sheet(isPresented: $showExampleSheet) {
                SampleView(
                    healthKitManager: healthKitManager,
                    showWalkingRoutes: $showWalkingRoutes,
                    showRunningRoutes: $showRunningRoutes,
                    showCyclingRoutes: $showCyclingRoutes,
                    onOpenAppTap: {
                        // Dismiss SampleView and present OpenAppView.
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            showOpenAppSheet = true
                        }
                    },
                    onNoteTap: {
                        // Dismiss SampleView and navigate to NoteView.
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            navigateToNote = true
                        }
                    },
                    onPetalTap: {
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        Task { @MainActor in
                            navigateToPetal = true
                        }
                    }
                )
                .presentationDetents([
                    .custom(CompactDetent.self),
                    .medium,
                    .custom(OneSmallThanMaxDetent.self)
                ])
                .presentationCornerRadius(30)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
            }
            // Secondary sheet – OpenAppView.
            .sheet(isPresented: $showOpenAppSheet, onDismiss: {
                showExampleSheet = true
            }) {
                OpenAppView()
            }
            .onAppear {
                // Show ExampleSheet again if returning to this view.
                // CoreDataManager.shared.clearAllData()

                showExampleSheet = true
                Task(priority: .high) {
                    await healthKitManager.requestHKPermissions()
                }
                healthKitManager.loadRoutes()

                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Wait 5s for routes to load.
                    print("📍 Walking Routes: \(healthKitManager.walkingRoutes.count)")
                    print("📍 Running Routes: \(healthKitManager.runningRoutes.count)")
                    print("📍 Cycling Routes: \(healthKitManager.cyclingRoutes.count)")
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - SampleView (Main Bottom Sheet)

/// A bottom sheet view with tabs and improved UI using ClaudeButton components.
struct SampleView: View {
    // MARK: - Properties

    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600

    /// The search text.
    @State private var searchText: String = ""

    /// The currently selected tab.
    @State private var selectedTab: TabSection = .routes

    /// Indicates if sync is in progress
    @State private var isSyncing = false

    /// Last sync time
    @State private var lastSyncTime: Date? = nil

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager: HealthKitManager

    /// Bindings that toggle whether walking routes should be shown.
    @Binding var showWalkingRoutes: Bool

    /// Bindings that toggle whether running routes should be shown.
    @Binding var showRunningRoutes: Bool

    /// Bindings that toggle whether cycling routes should be shown.
    @Binding var showCyclingRoutes: Bool

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void

    let sampleData = ["Running Route", "Walking Route", "Cycling Route"] // Placeholder data

    /// Tab sections
    enum TabSection: String, CaseIterable {
        case routes = "Routes"
        case shortcuts = "Shortcuts"
        case explore = "Explore"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .routes: "map"
            case .shortcuts: "square.grid.2x2"
            case .explore: "safari"
            case .settings: "gear"
            }
        }
    }

    var filteredItems: [String] {
        searchText.isEmpty ? sampleData : sampleData.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchBarSection
            tabSelectorSection
            Divider()
            tabContentSection
        }
    }

    @ViewBuilder
    private var searchBarSection: some View {
        SearchBarView(searchText: $searchText)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(TabSection.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var tabContentSection: some View {
        TabView(selection: $selectedTab) {
            routesTabContent.tag(TabSection.routes)
            shortcutsTabContent.tag(TabSection.shortcuts)
            exploreTabContent.tag(TabSection.explore)
            settingsTabContent.tag(TabSection.settings)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func tabButton(for tab: TabSection) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))

                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == tab ? Color.blue : Color.gray)
            .padding(.vertical, 8)
        }
        .background(
            selectedTab == tab
                ? Color.blue.opacity(0.1)
                : Color.clear
        )
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
                            style: .glassy3D
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

            // Summary counts
            HStack(spacing: 20) {
                routeCountCard(count: healthKitManager.walkingRoutes.count, title: "Walking", color: .blue)
                routeCountCard(count: healthKitManager.runningRoutes.count, title: "Running", color: .red)
                routeCountCard(count: healthKitManager.cyclingRoutes.count, title: "Cycling", color: .green)
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
            // old cyberpunky style
            routeToggleButton(title: "Walking", isOn: $showWalkingRoutes, color: .blue)
            routeToggleButton(title: "Running", isOn: $showRunningRoutes, color: .red)
            routeToggleButton(title: "Cycling", isOn: $showCyclingRoutes, color: .green)
            
//            ClaudeButton(
//                "Walking",
//                color: ClaudeButtonColor.blue,
//                size: .small,
//                rounded: true,
//                icon: nil,
//                style: .modernAqua
//            ) {
//                $showWalkingRoutes.wrappedValue.toggle()
//            }
//            .opacity($showWalkingRoutes.wrappedValue ? 1.0 : 0.5)
//            
//            Spacer()
//            
//            ClaudeButton(
//                "Running",
//                color: ClaudeButtonColor.red,
//                size: .small,
//                rounded: true,
//                icon: nil,
//                style: .modernAqua
//            ) {
//                $showRunningRoutes.wrappedValue.toggle()
//            }
//            .opacity($showRunningRoutes.wrappedValue ? 1.0 : 0.5)
//            
//            Spacer()
//            
//            ClaudeButton(
//                "Cycling",
//                color: ClaudeButtonColor.green,
//                size: .small,
//                rounded: true,
//                icon: nil,
//                style: .modernAqua
//            ) {
//                $showCyclingRoutes.wrappedValue.toggle()
//            }
//            .opacity($showCyclingRoutes.wrappedValue ? 1.0 : 0.5)
            
        }
    }

    private var routeListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Routes")
                .font(.headline)

            if !filteredItems.isEmpty {
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
                    }
                }
            } else {
                Text("No routes found")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }

    // MARK: - Helper Views

    private func routeCountCard(count: Int, title: String, color: Color) -> some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func routeToggleButton(title: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(isOn.wrappedValue ? color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)

                Text(title)
                    .font(.caption)
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn.wrappedValue ? color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isOn.wrappedValue ? color.opacity(0.3) : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
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
                await MainActor.run {
                    // Load routes more efficiently
                    healthKitManager.loadRoutes()

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
}

// MARK: - Helper Components

/// A shortcut button with gradient background.
struct ShortcutCard: View {
    let title: String
    let icon: String
    let gradient: Gradient
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Spacer()

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding()
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
