//
//  PloreApp.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import SwiftUI

@main
struct PloreApp: App {
    /// The current UI mode (original, test, or MVVM)
    @State private var uiMode: UIMode = .mvvm
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch uiMode {
                case .original:
                    ContentView()
                case .test:
                    TestMVVMView()
                case .mvvm:
                    MVVMContentView()
                }
            }
            .overlay(alignment: .topTrailing) {
                modeSelector
            }
        }
    }
    
    /// UI to select between the different modes
    private var modeSelector: some View {
        Menu {
            Button("Original UI") {
                uiMode = .original
            }
            Button("Test MVVM") {
                uiMode = .test
            }
            Button("MVVM UI") {
                uiMode = .mvvm
            }
        } label: {
            Text(uiMode.rawValue)
                .font(.caption)
                .padding(6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
        .padding(.top, 50)
        .padding(.trailing, 8)
    }
}

/// The different UI modes available in the app
enum UIMode: String {
    case original = "Original"
    case test = "Test MVVM"
    case mvvm = "MVVM"
}
