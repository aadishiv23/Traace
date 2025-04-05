//
//  TestMVVM.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import SwiftUI
import MapKit
import CoreData
import HealthKit

/// A view to test our MVVM architecture with MapViewModel and RouteListViewModel
struct TestMVVMView: View {
    // MARK: - Properties
    
    /// The view model for the map
    @StateObject private var mapViewModel = MapViewModel()
    
    /// The view model for the route list
    @StateObject private var routeListViewModel = RouteListViewModel()
    
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
            .overlay(alignment: .topTrailing) {
                // Map controls
                VStack {
                    if mapViewModel.zoomedRouteID != nil {
                        Button {
                            mapViewModel.clearZoom()
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding()
                    }
                    
                    if mapViewModel.isLoading {
                        ProgressView()
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                            .padding()
                    }
                }
            }
            
            // Sheet pull indicator
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
            
            // Auto-dismiss the sheet when a route is selected
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

/// Test ViewModel to verify our repository pattern
class TestViewModel: ObservableObject {
    @Published var routeSummaries: [RouteSummaryInfo] = []
    @Published var isLoading: Bool = false
    @Published var lastSyncDate: Date?
    
    private let repository = ServiceFactory.shared.routeRepository
    
    func loadRoutes() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // First ensure we have data
            let hasData = try await repository.ensureInitialData()
            if hasData {
                // Then fetch summaries
                let summaries = await repository.getRouteSummaryInfo()
                
                await MainActor.run {
                    self.routeSummaries = summaries
                    self.lastSyncDate = repository.lastSyncDate
                    self.isLoading = false
                }
            }
        } catch {
            print("Error loading routes: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func syncWithHealthKit() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let didSync = try await repository.syncWithHealthKit()
            
            if didSync {
                // Reload summaries if we synced new data
                let summaries = await repository.getRouteSummaryInfo()
                
                await MainActor.run {
                    self.routeSummaries = summaries
                    self.lastSyncDate = repository.lastSyncDate
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            print("Error syncing with HealthKit: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

#Preview {
    TestMVVMView()
} 