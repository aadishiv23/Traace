import SwiftUI
import Foundation

// MARK: - SampleView (Main Bottom Sheet)

struct SampleView: View {
    // MARK: - Properties
    
    /// Track the user's selected time interval.
    @State private var selectedSyncInterval: TimeInterval = 3600
    
    /// The search text (shared by both compact and expanded search views).
    @State private var searchText: String = ""
    
    /// Indicates if sync is in progress.
    @State private var isSyncing = false
    
    /// Last sync time.
    @State private var lastSyncTime: Date? = nil
    
    /// The date selected to be filtered by.
    @State private var selectedDate: Date? = nil
    
    /// Whether the Settings panel is showing.
    @State private var isShowingSettingsPanel = false
    
    /// Whether the search overlay is active (3D pop).
    @State private var isSearchBarActive = false
    
    /// Matched geometry namespace for the search bar transition.
    @Namespace private var searchBarNamespace
    
    /// The object that interfaces with HealthKit to fetch route data.
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// Bindings that toggle whether walking routes should be shown.
    @Binding var showWalkingRoutes: Bool
    
    /// Bindings that toggle whether running routes should be shown.
    @Binding var showRunningRoutes: Bool
    
    /// Bindings that toggle whether cycling routes should be shown.
    @Binding var showCyclingRoutes: Bool
    
    /// The date used for filtering routes.
    @Binding var selectedFilterDate: Date?
    
    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void
    let onPetalTap: () -> Void
    
    let onDateFilterChanged: (() -> Void)?
    
    let sampleData = ["Running Route", "Walking Route", "Cycling Route"] // Placeholder data
    
    /// Filter the sampleData by the current search text.
    var filteredItems: [String] {
        if searchText.isEmpty {
            return sampleData
        } else {
            return sampleData.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 1) The main sheet content, blurred when the search overlay is active
            mainContent
                .blur(radius: isSearchBarActive ? 10 : 0) // Slightly reduced blur for performance
            
            // 2) The “floating” search overlay
            if isSearchBarActive {
                searchOverlay
                    .zIndex(1)
                    // Use a scale + opacity transition for smoother insertion/removal
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.0).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
            
            // 3) The settings overlay, if needed
            if isShowingSettingsPanel {
                settingsOverlay
                    .zIndex(2)
                    .transition(.move(edge: .trailing))
            }
        }
        // A single, more “bouncy” spring animation for both states:
        .animation(
            .interactiveSpring(
                response: 0.45,      // how quickly the spring “responds”
                dampingFraction: 0.65, // how bouncy vs. damped
                blendDuration: 0.2
            ),
            value: isSearchBarActive || isShowingSettingsPanel
        )
    }
    
    // MARK: - Main Content (Sheet)
    
    /// The main content of the sheet, including a compact search bar, toggles, etc.
    private var mainContent: some View {
        VStack(spacing: 0) {
            // A “compact” search bar in the sheet
            if !isSearchBarActive {
                compactSearchBar
                    .padding(.vertical, 15)
            } else {
                // If the overlay is active, hide the search bar from here
                // so it can appear “moved” to the overlay.
                Color.clear.frame(height: 0)
            }
            
            // The main tab content below the search bar
            tabContentSection
        }
    }
    
    /// A compact search bar that sits in the sheet. When tapped, it triggers the overlay.
    private var compactSearchBar: some View {
        HStack {
            // The same SearchBarView, but matched geometry
            SearchBarView(
                searchText: $searchText,
                selectedDate: $selectedFilterDate,
                isInteractive: false // disabled typing in the sheet version
            )
            .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)
            .onChange(of: selectedFilterDate) { _ in
                onDateFilterChanged?()
            }
            .onTapGesture {
                // Tapping triggers the overlay
                isSearchBarActive = true
            }
            
            // Gear button
            Button {
                isShowingSettingsPanel.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Search Overlay
    
    /// A “floating” overlay that appears with a 3D pop, showing a fully interactive search bar + results.
    private var searchOverlay: some View {
        ZStack(alignment: .top) {
            // Dimmed background that also dismisses on tap
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isSearchBarActive = false
                }
            
            // A floating card that holds the search bar + search results
            VStack(spacing: 0) {
                // The fully interactive search bar, matched geometry
                SearchBarView(
                    searchText: $searchText,
                    selectedDate: $selectedFilterDate,
                    isInteractive: true
                )
                .matchedGeometryEffect(id: "SearchBar", in: searchBarNamespace)
                .padding(.top, 20)
                .onChange(of: selectedFilterDate) { _ in
                    onDateFilterChanged?()
                }
                
                // Divider
                Divider()
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                // The scrollable list of filtered items
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredItems, id: \.self) { item in
                            HStack {
                                Circle()
                                    .fill(colorForRoute(item))
                                    .frame(width: 12, height: 12)
                                
                                Text(item)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        
                        if filteredItems.isEmpty {
                            Text("No routes found")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            // Slight 3D scale + rotation for the “pop” effect
            .scaleEffect(1.03)
            .rotation3DEffect(
                .degrees(4),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.7
            )
        }
    }
    
    // MARK: - Settings Overlay
    
    private var settingsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    isShowingSettingsPanel = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.title.bold())
                        .padding(.bottom, 10)
                    
                    Toggle("Show Walking Routes", isOn: $showWalkingRoutes)
                    Toggle("Show Running Routes", isOn: $showRunningRoutes)
                    Toggle("Show Cycling Routes", isOn: $showCyclingRoutes)
                    Toggle("Dark Mode", isOn: .constant(false))
                    Toggle("Show Distance", isOn: .constant(true))
                    
                    Divider().padding(.vertical)
                    
                    Text("Version 1.0.0 • Build 2025.03.23")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContentSection: some View {
        routesTabContent
    }
    
    /// Routes tab content
    private var routesTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sync status section
                syncStatusSection
                
                // Route toggles
                routeToggleSection
                
                // Route list
                routeListSection
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
    }
    
    private var syncStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Route Data")
                    .font(.headline)
                Spacer()
                
                // Sync button
                ClaudeButton(
                    "Sync",
                    color: .blue,
                    size: .small,
                    rounded: true,
                    icon: Image(systemName: "arrow.triangle.2.circlepath"),
                    style: .modernAqua
                ) {
                    performSync()
                }
                .disabled(isSyncing)
                .opacity(isSyncing ? 0.7 : 1.0)
            }
            
            // Summary counts
            HStack(spacing: 20) {
                routeCountCard(count: healthKitManager.walkingRoutes.count, title: "Walking", color: .blue)
                routeCountCard(count: healthKitManager.runningRoutes.count, title: "Running", color: .red)
                routeCountCard(count: healthKitManager.cyclingRoutes.count, title: "Cycling", color: .green)
            }
            
            // Last sync info
            if let lastSync = lastSyncTime {
                Text("Last synced: \(timeAgoString(from: lastSync))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    private var routeToggleSection: some View {
        HStack(spacing: 12) {
            routeToggleButton(title: "Walking", isOn: $showWalkingRoutes, color: .blue)
            routeToggleButton(title: "Running", isOn: $showRunningRoutes, color: .red)
            routeToggleButton(title: "Cycling", isOn: $showCyclingRoutes, color: .green)
        }
    }
    
    private var routeListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Routes")
                .font(.headline)
            
            if !filteredItems.isEmpty {
                VStack(spacing: 10) {
                    ForEach(filteredItems, id: \.self) { item in
                        HStack {
                            Circle()
                                .fill(colorForRoute(item))
                                .frame(width: 12, height: 12)
                            
                            Text(item)
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            } else {
                Text("No routes found")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func routeCountCard(count: Int, title: String, color: Color) -> some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func routeToggleButton(title: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(isOn.wrappedValue ? color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isOn.wrappedValue ? color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isOn.wrappedValue ? color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isOn.wrappedValue ? color.opacity(0.3) : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    // MARK: - Sync Logic
    
    private func performSync() {
        // Start the sync process
        isSyncing = true
        
        // Using Task to properly handle async operations
        Task {
            do {
                // Simulate network request with better performance
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                // Use the main thread for UI updates
                await MainActor.run {
                    // Load routes more efficiently
                    healthKitManager.loadRoutes()
                    
                    // Update state
                    lastSyncTime = Date()
                    isSyncing = false
                }
            } catch {
                // Handle any errors
                print("Sync error: \(error)")
                
                await MainActor.run {
                    isSyncing = false
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func colorForRoute(_ route: String) -> Color {
        if route.contains("Walking") {
            return .blue
        } else if route.contains("Running") {
            return .red
        } else if route.contains("Cycling") {
            return .green
        }
        return .gray
    }
}

// MARK: - SearchBarView

/// A reusable search bar. The `isInteractive` flag lets us disable typing
/// in the “compact” version but enable it in the “expanded” overlay.
import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedDate: Date?
    
    /// Whether the user can actually type here (e.g. in the overlay).
    var isInteractive: Bool
    
    @State private var showDatePicker = false
    @State private var tempDate = Date()
    
    /// Focus state for the text field
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search routes", text: $searchText)
                        .font(.system(size: 16))
                        .disabled(!isInteractive)
                        .focused($textFieldFocused)
                    
                    if !searchText.isEmpty && isInteractive {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(4)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                
                // Date filter button
                Button(action: {
                    if isInteractive {
                        tempDate = selectedDate ?? Date()
                        showDatePicker.toggle()
                    }
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedDate != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                }
                .disabled(!isInteractive)
            }
            
            // Date filter chips (only shown when date is selected)
            if let date = selectedDate {
                HStack {
                    Spacer()
                    
                    Text("Filtered by: ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 14, weight: .medium))
                        
                        if isInteractive {
                            Button(action: {
                                selectedDate = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue))
                    .foregroundColor(.white)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: selectedDate)
        // Automatically focus the text field when interactive
        .onAppear {
            if isInteractive {
                // A slight delay allows the overlay transition to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    textFieldFocused = true
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") {
                        showDatePicker = false
                    }
                    
                    Spacer()
                    
                    Text("Filter by Date")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Apply") {
                        selectedDate = tempDate
                        showDatePicker = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                DatePicker("", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal)
                
                Button(action: {
                    selectedDate = nil
                    showDatePicker = false
                }) {
                    Text("Clear Filter")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .presentationDetents([.height(500)])
            .presentationCornerRadius(20)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
}

