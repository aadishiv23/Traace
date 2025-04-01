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
                mapOverlay

                controlButtons

                // Hidden navigation link for programmatic navigation.
                NavigationLink(
                    destination: Aqua(),
                    isActive: $navigateToNote
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
        }
    }

    // MARK: Subviews

    /// Map overlay.
    private var mapOverlay: some View {
        Map {
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
        .edgesIgnoringSafeArea(.all)
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("📍 Walking Routes: \(healthKitManager.walkingRoutes.count)")
            print("📍 Running Routes: \(healthKitManager.runningRoutes.count)")
            print("📍 Cycling Routes: \(healthKitManager.cyclingRoutes.count)")
            updateFilteredRoutes()
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
