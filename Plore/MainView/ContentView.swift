//
//  ContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import HealthKit
import MapKit
import PhotosUI
import SwiftUI

/// The main view displaying a Map and handling sheet presentations & navigation.
struct ContentView: View {
    // MARK: Properties

    /// Route color theme in use (persisted)
    @AppStorage("routeColorTheme") private var routeColorThemeRaw: String = RouteColorTheme.vibrant.rawValue

    private var routeColorTheme: RouteColorTheme {
        get { RouteColorTheme(rawValue: routeColorThemeRaw) ?? .vibrant }
        set { routeColorThemeRaw = newValue.rawValue }
    }

    private var routeColorThemeBinding: Binding<RouteColorTheme> {
        Binding<RouteColorTheme>(
            get: { RouteColorTheme(rawValue: routeColorThemeRaw) ?? .vibrant },
            set: { routeColorThemeRaw = $0.rawValue }
        )
    }

    private var currentRouteColors: (walking: Color, running: Color, cycling: Color) {
        RouteColors.colors(for: routeColorTheme)
    }

    /// Controls when the SampleView sheet is shown.
    @State private var showExampleSheet = false

    /// Controls when the OpenAppView sheet is shown.
    @State private var showOpenAppSheet = false

    /// Controls navigation to the NoteView.
    @State private var navigateToNote = false

    @State private var navigateToPetal = false

    /// Controls navigation to the theme settings.
    @State private var showSettingsView = false

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

    @State private var filteredWalkingPolylines: [MKPolyline] = []
    @State private var filteredRunningPolylines: [MKPolyline] = []
    @State private var filteredCyclingPolylines: [MKPolyline] = []
    @State private var selectedFilterDate: Date? = nil

    /// The currently focused route
    @State private var focusedRoute: RouteInfo? = nil

    /// Controls when the RouteDetailView is shown.
    @State private var showRouteDetailView = false

    @State private var routeDetailDismissed = false

    /// MapCamera position state
    @State private var mapPosition: MapCameraPosition = .automatic

    /// Show loading popup for first-time users
    @State private var showInitialLoadingPopup = false

    /// Binding to hasCompletedOnboarding from PloreApp
    @Binding var hasCompletedOnboarding: Bool

    @AppStorage("hasSeenLoadingPopup") private var hasSeenLoadingPopup: Bool = false

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager = HealthKitManager()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                mapOverlay

                controlButtons

                // Focused route info panel
                if let route = focusedRoute {
                    focusedRoutePanel(route)
                }

                // Hidden navigation links for programmatic navigation.
                NavigationLink(
                    destination: Aqua(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }

                NavigationLink(
                    destination: RouteDetailView(route: focusedRoute ?? RouteInfo(
                        name: "",
                        type: .walking,
                        date: Date(),
                        locations: []
                    ))
                    .onDisappear {
                        DispatchQueue.main.async {
                            routeDetailDismissed = true
                            showExampleSheet = true
                        }
                    },
                    isActive: $showRouteDetailView
                ) {
                    EmptyView()
                }

                // Settings navigation link
                NavigationLink(
                    destination: RouteThemeSettingsView(selectedTheme: routeColorThemeBinding),
                    isActive: $showSettingsView
                ) {
                    EmptyView()
                }

                // First-time user loading popup
                if showInitialLoadingPopup {
                    initialLoadingPopup
                }
            }
            // Primary sheet – SampleView.
            .sheet(isPresented: $showExampleSheet) {
                sampleSheetContent
            }
            // Inject the route color theme into the environment for all child views
            .environment(\.routeColorTheme, routeColorTheme)
            // Secondary sheet – OpenAppView.
            .sheet(isPresented: $showOpenAppSheet, onDismiss: {
                showExampleSheet = true
            }) {
                OpenAppView()
            }
            .task {
                await initializeView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: focusedRoute) { _, newRoute in
                if let route = newRoute {
                    let rect = route.polyline.boundingMapRect
                    let padding = rect.size.width * 0.2
                    let paddedRect = MKMapRect(
                        x: rect.origin.x - padding,
                        y: rect.origin.y - padding,
                        width: rect.size.width + (padding * 2),
                        height: rect.size.height + (padding * 2)
                    )
                    mapPosition = .rect(paddedRect)
                } else {
                    mapPosition = .automatic
                }
            }
            .onChange(of: routeDetailDismissed) { _, dismissed in
                if dismissed {
                    routeDetailDismissed = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showExampleSheet = true
                    }
                }
            }
        }
    }

    // MARK: - Initial Loading Popup

    private var initialLoadingPopup: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Close popup when tapping outside
                    withAnimation(.easeOut(duration: 0.3)) {
                        showInitialLoadingPopup = false
                    }
                }

            // Popup content
            VStack(spacing: 20) {
                // Progress indicator and title
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Getting Your Routes")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("We're loading your workout routes from HealthKit. This may take a moment.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Tips
                VStack(alignment: .leading, spacing: 14) {
                    routeTip(icon: "arrow.triangle.2.circlepath", text: "Press the Sync button to refresh your routes")
                    routeTip(icon: "figure.walk", text: "Toggle route types using the route toggles on the sheet")
                    routeTip(icon: "magnifyingglass", text: "Use the search bar to find specific routes")
                }
                .padding(.vertical, 10)

                // Dismiss button
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showInitialLoadingPopup = false
                    }
                } label: {
                    Text("Got it")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 30)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    private func routeTip(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: Subviews

    /// Map overlay.
    private var mapOverlay: some View {
        Map(position: $mapPosition) {
            // If there's a focused route, show only that one
            if let route = focusedRoute {
                MapPolyline(route.polyline)
                    .stroke(routeTypeColor(for: route.type), lineWidth: 4)

                // Start marker
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

                // End marker
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
            // Otherwise show all filtered routes
            else {
                if showWalkingRoutes {
                    ForEach(filteredWalkingPolylines, id: \.self) {
                        MapPolyline($0).stroke(currentRouteColors.walking, lineWidth: 3)
                    }
                }
                if showRunningRoutes {
                    ForEach(filteredRunningPolylines, id: \.self) {
                        MapPolyline($0).stroke(currentRouteColors.running, lineWidth: 3)
                    }
                }
                if showCyclingRoutes {
                    ForEach(filteredCyclingPolylines, id: \.self) {
                        MapPolyline($0).stroke(currentRouteColors.cycling, lineWidth: 3)
                    }
                }
            }
        }
        .mapControls {}
        .edgesIgnoringSafeArea(.all)
    }

    /// Focused route info panel
    private func focusedRoutePanel(_ route: RouteInfo) -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(route.name ?? "Selected Route")
                        .font(.headline)
                        .lineLimit(1)

                    HStack {
                        Image(systemName: routeTypeIcon(for: route.type))
                            .font(.system(size: 12))
                            .foregroundColor(routeTypeColor(for: route.type))

                        Text(formattedDate(route.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    showExampleSheet = false
                    showRouteDetailView = true
                } label: {
                    Text("View Details")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(routeTypeColor(for: route.type).opacity(0.2))
                        .foregroundColor(routeTypeColor(for: route.type))
                        .clipShape(Capsule())
                }

                Button {
                    withAnimation {
                        focusedRoute = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
    }

    /// Control button overlay.
    /// Control button overlay.
    private var controlButtons: some View {
        VStack {
            Spacer()

            // Group the toggles + settings into a tiny VStack
            VStack(spacing: 8) {
                // 1) The three route toggles
                HStack {
                    VStack(spacing: 0) {
                        let colors = RouteColors.colors(for: routeColorTheme)
                        routeToggleButton(icon: "figure.run", isOn: $showRunningRoutes, color: colors.running)
                        Divider().frame(width: 44).background(Color.gray.opacity(0.6))
                        routeToggleButton(icon: "figure.outdoor.cycle", isOn: $showCyclingRoutes, color: colors.cycling)
                        Divider().frame(width: 44).background(Color.gray.opacity(0.6))
                        routeToggleButton(icon: "figure.walk", isOn: $showWalkingRoutes, color: colors.walking)
                    }
                    .frame(width: 50)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 5)
                    .padding(.leading, 10)

                    Spacer()
                }

                // 2) The settings button, right below the walk toggle
                HStack {
                    Button {
                        // Dismiss the sheet first
                        showExampleSheet = false
                        // Then navigate
                        showSettingsView = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.accentColor)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(radius: 5)
                    .padding(.leading, 10)

                    Spacer()
                }
            }
            // Push the whole stack up a bit from the bottom
            .padding(.bottom, 400)
        }
    }

    @ViewBuilder
    private func routeToggleButton(icon: String, isOn: Binding<Bool>, color: Color) -> some View {
        let isActive = isOn.wrappedValue

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isOn.wrappedValue.toggle()
                updateFilteredRoutes() // Update filtered routes immediately
            }
        } label: {
            if #available(iOS 18.0, *) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isActive ? color : .gray)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .symbolEffect(.bounce, value: isActive)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isActive ? color : .gray)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isActive ? 1.1 : 1.0)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: Vars

    @ViewBuilder
    private var sampleSheetContent: some View {
        SheetView(
            healthKitManager: healthKitManager,
            showWalkingRoutes: $showWalkingRoutes,
            showRunningRoutes: $showRunningRoutes,
            showCyclingRoutes: $showCyclingRoutes,
            selectedFilterDate: $selectedFilterDate,
            focusedRoute: $focusedRoute,
            hasCompletedOnboarding: $hasCompletedOnboarding,
            onOpenAppTap: {
                updateFilteredRoutes()
            },
            onNoteTap: {
                showExampleSheet = false
                wasExampleSheetDismissed = true
                DispatchQueue.main.async {
                    showOpenAppSheet = true
                }
            },
            onPetalTap: {
                showExampleSheet = false
                wasExampleSheetDismissed = true
                DispatchQueue.main.async {
                    navigateToNote = true
                }
            },
            showRouteDetailView: {
                showExampleSheet = false
                wasExampleSheetDismissed = true
            },
            onRouteSelected: { route in
                // Focus on the selected route
                focusedRoute = route

                // Dismiss the sheet to show the map fully
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                //                    showExampleSheet = false
                //                }
            },
            onDateFilterChanged: {
                updateFilteredRoutes()
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

    // MARK: Functions

    func updateFilteredRoutes() {
        let filtered = healthKitManager.filterRoutesByDate(date: selectedFilterDate)
        filteredWalkingPolylines = filtered.walking
        filteredRunningPolylines = filtered.running
        filteredCyclingPolylines = filtered.cycling
    }

    private func initializeView() async {
        // Check if this is the first time after completing onboarding
        if hasCompletedOnboarding, !hasSeenLoadingPopup {
            withAnimation(.easeIn(duration: 0.3)) {
                showInitialLoadingPopup = true
            }

            // Mark as seen
            hasSeenLoadingPopup = true

            // Auto-dismiss after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showInitialLoadingPopup = false
                }
            }
        }

        showExampleSheet = true

        Task(priority: .high) {
            await healthKitManager.requestHKPermissions()
        }

        await healthKitManager.loadRoutes()

        // Determine the most recent route and set map position
        let allRoutes = healthKitManager.walkingRouteInfos + healthKitManager.runningRouteInfos + healthKitManager
            .cyclingRouteInfos
        if let mostRecentRoute = allRoutes.sorted(by: { $0.date > $1.date }).first {
            let routeRect = mostRecentRoute.polyline.boundingMapRect
            let oneMileInMapPoints = 1609.34 *
                MKMapPointsPerMeterAtLatitude(mostRecentRoute.polyline.coordinate.latitude) // Approximate
            let expandedRect = routeRect
                .insetBy(dx: -oneMileInMapPoints, dy: -oneMileInMapPoints) // Negative inset expands
            mapPosition = .rect(expandedRect)
        } else {
            mapPosition = .automatic
        }

        filteredWalkingPolylines = healthKitManager.walkingPolylines
        filteredRunningPolylines = healthKitManager.runningPolylines
        filteredCyclingPolylines = healthKitManager.cyclingPolylines

        // Update routes with a short delay to ensure they display properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("📍 Walking Routes: \(healthKitManager.walkingRoutes.count)")
            print("📍 Running Routes: \(healthKitManager.runningRoutes.count)")
            print("📍 Cycling Routes: \(healthKitManager.cyclingRoutes.count)")
            updateFilteredRoutes()
        }
    }

    // MARK: - Helper Functions

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
        case .walking: "Walking Route"
        case .running: "Running Route"
        case .cycling: "Cycling Route"
        default: "Unknown Route"
        }
    }

    /// Returns the color for a route type.
    private func routeTypeColor(for type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking: currentRouteColors.walking
        case .running: currentRouteColors.running
        case .cycling: currentRouteColors.cycling
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

// MARK: - Helper Components

// MARK: - Preview

#Preview {
    ContentView(hasCompletedOnboarding: .constant(true))
}
