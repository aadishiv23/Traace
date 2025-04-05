//
//  MVVMContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import SwiftUI
import MapKit

/// The main ContentView implementation using MVVM architecture
struct MVVMContentView: View {
    // MARK: - ViewModels
    
    /// The view model for the map
    @StateObject private var mapViewModel = MapViewModel()
    
    /// The view model for the route list
    @StateObject private var routeListViewModel = RouteListViewModel()
    
    // MARK: - Navigation State
    
    /// Controls when the sheet is shown.
    @State private var showRouteListSheet = true
    
    /// Controls when the OpenAppView sheet is shown.
    @State private var showOpenAppSheet = false
    
    /// Controls navigation to the NoteView.
    @State private var navigateToNote = false
    
    /// Controls navigation to the PetalView
    @State private var navigateToPetal = false
    
    /// Tracks if sheet was dismissed when navigating away.
    @State private var wasSheetDismissed = false
    
    /// Whether the map is currently being interacted with
    @State private var isMapInteracting = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                MapView(
                    routes: mapViewModel.displayableRoutes,
                    region: $mapViewModel.mapRegion,
                    isInteracting: $isMapInteracting
                )
                .ignoresSafeArea()
                
                // Control buttons (route type toggles)
                controlButtons
                
                // Hidden navigation links
                NavigationLink(destination: Aqua(), isActive: $navigateToNote) {
                    EmptyView()
                }
                
                // Pull indicator (only when sheet is hidden)
                if !showRouteListSheet {
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 40, height: 5)
                            .padding(.top, 6)
                            .padding(.bottom, 8)
                            .background(Color.clear)
                            .onTapGesture {
                                withAnimation {
                                    showRouteListSheet.toggle()
                                }
                            }
                    }
                }
            }
            // Route list sheet
            .sheet(isPresented: $showRouteListSheet) {
                RouteListView(viewModel: routeListViewModel)
                    .presentationDetents([
                        .custom(CompactDetent.self),
                        .medium,
                        .custom(OneSmallThanMaxDetent.self)
                    ])
                    .presentationCornerRadius(30)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
            }
            // Secondary sheet - OpenAppView
            .sheet(isPresented: $showOpenAppSheet, onDismiss: {
                showRouteListSheet = true
            }) {
                OpenAppView()
            }
            .onAppear {
                // Set up communication between ViewModels
                setupViewModelCommunication()
                
                // Initial data loading
                Task {
                    await mapViewModel.loadRoutes()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        VStack {
            // Map controls (Show All button for zoomed routes)
            if mapViewModel.zoomedRouteID != nil {
                HStack {
                    Button {
                        mapViewModel.clearZoom()
                    } label: {
                        Label("Show All", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Route type toggle buttons
            HStack {
                VStack(spacing: 0) {
                    routeToggleButton(icon: "figure.run", isOn: $routeListViewModel.showRunning, color: .red)
                    Divider().frame(width: 44).background(Color.gray.opacity(0.6))
                    routeToggleButton(icon: "figure.outdoor.cycle", isOn: $routeListViewModel.showCycling, color: .green)
                    Divider().frame(width: 44).background(Color.gray.opacity(0.6))
                    routeToggleButton(icon: "figure.walk", isOn: $routeListViewModel.showWalking, color: .blue)
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
    
    // MARK: - Setup
    
    /// Sets up communication between the ViewModels
    private func setupViewModelCommunication() {
        // When filter criteria change in the route list, apply them to the map
        routeListViewModel.onFilterChange = { [weak mapViewModel] filterCriteria in
            mapViewModel?.applyFilters(filterCriteria)
        }
        
        // When a route is selected in the list, zoom to it on the map
        routeListViewModel.onRouteSelect = { [weak mapViewModel] routeId in
            mapViewModel?.zoomToRoute(id: routeId)
            
            // Auto-dismiss the sheet when a route is selected
            withAnimation {
                showRouteListSheet = false
            }
        }
        
        // When clearing zoom is requested, relay to the map view model
        routeListViewModel.onClearZoom = { [weak mapViewModel] in
            mapViewModel?.clearZoom()
        }
        
        // Setup navigation closures for RouteListView
        // These would come from the SampleView where they delegate navigation to ContentView
        routeListViewModel.onOpenAppTap = {
            showRouteListSheet = false
            wasSheetDismissed = true
            DispatchQueue.main.async {
                showOpenAppSheet = true
            }
        }
        
        routeListViewModel.onNoteTap = {
            showRouteListSheet = false
            wasSheetDismissed = true
            DispatchQueue.main.async {
                navigateToNote = true
            }
        }
        
        routeListViewModel.onPetalTap = {
            showRouteListSheet = false
            wasSheetDismissed = true
            DispatchQueue.main.async {
                navigateToPetal = true
            }
        }
    }
}

#Preview {
    MVVMContentView()
} 