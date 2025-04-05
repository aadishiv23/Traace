//
//  MVVMContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import SwiftUI
import MapKit

/// The main view of the app using MVVM architecture
struct MVVMContentView: View {
    // MARK: - View Models
    
    /// The view model for the map
    @StateObject private var mapViewModel = MapViewModel()
    
    /// The view model for the route list
    @StateObject private var routeListViewModel = RouteListViewModel()
    
    // MARK: - State
    
    /// Whether to show the route list sheet
    @State private var showRouteList = true
    
    /// Whether the map is currently being interacted with
    @State private var isMapInteracting = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Map View
            MapView(
                routes: mapViewModel.displayableRoutes,
                region: $mapViewModel.mapRegion,
                isInteracting: $isMapInteracting
            )
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                // Map controls
                VStack(alignment: .leading, spacing: 12) {
                    // Show All button (when a route is zoomed)
                    if mapViewModel.zoomedRouteID != nil {
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
                    }
                    
                    // Loading indicator
                    if mapViewModel.isLoading {
                        ProgressView()
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 60)
            }
            .overlay(alignment: .topTrailing) {
                // Toggle sheet button
                Button {
                    withAnimation {
                        showRouteList.toggle()
                    }
                } label: {
                    Image(systemName: showRouteList ? "chevron.down" : "chevron.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.horizontal)
                .padding(.top, 60)
            }
            
            // Sheet pull indicator (only when sheet is hidden)
            if !showRouteList {
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
                                showRouteList.toggle()
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showRouteList) {
            RouteListView(viewModel: routeListViewModel)
                .presentationDetents([.height(250), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(true)
        }
        .onAppear {
            // Set up communication between ViewModels
            setupViewModelCommunication()
            
            // Initial data loading
            Task {
                await mapViewModel.loadRoutes()
            }
        }
    }
    
    // MARK: - Setup
    
    /// Sets up communication between the MapViewModel and RouteListViewModel
    private func setupViewModelCommunication() {
        // When filter criteria change in the route list, apply them to the map
        routeListViewModel.onFilterChange = { [weak mapViewModel] filterCriteria in
            mapViewModel?.applyFilters(filterCriteria)
        }
        
        // When a route is selected in the list, zoom to it on the map
        routeListViewModel.onRouteSelect = { [weak mapViewModel] routeId in
            mapViewModel?.zoomToRoute(id: routeId)
            
            // Auto-dismiss the sheet (optionally, could just reduce its height)
            withAnimation {
                showRouteList = false
            }
        }
        
        // When clearing zoom is requested, relay to the map view model
        routeListViewModel.onClearZoom = { [weak mapViewModel] in
            mapViewModel?.clearZoom()
        }
    }
}

#Preview {
    MVVMContentView()
} 