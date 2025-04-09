//
//  OnboardingView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/9/25.
//

import Foundation
import SwiftUI


struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Plore!")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 60)
            
            Spacer()
            
            FeatureRow(
                icon: "map.fill",
                iconColor: .blue,
                title: "See your routes on the map",
                description: "See your running, walking, and cycliing workouts diplayed on the map!"
            )
            
            FeatureRow(
                icon: "figure.run",
                iconColor: .red,
                title: "Workouts",
                description: "Supports running, walking, and cycling workouts."
            )
            
            FeatureRow(
                icon: "inset.filled.rectangle.and.person.filled",
                iconColor: .blue,
                title: "Share Snapshots",
                description: "Share a snapshot of your workout on social media!"
            )
            
            Spacer()
            
            Button(action: {
                hasCompletedOnboarding = true
            }) {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .padding()
    }
}

struct FeatureRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
