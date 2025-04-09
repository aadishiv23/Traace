//
//  ImprovedSearchBarView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/8/25.
//

import Foundation
import SwiftUI

/// An elegant search bar with date selection and filtering capabilities.
///
/// This component provides a clean interface for searching routes by name or date,
/// and automatically filters route data based on user input.
///
/// - Parameters:
///   - searchText: A binding to the search text
///   - selectedDate: A binding to the optional selected date for filtering
///   - isInteractive: Whether this search bar is in interactive mode
///
struct ImprovedSearchBarView: View {
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

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main search bar
            HStack(spacing: 8) {
                // Search icon and text field
                Image(systemName: "magnifyingglass")
                    .foregroundColor(searchText.isEmpty ? .gray : .blue)
                    .padding(.leading, 12)

                if isInteractive {
                    TextField("Search routes", text: $searchText)
                        .autocorrectionDisabled()
                        .padding(.vertical, 12)
                        .onChange(of: searchText) { _, _ in
                            // Trigger filter update when search text changes
                            onFilterChanged?()
                        }
                } else {
                    Text(searchText.isEmpty ? "Search routes" : searchText)
                        .foregroundColor(searchText.isEmpty ? .gray : .primary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // Clear search button
                if !searchText.isEmpty, isInteractive {
                    Button {
                        searchText = ""
                        onFilterChanged?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 4)
                    }
                }

                // Date filtering
                dateFilterButton
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(searchText.isEmpty ? Color.gray.opacity(0.2) : Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $isShowingDatePicker) {
            datePicker
        }
    }

    // MARK: - Subviews

    /// The date filter button showing either a calendar icon or the selected date.
    private var dateFilterButton: some View {
        Button {
            if isInteractive {
                isShowingDatePicker = true
            }
        } label: {
            HStack(spacing: 4) {
                if let date = selectedDate {
                    // Show the selected date with highlight
                    HStack(spacing: 4) {
                        Text(formattedShortDate(date))
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        // Clear date button
                        if isInteractive {
                            Button {
                                selectedDate = nil
                                onFilterChanged?()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.trailing, 4)
                } else {
                    // Show calendar icon
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .padding(.trailing, 12)
                }
            }
        }
        .disabled(!isInteractive)
        .buttonStyle(PlainButtonStyle())
    }

    /// The date picker sheet with a calendar view.
    private var datePicker: some View {
        NavigationView {
            VStack {
                // Calendar date picker
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

                // Clear date button
                Button(action: {
                    selectedDate = nil
                    isShowingDatePicker = false
                    onFilterChanged?()
                }) {
                    Text("Clear Date")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingDatePicker = false
                        onFilterChanged?()
                    } label: {
                        Text("Done")
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Formats a date for the filter display.
    /// - Parameter date: The date to format
    /// - Returns: A string representation of the date in medium style
    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview Provider

#Preview {
    VStack(spacing: 20) {
        // Compact, non-interactive mode
        ImprovedSearchBarView(
            searchText: .constant(""),
            selectedDate: .constant(nil),
            isInteractive: .constant(false)
        )

        // Interactive mode with text
        ImprovedSearchBarView(
            searchText: .constant("Morning Run"),
            selectedDate: .constant(nil),
            isInteractive: .constant(true)
        )

        // Interactive mode with date
        ImprovedSearchBarView(
            searchText: .constant(""),
            selectedDate: .constant(Date()),
            isInteractive: .constant(true)
        )

        // Interactive mode with both text and date
        ImprovedSearchBarView(
            searchText: .constant("Park Run"),
            selectedDate: .constant(Date()),
            isInteractive: .constant(true)
        )

        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}
