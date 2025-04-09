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

// The main view displaying a Map and handling sheet presentations & navigation.
// Ensures that `SampleView` reappears when returning to this screen.
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

                // Hidden navigation link for programmatic navigation.
                NavigationLink(
                    destination: Aqua(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }

                // In ContentView, replace your NavigationLink with:
                NavigationLink(
                    destination: RouteDetailView(route: focusedRoute ?? RouteInfo(
                        name: "",
                        type: .walking,
                        date: Date(),
                        locations: []
                    ))
                    .onDisappear {
                        // When RouteDetailView disappears
                        DispatchQueue.main.async {
                            // Show the sample sheet again
                            routeDetailDismissed = true
                            showExampleSheet = true
                            // Clear focused route (optional, depending on your UX preference)
                            // focusedRoute = nil
                        }
                    },
                    isActive: $showRouteDetailView
                ) {
                    EmptyView()
                }
            }
            // Primary sheet – SampleView.
            .sheet(isPresented: $showExampleSheet) {
                sampleSheetContent
            }

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
                // When the focused route changes, update the map camera
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
                    // Reset the flag
                    routeDetailDismissed = false

                    // Show the sample sheet again with a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showExampleSheet = true
                    }
                }
            }
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
                        MapPolyline($0).stroke(Color.blue, lineWidth: 3)
                    }
                }
                if showRunningRoutes {
                    ForEach(filteredRunningPolylines, id: \.self) {
                        MapPolyline($0).stroke(Color.red, lineWidth: 3)
                    }
                }
                if showCyclingRoutes {
                    ForEach(filteredCyclingPolylines, id: \.self) {
                        MapPolyline($0).stroke(Color.green, lineWidth: 3)
                    }
                }
            }
        }
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
    private var controlButtons: some View {
        VStack {
            Spacer()
            HStack {
                VStack(spacing: 0) {
                    routeToggleButton(icon: "figure.run", isOn: $showRunningRoutes, color: .red)
                    Divider().frame(width: 44).background(Color.gray.opacity(0.6))
                    routeToggleButton(icon: "figure.outdoor.cycle", isOn: $showCyclingRoutes, color: .green)
                    Divider().frame(width: 44).background(Color.gray.opacity(0.6))
                    routeToggleButton(icon: "figure.walk", isOn: $showWalkingRoutes, color: .blue)
                }
                .frame(width: 50)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.leading, 10)
                .padding(.bottom, 360)
                .shadow(radius: 5)

                Spacer()
            }

            Spacer()
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
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isActive ? color : .gray)
                .frame(width: 44, height: 44)
                .scaleEffect(isActive ? 1.1 : 1.0)
                .symbolEffect(.wiggle, value: isActive)
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
        showExampleSheet = true

        Task(priority: .high) {
            await healthKitManager.requestHKPermissions()
        }

        await healthKitManager.loadRoutes()

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

// MARK: - Helper Components

// MARK: - Preview

#Preview {
    ContentView()
}
