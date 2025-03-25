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
                Map {
                    // 🟦 Walking Routes
                    if showWalkingRoutes {
                        ForEach(filteredWalkingPolylines, id: \.self) { polyline in
                            MapPolyline(polyline)
                                .stroke(Color.blue, lineWidth: 3)
                        }
                    }

                    // 🟥 Running Routes
                    if showRunningRoutes {
                        ForEach(filteredRunningPolylines, id: \.self) { polyline in
                            MapPolyline(polyline)
                                .stroke(Color.red, lineWidth: 3)
                        }
                    }

                    // 🟩 Cycling Routes
                    if showCyclingRoutes {
                        ForEach(filteredCyclingPolylines, id: \.self) { polyline in
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

//                NavigationLink(
//                    destination: PetalAssistantView(),
//                    isActive: $navigateToPetal
//                ) {
//                    EmptyView()
//                }
            }
            // Primary sheet – SampleView.
            .sheet(isPresented: $showExampleSheet) {
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
                        // Dismiss SampleView and present OpenAppView.
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            showOpenAppSheet = true
                        }
                    },
                    onPetalTap: {
                        // Dismiss SampleView and navigate to NoteView.
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            navigateToNote = true
                        }
                    },
                    onDateFilterChanged: {
                        self.updateFilteredRoutes()
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

                // Initialize filtered routes with all routes
                filteredWalkingPolylines = healthKitManager.walkingPolylines
                filteredRunningPolylines = healthKitManager.runningPolylines
                filteredCyclingPolylines = healthKitManager.cyclingPolylines

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // Wait 5s for routes to load.
                    print("📍 Walking Routes: \(healthKitManager.walkingRoutes.count)")
                    print("📍 Running Routes: \(healthKitManager.runningRoutes.count)")
                    print("📍 Cycling Routes: \(healthKitManager.cyclingRoutes.count)")

                    updateFilteredRoutes()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    func updateFilteredRoutes() {
        let filtered = healthKitManager.filterRoutesByDate(date: selectedFilterDate)
        filteredWalkingPolylines = filtered.walking
        filteredRunningPolylines = filtered.running
        filteredCyclingPolylines = filtered.cycling
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
