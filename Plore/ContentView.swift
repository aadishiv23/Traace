//
//  ContentView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 1/29/25.
//

import MapKit
import SwiftUI

/// The main view displaying a Map and handling sheet presentations & navigation.
/// Ensures that `SampleView` reappears when returning to this screen.
struct ContentView: View {
    /// Controls when the SampleView sheet is shown
    @State private var showExampleSheet = false

    /// Controls when the OpenAppView sheet is shown
    @State private var showOpenAppSheet = false

    /// Controls navigation to the NoteView
    @State private var navigateToNote = false

    /// Tracks if ExampleSheet was dismissed when navigating away
    @State private var wasExampleSheetDismissed = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Display a full-screen map
                Map()
                    .edgesIgnoringSafeArea(.all)

                // Hidden navigation link to trigger programmatic navigation
                NavigationLink(
                    destination: NoteView(),
                    isActive: $navigateToNote
                ) {
                    EmptyView()
                }
            }
            // Primary sheet - SampleView
            .sheet(isPresented: $showExampleSheet) {
                SampleView(
                    onOpenAppTap: {
                        // Dismiss SampleView and present OpenAppView
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            showOpenAppSheet = true
                        }
                    },
                    onNoteTap: {
                        // Dismiss SampleView and navigate to NoteView
                        showExampleSheet = false
                        wasExampleSheetDismissed = true
                        DispatchQueue.main.async {
                            navigateToNote = true
                        }
                    }
                )
                .presentationDetents([
                    .custom(CompactDetent.self),
                    .medium,
                    .custom(OneSmallThanMaxDetent.self)
                ])
                .presentationCornerRadius(30)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
            }
            // Secondary sheet - OpenAppView
            // Added onDismiss to re-show the SampleView
            .sheet(isPresented: $showOpenAppSheet, onDismiss: {
                showExampleSheet = true
            }) {
                OpenAppView()
            }
            .onAppear {
                // Show ExampleSheet again if returning to this view
                showExampleSheet = true
                // If you specifically need the wasExampleSheetDismissed logic:
                //                if wasExampleSheetDismissed {
                //                    showExampleSheet = true
                //                    wasExampleSheetDismissed = false
                //                } else {
                //                    showExampleSheet = true
                //                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - SampleView (Main Bottom Sheet)

struct SampleView: View {
    let onOpenAppTap: () -> Void
    let onNoteTap: () -> Void

    let categories = [
        ("Scripting", "wand.and.stars"),
        ("Controls", "slider.horizontal.3"),
        ("Device", "iphone.gen3"),
        ("More", "ellipsis")
    ]

    var body: some View {
        ScrollView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray.opacity(0.8))
                    Text("Search")
                        .foregroundStyle(.gray.opacity(0.8))
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                )
                .padding(.horizontal)
                .padding(.top, 25)
                .padding(.bottom, 20)
            }

            // Horizontal scroll categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.0) { category in
                        CategoryButton(title: category.0, icon: category.1)
                    }
                }
                .padding(.horizontal)
            }

            // Color boxes for mood representation
            HStack(spacing: 5) {
                ColorBox(
                    color: .red.opacity(0.8),
                    text: "Friendly"
                )
                ColorBox(color: .blue.opacity(0.8), text: "Office")
                ColorBox(color: .green.opacity(0.8), text: "Concise")
            }
            .padding(.horizontal)
            
            HStack(spacing: 5) {
                ColorBox(color: .blue.opacity(0.8), text: "Office")
                ColorBox(color: .green.opacity(0.8), text: "Concise")
            }
            .padding(.horizontal)
            

            // "Get Started" Section
            Text("Get Started")
                .font(.title2.bold())
                .foregroundStyle(.black)
                .padding(.horizontal)

            // Shortcuts Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ShortcutButton(
                    title: "Open App...",
                    icon: "square.dashed",
                    gradient: Gradient(colors: [.blue, .cyan]),
                    action: onOpenAppTap
                )
                ShortcutButton(
                    title: "Call Favorites",
                    icon: "phone.fill",
                    gradient: Gradient(colors: [.green, .mint])
                )
                ShortcutButton(
                    title: "Recently Played",
                    icon: "music.note",
                    gradient: Gradient(colors: [.red, .orange])
                )
                ShortcutButton(
                    title: "Set Timer",
                    icon: "timer",
                    gradient: Gradient(colors: [.yellow, .orange])
                )
                ShortcutButton(
                    title: "New Note",
                    icon: "note.text",
                    gradient: Gradient(colors: [.orange, .yellow]),
                    action: onNoteTap
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - OpenAppView (Second Sheet)

struct OpenAppView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Open App Sheet")
                .font(.title)
                .padding()

            Text("Imagine this is where you choose or open an app.")
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.yellow.opacity(0.2))
        .ignoresSafeArea()
    }
}

// MARK: - NoteView (Hidden Navigation Bar)

struct NoteView: View {
    var body: some View {
        VStack {
            Text("New Note")
                .font(.largeTitle)
                .padding()

            Text("Type your notes here...")
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green.opacity(0.2))
        .ignoresSafeArea()
    }
}

// MARK: - Reusable Components

/// A button used in the "Get Started" section
struct ShortcutButton: View {
    let title: String
    let icon: String
    let gradient: Gradient
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            )
        }
    }
}

/// A simple category button
struct CategoryButton: View {
    let title: String
    let icon: String

    var body: some View {
        Button {
            // Placeholder action
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(.gray.opacity(0.2))
            )
        }
        .foregroundStyle(.blue)
    }
}

/// A color box component
struct ColorBox: View {
    let color: Color
    let text: String

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).foregroundStyle(color))
    }
}

// MARK: - Custom Sheet Detents

struct OneSmallThanMaxDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue - 1
    }
}

struct CompactDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue * 0.1
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
