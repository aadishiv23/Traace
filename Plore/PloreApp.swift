//
//  PloreApp.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import SwiftUI

@main
struct PloreApp: App {
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasSeenOnboarding)
            }
        }
    }
}
