//
//  SettingsView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 5/20/25.
//

import Foundation
import SwiftUI

/// A general settings screen for Plore.
struct SettingsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @Binding var selectedTheme: RouteColorTheme
    @AppStorage("polylineStyle") private var polylineStyle: PolylineStyle = .standard // Default to standard

    @State private var isClearing = false
    @State private var isSyncing  = false
    @State private var showResetAlert = false
    @State private var statusMessage   = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance").font(.headline).padding(.leading, -10)) {
                    NavigationLink {
                        RouteThemeSettingsView(selectedTheme: $selectedTheme)
                    } label: {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(selectedTheme.previewColor)
                            Text("Route Color Theme")
                            Spacer()
                            Text(selectedTheme.rawValue.capitalized)
                                .foregroundColor(.gray)
                        }
                    }

                    Picker(selection: $polylineStyle, label: 
                        HStack {
                            Image(systemName: "scribble.variable")
                                .foregroundColor(.accentColor)
                            Text("Polyline Style")
                        }
                    ) {
                        ForEach(PolylineStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    // Polyline style preview
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Preview:")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 2)
                        
                        ZStack {
                            // Background line to simulate a map path better
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                                .frame(height: 20)

                            if polylineStyle == .custom {
                                // Casing
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.black.opacity(0.4), lineWidth: 7)
                                    .frame(height: 20)
                                // Main gradient line
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [selectedTheme.previewColor.opacity(0.8), selectedTheme.previewColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 5
                                    )
                                    .frame(height: 20)
                            } else {
                                // Standard line
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(selectedTheme.previewColor, lineWidth: 5)
                                    .frame(height: 20)
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.bottom, 8)
                    }
                    .padding(.top, 4)
                    
                }

                Section(header: Text("Data Management").font(.headline).padding(.leading, -10)) {
                    Button {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Reset & Rebuild Database")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }

                    // Status display
                    VStack(alignment: .leading) {
                        if isClearing {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Clearing local data…")
                                    .font(.footnote)
                            }
                        } else if isSyncing {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Syncing from HealthKit…")
                                    .font(.footnote)
                                ProgressView(value: Double(healthKitManager.loadedRouteCount),
                                             total: Double(healthKitManager.totalRouteCount > 0 ? healthKitManager.totalRouteCount : 1) // Avoid division by zero
                                )
                                .progressViewStyle(.linear)
                                Text("\(healthKitManager.loadedRouteCount) of \(healthKitManager.totalRouteCount) routes loaded")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        } else if !statusMessage.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(statusMessage)
                                    .font(.footnote)
                            }
                        } else {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Tap Reset to refresh route data from HealthKit.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Text("Done") }
                }
            }
            .alert("Are you sure?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    performReset()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will wipe all stored routes and re-sync from HealthKit. This action cannot be undone.")
            }
        }
    }

    private func performReset() {
        isClearing    = true
        statusMessage = ""
        Task {
            await MainActor.run { // Ensure UI updates on main thread
                healthKitManager.walkingRouteInfos = []
                healthKitManager.runningRouteInfos = []
                healthKitManager.cyclingRouteInfos = []
            }
            
            await CoreDataManager.shared.clearAllData()

            await MainActor.run { // Ensure UI updates on main thread
                isClearing = false
                isSyncing  = true
            }
            
            await healthKitManager.loadRoutes() // Ensure this re-fetches everything

            await MainActor.run { // Ensure UI updates on main thread
                isSyncing = false
                statusMessage = "Rebuild complete! 🎉"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if statusMessage == "Rebuild complete! 🎉" { 
                        statusMessage = ""
                    }
                }
            }
        }
    }
}

extension RouteColorTheme {
    var previewColor: Color {
        let colors = RouteColors.colors(for: self)
        return colors.running 
    }
}


#Preview {
    SettingsView(
        healthKitManager: HealthKitManager(), 
        selectedTheme: .constant(.vibrant)
    )
}
