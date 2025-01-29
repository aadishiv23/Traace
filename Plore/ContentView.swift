//
//  ContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import MapKit
import SwiftUI

struct ContentView: View {
    @State private var showDock = true
    @State private var selectedAction: String?

    var body: some View {
        ZStack {
            // Map Background
            Map()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                if showDock {
                    commandDock
//                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.2), value: showDock)
        }
        .onTapGesture {
            withAnimation {
                showDock.toggle()
            }
        }
    }

    /// Floating Dock with Buttons
    private var commandDock: some View {
        HStack(spacing: 20) {
            commandButton(icon: "mappin.and.ellipse", title: "Mark")
            Spacer()
            commandButton(icon: "arrow.triangle.2.circlepath", title: "Refresh")
            Spacer()
            commandButton(icon: "gear", title: "Settings")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .shadow(radius: 5)
        )
        .frame(width: UIScreen.main.bounds.width - 40, height: 60)
        .padding(.bottom, 20)
    }

    /// Animated Command Button
    private func commandButton(icon: String, title: String) -> some View {
        Button(action: {
            withAnimation {
                selectedAction = title
            }
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.blue).shadow(radius: 3))
                    .scaleEffect(selectedAction == title ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedAction)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
