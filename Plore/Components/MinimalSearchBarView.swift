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
    
    /// Whether the date picker is showing.
    @State private var isShowingDatePicker = false
    
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
                    .padding(.vertical, 12)
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
            
            // Better date filter button with more padding
            if isInteractive {
                Button {
                    isShowingDatePicker = true
                } label: {
                    Image(systemName: selectedDate == nil ? "calendar" : "calendar.badge.clock")
                        .foregroundColor(selectedDate == nil ? .gray : .primary)
                        .padding(.horizontal, 10) // Added more horizontal padding
                        .padding(.vertical, 6)    // Added vertical padding
                        .contentTransition(.symbolEffect(.replace))
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: selectedDate != nil)
            }
        }
        .padding(6) // Increased overall padding for a more comfortable tap target
        .background(
            // Neutral background with consistent shadow
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 3,
                    x: 0,
                    y: 1
                )
        )
        .overlay(
            // Subtle grey border that doesn't change color
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color.gray.opacity(0.15),
                    lineWidth: 1
                )
        )
        // No scale effect animation to prevent shifting
        .sheet(isPresented: $isShowingDatePicker) {
            simpleDatePicker
        }
        .onTapGesture {
            if !isInteractive {
                isInteractive = true
                isSearchFocused = true
            }
        }
    }
    
    // MARK: - Subviews
    
    /// A simplified date picker sheet
    private var simpleDatePicker: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                HStack(spacing: 20) {
                    // Clear button with improved appearance
                    Button(action: {
                        selectedDate = nil
                        isShowingDatePicker = false
                        onFilterChanged?()
                    }) {
                        Text("Clear")
                            .fontWeight(.medium)
                            .foregroundColor(.primary.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // Increased padding
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                            )
                    }
                    
                    // Apply button with improved appearance
                    Button(action: {
                        isShowingDatePicker = false
                        onFilterChanged?()
                    }) {
                        Text("Apply")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // Increased padding
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary.opacity(0.8)) // Using primary instead of blue
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30) // Added more bottom padding
                
                Spacer()
            }
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
