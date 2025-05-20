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

    @State private var isClearing = false
    @State private var isSyncing  = false
    @State private var showResetAlert = false
    @State private var statusMessage   = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance")
                            .font(.headline)
                            .padding(.horizontal)
                        NavigationLink {
                            RouteThemeSettingsView(selectedTheme: $selectedTheme)
                        } label: {
                            HStack {
                                Text("Route Theme")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Material.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Data Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data")
                            .font(.headline)
                            .padding(.horizontal)

                        // Reset button card
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Text("Reset & Rebuild Database")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Status cards
                        if isClearing {
                            HStack {
                                ProgressView()
                                Text("Clearing local data…")
                            }
                            .padding()
                            .background(Material.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else if isSyncing {
                            HStack {
                                ProgressView(value: Double(healthKitManager.loadedRouteCount),
                                             total: Double(healthKitManager.totalRouteCount))
                                Text("Syncing \(healthKitManager.loadedRouteCount)/\(healthKitManager.totalRouteCount)…")
                            }
                            .padding()
                            .background(Material.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            Text(statusMessage)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Material.ultraThinMaterial)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Are you sure?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    performReset()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will wipe all stored routes and re-sync from HealthKit.")
            }
        }
    }

    private func performReset() {
        isClearing    = true
        statusMessage = ""
        Task {
            // 1) Clear Core Data
            await CoreDataManager.shared.clearAllData()

            // 1.5) Clear local HealthKitManager route data so downstream views see empty state
            healthKitManager.walkingRouteInfos = []
            healthKitManager.runningRouteInfos = []
            healthKitManager.cyclingRouteInfos = []

            // 2) Trigger a fresh sync
            isClearing = false
            isSyncing  = true
            healthKitManager.syncData()

            // 3) Wait for sync to finish
            while healthKitManager.isLoadingRoutes {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            isSyncing = false
            statusMessage = "Rebuild complete 🎉"
        }
    }
}
