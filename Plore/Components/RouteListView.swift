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
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    // MARK: - Subviews
    
    /// A compact search bar for the collapsed state
    private var compactSearchBar: some View {
        HStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Text("Search routes...")
                    .foregroundColor(.gray)
                
                Spacer()
                
                if viewModel.selectedDateFilter != nil {
                    Image(systemName: "calendar")
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
            
            // Settings button
            Button {
                // Show settings
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
    }
    
    /// The main list of routes
    private var routeListContent: some View {
        List {
            // Route type toggles
            routeTypeToggles
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            // Route list
            if viewModel.filteredSummaries.isEmpty {
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
                isOn: viewModel.showWalking,
                color: .blue,
                action: { viewModel.showWalking.toggle() }
            )
            
            Spacer()
            
            routeToggleButton(
                iconName: "figure.run",
                isOn: viewModel.showRunning,
                color: .red,
                action: { viewModel.showRunning.toggle() }
            )
            
            Spacer()
            
            routeToggleButton(
                iconName: "figure.outdoor.cycle",
                isOn: viewModel.showCycling,
                color: .green,
                action: { viewModel.showCycling.toggle() }
            )
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    /// A toggle button for a route type
    private func routeToggleButton(iconName: String, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .symbolVariant(isOn ? .fill : .none)
                    .foregroundStyle(isOn ? color : .gray)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6).opacity(isOn ? 0.3 : 0))
                    .clipShape(Circle())
                
                Text(isOn ? "On" : "Off")
                    .font(.system(size: 12))
                    .foregroundStyle(isOn ? color : .gray)
            }
        }
    }
    
    /// The list of routes
    private var routesList: some View {
        ForEach(viewModel.filteredSummaries) { summary in
            Button {
                viewModel.selectRoute(id: summary.id)
            } label: {
                HStack(spacing: 12) {
                    // Activity icon
                    Image(systemName: summary.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(colorForActivityType(summary.activityType))
                        .frame(width: 40, height: 40)
                        .background(colorForActivityType(summary.activityType).opacity(0.2))
                        .clipShape(Circle())
                    
                    // Route details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activityTypeToString(summary.activityType))
                            .font(.headline)
                        
                        Text(summary.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    /// View shown when no routes match the filter criteria
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No matching routes found")
                .font(.headline)
            
            if viewModel.selectedDateFilter != nil || !viewModel.showWalking || !viewModel.showRunning || !viewModel.showCycling {
                Button {
                    resetFilters()
                } label: {
                    Text("Reset Filters")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                Button {
                    Task {
                        await viewModel.triggerSync()
                    }
                } label: {
                    Text("Sync with HealthKit")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    /// Progress view shown during sync
    private var syncProgressView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Syncing with HealthKit...")
                .font(.headline)
            
            if let lastSync = viewModel.lastSyncTime {
                Text("Last sync: \(formattedDate(lastSync))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    /// The search and filter overlay
    private var searchOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSearchBarActive = false
                    }
                }
            
            // Search UI
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search routes...", text: $viewModel.searchText)
                        .disableAutocorrection(true)
                    
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        // Show date picker
                        withAnimation {
                            if viewModel.selectedDateFilter == nil {
                                viewModel.selectedDateFilter = Date()
                            } else {
                                viewModel.selectedDateFilter = nil
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(viewModel.selectedDateFilter != nil ? .blue : .gray)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)
                .padding(.horizontal)
                .padding(.top, 15)
                
                // Date picker if date filter is active
                if let selectedDate = viewModel.selectedDateFilter {
                    DatePicker("", selection: Binding(
                        get: { selectedDate },
                        set: { viewModel.selectedDateFilter = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Resets all filters to their default values
    private func resetFilters() {
        viewModel.selectedDateFilter = nil
        viewModel.showWalking = true
        viewModel.showRunning = true
        viewModel.showCycling = true
        viewModel.searchText = ""
    }
    
    /// Returns a color for a given workout activity type
    private func colorForActivityType(_ type: HKWorkoutActivityType) -> Color {
        switch type {
        case .walking:
            return .blue
        case .running:
            return .red
        case .cycling:
            return .green
        default:
            return .gray
        }
    }
    
    /// Converts a workout activity type to a readable string
    private func activityTypeToString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking:
            return "Walking"
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        default:
            return "Other"
        }
    }
    
    /// Formats a date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#if DEBUG
struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        RouteListView(viewModel: RouteListViewModel())
            .previewLayout(.sizeThatFits)
    }
}
#endif 