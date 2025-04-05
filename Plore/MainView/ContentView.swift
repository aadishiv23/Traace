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

    // ViewModels
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var routeListViewModel = RouteListViewModel()

    /// Controls when the RouteListView sheet is shown.
    @State private var showRouteListSheet = false

    /// Controls when the OpenAppView sheet is shown.
    @State private var showOpenAppSheet = false

    /// Controls navigation to the NoteView (Aqua).
    @State private var navigateToNote = false

    @State private var navigateToPetal = false

    /// Tracks if RouteListView was dismissed when navigating away.
    @State private var wasRouteListSheetDismissed = false

    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600

    @State private var filteredWalkingPolylines: [MKPolyline] = []
    @State private var filteredRunningPolylines: [MKPolyline] = []
    @State private var filteredCyclingPolylines: [MKPolyline] = []
    @State private var selectedFilterDate: Date? = nil

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager = HealthKitManager()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                MapView(
                    routes: mapViewModel.displayableRoutes,
                    region: $mapViewModel.mapRegion,
                    mapType: .standard
                )
                .edgesIgnoringSafeArea(.all)

                clearZoomButtonOverlay

                controlButtons

                NavigationLink(
                    destination: Aqua(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showRouteListSheet) {
                routeListSheetContent
            }

            .sheet(isPresented: $showOpenAppSheet, onDismiss: {
                showRouteListSheet = true
            }) {
                OpenAppView()
            }
            .task {
                await initializeView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: setupViewModelCommunication)
        }
    }

    // MARK: Subviews

    /// Overlay button to clear the map zoom when a route is focused
    @ViewBuilder
    private var clearZoomButtonOverlay: some View {
        if mapViewModel.zoomedRouteID != nil {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        routeListViewModel.clearSelectedRoute()
                    } label: {
                        Label("Show All Routes", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                            .padding(8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 3)
                    }
                    .padding(.top, 60)
                    .padding(.trailing)
                }
                Spacer()
            }
        }
    }

    /// Control button overlay
    private var controlButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var routeListSheetContent: some View {
        RouteListView(viewModel: routeListViewModel)
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(20)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
    }

    // MARK: Vars

    @ViewBuilder
    private var sampleSheetContent: some View {
        SampleView(
            healthKitManager: healthKitManager,
            showWalkingRoutes: $showWalkingRoutes,
            showRunningRoutes: $showRunningRoutes,
            showCyclingRoutes: $showCyclingRoutes,
            selectedFilterDate: $selectedFilterDate,
            onOpenAppTap: {
                updateFilteredRoutes()
            },
            onNoteTap: {
                showRouteListSheet = false
                wasRouteListSheetDismissed = true
                DispatchQueue.main.async {
                    showOpenAppSheet = true
                }
            },
            onPetalTap: {
                showRouteListSheet = false
                wasRouteListSheetDismissed = true
                DispatchQueue.main.async {
                    navigateToNote = true
                }
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

    private func setupViewModelCommunication() {
        guard routeListViewModel.onFilterChange == nil else { return }

        print("Setting up ViewModel communication closures.")

        routeListViewModel.onFilterChange = { [weak mapViewModel] criteria in
            print("ContentView: Filter change triggered")
            mapViewModel?.applyFilters(criteria)
        }

        routeListViewModel.onRouteSelect = { [weak mapViewModel] routeId in
            print("ContentView: Route selection triggered for ID: \(routeId)")
            mapViewModel?.zoomToRoute(id: routeId)
        }

        routeListViewModel.onClearZoom = { [weak mapViewModel] in
            print("ContentView: Clear zoom triggered")
            mapViewModel?.clearZoom()
        }

        routeListViewModel.onNoteTap = { [weak self] in
            print("ContentView: Note tap triggered")
            self?.showRouteListSheet = false
            self?.wasRouteListSheetDismissed = true
        }

        routeListViewModel.onPetalTap = { [weak self] in
            print("ContentView: Petal tap triggered")
            self?.showRouteListSheet = false
            self?.wasRouteListSheetDismissed = true
            self?.navigateToPetal = true
        }
    }

    private func initializeView() async {
        print("ContentView: Initializing view...")
        showRouteListSheet = true

        async let mapLoad: () = mapViewModel.loadRoutes()
        async let listLoad: () = routeListViewModel.loadRoutes()

        _ = await [mapLoad, listLoad]

        print("ContentView: Initial data loading complete.")
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
