//
//  MinimalSearchBarView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/15/25.
//

import Foundation
import SwiftUI

struct MinimalSearchBarView: View {
    // MARK: - Properties

    /// The search text binding.
    @Binding var searchText: String

    /// The selected date to filter by.
    @Binding var selectedDate: Date?

    /// Whether this search bar is interactive.
    @Binding var isInteractive: Bool

    /// Action to trigger when the search text or date changes.
    var onFilterChanged: (() -> Void)?

    /// Animation states - keeping it but not using for visual shifts
    @State private var isSearchFocused = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            // Search icon with subtle animation (no scaling)
            Image(systemName: "magnifyingglass")
                .foregroundColor(isSearchFocused ? .gray.opacity(0.8) : .gray.opacity(0.6))
                .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                .padding(.leading, 12)

            // Text field with no position-changing animation
            if isInteractive {
                TextField("Search routes", text: $searchText)
                    .autocorrectionDisabled()
                    .padding(.vertical, 6)
                    .onTapGesture {
                        isSearchFocused = true
                    }
                    .onChange(of: searchText) { _, _ in
                        onFilterChanged?()
                    }
            } else {
                Text(searchText.isEmpty ? "Search routes" : searchText)
                    .foregroundColor(searchText.isEmpty ? .gray : .primary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            // Clear search button with improved animation
            if !searchText.isEmpty, isInteractive {
                Button {
                    searchText = ""
                    onFilterChanged?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6) // Added horizontal padding
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .animation(.easeInOut(duration: 0.2), value: !searchText.isEmpty)
            }
        }
        .padding(10) // Increased overall padding for a more comfortable tap target
        .background(
            // Neutral background with consistent shadow
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 3
                )
        )
        .overlay(
            // Subtle grey border that doesn't change color
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color.white.opacity(0.15),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            if !isInteractive {
                isInteractive = true
                isSearchFocused = true
            }
        }
    }
}

// MARK: - Preview

// MARK: - Previews

#Preview("Light Mode - Typing") {
    MinimalSearchBarPreview(
        searchText: "Running",
        selectedDate: nil,
        isInteractive: true
    )
    .preferredColorScheme(.light)
}

#Preview("Light Mode - Empty") {
    MinimalSearchBarPreview(
        searchText: "",
        selectedDate: nil,
        isInteractive: true
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode - Typing") {
    MinimalSearchBarPreview(
        searchText: "Swimming",
        selectedDate: nil,
        isInteractive: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark Mode - Empty") {
    MinimalSearchBarPreview(
        searchText: "",
        selectedDate: nil,
        isInteractive: true
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark Mode - Non-Interactive") {
    MinimalSearchBarPreview(
        searchText: "Cycling",
        selectedDate: nil,
        isInteractive: false
    )
    .preferredColorScheme(.dark)
}

// Extracted view for reuse in previews
private struct MinimalSearchBarPreview: View {
    @State var searchText: String
    @State var selectedDate: Date?
    @State var isInteractive: Bool

    var body: some View {
        MinimalSearchBarView(
            searchText: $searchText,
            selectedDate: $selectedDate,
            isInteractive: $isInteractive,
            onFilterChanged: {
                print("Filter changed: \(searchText), \(String(describing: selectedDate))")
            }
        )
        .padding()
        .background(Color(.systemBackground))
    }
}
