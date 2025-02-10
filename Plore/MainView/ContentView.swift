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

    /// Tracks if ExampleSheet was dismissed when navigating away.
    @State private var wasExampleSheetDismissed = false

    /// Tracks if walking routes should be shown.
    @State private var showWalkingRoutes = true

    /// Tracks if running routes should be shown.
    @State private var showRunningRoutes = true

    /// Tracks if cycling routes should be shown
    @State private var showCyclingRoutes = true

    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager = HealthKitManager()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Map {
                    // 🟦 Walking Routes
                    if showWalkingRoutes {
                        ForEach(healthKitManager.walkingRoutes, id: \.self) { route in
                            let coordinates = route.map(\.coordinate)
                            let polyline = MKPolyline(
                                coordinates: coordinates,
                                count: coordinates.count
                            )

                            withAnimation {
                                MapPolyline(polyline)
                                    .stroke(Color.blue, lineWidth: 3)
                            }
                        }
                    }

                    // 🟥 Running Routes
                    if showRunningRoutes {
                        ForEach(healthKitManager.runningRoutes, id: \.self) { route in
                            let coordinates = route.map(\.coordinate)
                            let polyline = MKPolyline(
                                coordinates: coordinates,
                                count: coordinates.count
                            )

                            withAnimation {
                                MapPolyline(polyline)
                                    .stroke(Color.red, lineWidth: 3)
                            }
                        }
                    }

                    // 🟩 Cycling Routes
                    if showCyclingRoutes {
                        ForEach(healthKitManager.cyclingRoutes, id: \.self) { route in
                            let coordinates = route.map(\.coordinate)
                            let polyline = MKPolyline(
                                coordinates: coordinates,
                                count: coordinates.count
                            )

                            withAnimation {
                                MapPolyline(polyline)
                                    .stroke(Color.green, lineWidth: 3)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)

                // Hidden navigation link for programmatic navigation.
                NavigationLink(
                    destination: NoteView(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }
            }
            // Primary sheet – SampleView.
            .sheet(isPresented: $showExampleSheet) {
                SampleView(
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

/// A bottom sheet view that provides several shortcuts and actions.
struct SampleView: View {

    /// Bindings that toggle whether walking routes should be shown.
    @Binding var showWalkingRoutes: Bool

    /// Bindings that toggle whether running routes should be shown.
    @Binding var showRunningRoutes: Bool

    /// Bindings that toggle whether cycling routes should be shown.
    @Binding var showCyclingRoutes: Bool

    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void

    let categories = [
        ("Scripting", "wand.and.stars"),
        ("Controls", "slider.horizontal.3"),
        ("Device", "iphone.gen3"),
        ("More", "ellipsis")
    ]

    var body: some View {
        ScrollView {
            VStack {
                searchBar

                HStack(spacing: 10) {
                    ToggleButton(title: "Running", color: .red, isOn: $showRunningRoutes)
                    ToggleButton(title: "Walking", color: .blue, isOn: $showWalkingRoutes)
                    ToggleButton(title: "Cycling", color: .green, isOn: $showCyclingRoutes)
                }
                .padding()
            }

            // Horizontal scroll categories.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.0) { category in
                        CategoryButton(title: category.0, icon: category.1)
                    }
                }
                .padding(.horizontal)
            }

            // Color boxes for mood representation.
            HStack(spacing: 5) {
                ColorBox(
                    color: .red.opacity(0.8),
                    text: "Friendly"
                )
                ColorBox(color: .blue.opacity(0.8), text: "Office")
                ColorBox(color: .green.opacity(0.8), text: "Concise")
            }
            .padding(.horizontal)

            HStack(spacing: 5) {
                ColorBox(color: .blue.opacity(0.8), text: "Office")
                ColorBox(color: .green.opacity(0.8), text: "Concise")
            }
            .padding(.horizontal)

            // "Get Started" Section.
            Text("Get Started")
                .font(.title2.bold())
                .foregroundStyle(.black)
                .padding(.horizontal)

            // Shortcuts Grid.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ShortcutButton(
                    title: "Open App...",
                    icon: "square.dashed",
                    gradient: Gradient(colors: [.blue, .cyan]),
                    action: onOpenAppTap
                )
                ShortcutButton(
                    title: "Call Favorites",
                    icon: "phone.fill",
                    gradient: Gradient(colors: [.green, .mint])
                )
                ShortcutButton(
                    title: "Recently Played",
                    icon: "music.note",
                    gradient: Gradient(colors: [.red, .orange])
                )
                ShortcutButton(
                    title: "Set Timer",
                    icon: "timer",
                    gradient: Gradient(colors: [.yellow, .orange])
                )
                ShortcutButton(
                    title: "New Note",
                    icon: "note.text",
                    gradient: Gradient(colors: [.orange, .yellow]),
                    action: onNoteTap
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: Subviews

    /// The search bar that in the future will allow users to filter different data values.
    /// Currently it is a static UI element
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray.opacity(0.8))
            Text("Search")
                .foregroundStyle(.gray.opacity(0.8))
            Spacer()
        }
        .padding(.all, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 15)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
