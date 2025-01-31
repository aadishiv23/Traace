//
//  ContentView.swift
//  PloreTracker Watch App
//
//  Created by Aadi Shiv Malhotra on 1/30/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var healthKitManager = HealthKitManager.shared
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView {
            // Main workout view
            VStack(spacing: 12) {
                if healthKitManager.isTracking {
                    // Timer display
                    Text(formatTime(elapsedTime))
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundStyle(.green)
                        .padding(.top, 5)
                    
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.caption2)
                    }
                }
                
                Spacer()
                
                // Main action button
                Button(action: {
                    if healthKitManager.isTracking {
                        healthKitManager.stopWorkout()
                        elapsedTime = 0
                    } else {
                        healthKitManager.startWalkWorkout()
                    }
                }) {
                    Image(systemName: healthKitManager.isTracking ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(healthKitManager.isTracking ? .red : .green)
                }
                .buttonStyle(.plain)
                
                Text(healthKitManager.isTracking ? "Stop Walk" : "Start Walk")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(healthKitManager.isTracking ? .red : .green)
            }
            
            // Stats view (swipe left)
            if healthKitManager.isTracking {
                VStack(spacing: 15) {
                    Text("Statistics")
                        .font(.system(.headline, design: .rounded))
                    
                    StatView(
                        icon: "clock.fill",
                        title: "Duration",
                        value: formatTime(elapsedTime)
                    )
                    
                    StatView(
                        icon: "location.fill",
                        title: "GPS",
                        value: "Active"
                    )
                }
            }
        }
        .tabViewStyle(.page)
        .onAppear {
            Task(priority: .high) {
                await healthKitManager.requestHKPermissions()
            }
        }
        .onReceive(timer) { _ in
            if healthKitManager.isTracking {
                elapsedTime += 1
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct StatView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(.body, weight: .semibold))
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.gray)
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .medium))
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
