//
//  RouteListView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import SwiftUI
import HealthKit

/// A view that displays a list of routes with filtering options
struct RouteListView: View {
    // MARK: - Properties
    
    /// The view model managing the route list data and state
    @ObservedObject var viewModel: RouteListViewModel
    
    /// Whether the search bar is active and showing full search/filter UI
    @State private var isSearchBarActive = false
    
    /// Namespace for matched geometry effect between compact and expanded search bar
    @Namespace private var searchBarNamespace
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search bar
            VStack(spacing: 0) {
                if !isSearchBarActive {
                    compactSearchBar
                        .padding(.vertical, 15)
                } else {
                    Color.clear.frame(height: 0)
                }
            }
            
            // Main content
            if viewModel.isSyncing {
                syncProgressView
            } else {
                routeListContent
            }
        }
        .overlay {
            if isSearchBarActive {
                searchOverlay
            }
        }
        // ViewModel's init already loads data
        // .onAppear {
        //     Task {
        //         await viewModel.loadRoutes() // Corrected method name if needed, but init handles it
        //     }
        // }
    }
    
    // MARK: - Subviews
    
    /// A compact search bar for the collapsed state
    private var compactSearchBar: some View {
        HStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Text(viewModel.searchText.isEmpty ? "Search or filter routes..." : viewModel.searchText)
                    .foregroundColor(viewModel.searchText.isEmpty ? .gray : .primary)
                
                Spacer()
                
                // Indicate if filters are active (other than default types shown)
                if areFiltersActive() {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSearchBarActive = true
                }
            }
            
            // Settings button (functionality can be added later)
             Button {
                 viewModel.isShowingSettings.toggle() // Toggle settings state in ViewModel
             } label: {
                 Image(systemName: "gearshape.fill")
                     .font(.system(size: 18, weight: .medium))
                     .foregroundColor(.gray)
                     .padding(8)
                     .background(Color(.systemGray6))
                     .clipShape(Circle())
             }
        }
        .padding(.horizontal)
        .sheet(isPresented: $viewModel.isShowingSettings) {
             SettingsView(viewModel: viewModel) // Present SettingsView as a sheet
         }
    }
    
    /// The main list of routes
    private var routeListContent: some View {
        List {
            // Route type toggles
            routeTypeToggles
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.bottom, 5) // Add some space below toggles

            // Route list
            if viewModel.filteredRoutes.isEmpty {
                emptyStateView
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                routesList
            }
        }
        .listStyle(.plain)
    }
    
    /// Toggles for route types
    private var routeTypeToggles: some View {
        HStack {
            Spacer()
            
            routeToggleButton(
                iconName: "figure.walk",
                isOn: $viewModel.showWalking, // Use Binding
                color: .blue
            )
            
            Spacer()
            
            routeToggleButton(
                iconName: "figure.run",
                isOn: $viewModel.showRunning, // Use Binding
                color: .red
            )
            
            Spacer()
            
            routeToggleButton(
                iconName: "figure.outdoor.cycle",
                isOn: $viewModel.showCycling, // Use Binding
                color: .green
            )
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    /// A toggle button for a route type
    private func routeToggleButton(iconName: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            withAnimation {
                isOn.wrappedValue.toggle() // Toggle the binding
            }
        } label: {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .symbolVariant(isOn.wrappedValue ? .fill : .none)
                    .foregroundStyle(isOn.wrappedValue ? color : .gray)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6).opacity(isOn.wrappedValue ? 0.3 : 0))
                    .clipShape(Circle())
                
                // Text("On"/"Off") is redundant with fill/no fill icon, removed for cleaner look
                // Text(isOn.wrappedValue ? "On" : "Off")
                //     .font(.system(size: 12))
                //     .foregroundStyle(isOn.wrappedValue ? color : .gray)
            }
        }
    }
    
    /// The list of routes
    private var routesList: some View {
        ForEach(viewModel.filteredRoutes) { route in // Use filteredRoutes and WorkoutRoute
            Button {
                viewModel.selectRoute(route) // Pass the whole route object
            } label: {
                HStack(spacing: 12) {
                    // Activity icon
                    Image(systemName: iconForActivityType(route.workoutActivityType)) // Use helper for icon name
                        .font(.system(size: 20))
                        .foregroundColor(colorForActivityType(route.workoutActivityType)) // Use helper
                        .frame(width: 40, height: 40)
                        .background(colorForActivityType(route.workoutActivityType).opacity(0.2)) // Use helper
                        .clipShape(Circle())
                    
                    // Route details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.name ?? "Workout") // Use route name or fallback
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack {
                             Text(route.formattedDate ?? "") // Use formattedDate from route
                                 .font(.subheadline)
                             Spacer() // Push duration to the right
                             Text(route.formattedDistance ?? "") // Display distance
                                 .font(.subheadline)
                        }
                        .foregroundColor(.secondary)

                    }
                    
                    Spacer() // Push chevron to the right
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.vertical, 4) // Add padding for better spacing
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    /// View shown when no routes match the filter criteria
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle") // Slightly different icon
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Matching Routes")
                .font(.title2)
                .fontWeight(.semibold)
             
             Text(viewModel.searchText.isEmpty ? "Try adjusting filters or sync HealthKit." : "Try refining your search or filters.")
                 .font(.subheadline)
                 .foregroundColor(.gray)
                 .multilineTextAlignment(.center)
                 .padding(.horizontal)

            // Offer to reset filters if they are active
            if areFiltersActive() {
                Button {
                    resetFilters()
                } label: {
                    Text("Reset Filters")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            } else {
                // Offer to sync if no filters are active and list is empty
                 Button {
                     Task {
                         await viewModel.loadRoutes() // Reload/resync
                     }
                 } label: {
                     Label("Sync HealthKit", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                 }
                 .buttonStyle(.bordered)
                 .tint(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50) // Add more vertical padding
    }
    
    /// Progress view shown during sync
    private var syncProgressView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5) // Make it larger
            Text("Syncing routes...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Expanded search and filter overlay
    private var searchOverlay: some View {
        VStack(spacing: 0) {
            // Top section: Search bar and Cancel button
            HStack {
                // Expanded search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search routes...", text: $viewModel.searchText) // Bind to viewModel
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !viewModel.searchText.isEmpty {
                         Button {
                             viewModel.searchText = "" // Clear search text
                         } label: {
                             Image(systemName: "xmark.circle.fill")
                                 .foregroundColor(.gray)
                         }
                     }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)

                // Cancel button
                Button("Cancel") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSearchBarActive = false
                        // Optionally reset search text on cancel, or keep it
                        // viewModel.searchText = ""
                         // Hide keyboard if needed (requires more setup usually)
                    }
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal)
            .padding(.top, 15) // Add padding from top safe area
            .padding(.bottom, 10)

            // Filter section: Date Range and Sync Interval
            Form {
                Section("Filter by Date Range") {
                    Picker("Sync Interval", selection: $viewModel.selectedSyncInterval) {
                         ForEach(SyncInterval.allCases) { interval in
                             Text(interval.rawValue).tag(interval)
                         }
                     }
                    .onChange(of: viewModel.selectedSyncInterval) { _, _ in
                        // ViewModel handles date updates and reloading
                    }

                    // Date pickers show the derived range
                     DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                         .disabled(true) // Disabled as it's derived from interval
                     DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                         .disabled(true) // Disabled as it's derived from interval
                }
            }
            .frame(height: 200) // Limit height of Form
             
            Spacer() // Push everything up
        }
        .background(.ultraThinMaterial) // Use material background
        .edgesIgnoringSafeArea(.bottom) // Extend background down
    }

    // MARK: - Helper Methods
    
    /// Returns the appropriate color for a given activity type
    private func colorForActivityType(_ type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking, .hiking:
            return .blue
        case .running:
            return .red
        case .cycling:
            return .green
        default:
            return .gray
        }
    }
    
    /// Returns the appropriate SF Symbol name for a given activity type
    private func iconForActivityType(_ type: HKWorkoutActivityType) -> String {
         switch type {
         case .walking:
             return "figure.walk"
         case .running:
             return "figure.run"
         case .cycling:
             return "figure.outdoor.cycle"
         case .hiking:
             return "figure.hiking" // Specific icon for hiking
         default:
             return "figure.mixed.cardio" // Generic fallback
         }
     }

    /// Checks if any filters are active beyond the default (all types shown, default date range)
    private func areFiltersActive() -> Bool {
        return !viewModel.searchText.isEmpty ||
               viewModel.selectedSyncInterval != .threeMonths || // Check if interval differs from default
               !viewModel.showWalking ||
               !viewModel.showRunning ||
               !viewModel.showCycling
    }

    /// Resets all filters to their default state
    private func resetFilters() {
        withAnimation {
            viewModel.searchText = ""
            viewModel.showWalking = true
            viewModel.showRunning = true
            viewModel.showCycling = true
            viewModel.selectedSyncInterval = .threeMonths // Resets date range via ViewModel's didSet
        }
    }
}

// MARK: - Settings View (Placeholder)

struct SettingsView: View {
    @ObservedObject var viewModel: RouteListViewModel // Pass ViewModel if needed
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Sync Options") {
                    // Example: Allow manual sync
                    Button {
                        Task {
                            await viewModel.loadRoutes()
                            dismiss() // Dismiss after sync
                        }
                    } label: {
                        Label("Sync HealthKit Now", systemImage: "arrow.clockwise")
                    }
                }
                 Section("About") {
                     Text("Plore App - Version 1.0") // Example content
                 }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Preview

struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ViewModel for previewing
        let mockViewModel = RouteListViewModel()
        // Optionally add some mock data to the viewModel if needed for preview
        
        RouteListView(viewModel: mockViewModel)
    }
} 