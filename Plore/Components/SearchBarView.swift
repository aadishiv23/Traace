//
//  SearchBarView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/11/25.
//

import SwiftUI

/// A reusable search bar. The `isInteractive` flag lets us disable typing
/// in the “compact” version but enable it in the “expanded” overlay.
import SwiftUI

/// An enhanced search bar with date selection functionality.
struct SearchBarView: View {
    // MARK: - Properties
    
    /// The search text binding.
    @Binding var searchText: String
    
    /// The selected date to filter by.
    @Binding var selectedDate: Date?
    
    /// Whether this search bar is interactive.
    let isInteractive: Bool
    
    /// Whether the date picker is showing.
    @State private var isShowingDatePicker = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            // Search icon and text field
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            if isInteractive {
                TextField("Search routes", text: $searchText)
                    .autocorrectionDisabled()
                    .padding(.vertical, 10)
            } else {
                Text(searchText.isEmpty ? "Search routes" : searchText)
                    .foregroundColor(searchText.isEmpty ? .gray : .primary)
                    .padding(.vertical, 10)
            }
            
            Spacer()
            
            // Date filtering
            dateFilterView
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $isShowingDatePicker) {
            datePicker
        }
    }
    
    // MARK: - Subviews
    
    /// The date filter view with either a calendar icon or the selected date.
    private var dateFilterView: some View {
        Button {
            if isInteractive {
                isShowingDatePicker = true
            }
        } label: {
            HStack(spacing: 4) {
                if let date = selectedDate {
                    // Show the selected date
                    Text(formattedShortDate(date))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Clear button
                    if isInteractive {
                        Button {
                            selectedDate = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 4)
                    }
                } else {
                    // Show calendar icon
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedDate != nil ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .disabled(!isInteractive)
    }
    
    /// The date picker sheet.
    private var datePicker: some View {
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
                
                Button("Clear Date") {
                    selectedDate = nil
                    isShowingDatePicker = false
                }
                .foregroundColor(.red)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isShowingDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats a date for the filter display.
    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchBarView(
                searchText: .constant(""),
                selectedDate: .constant(Date()), isInteractive: true
            )
            SearchBarView(
                searchText: .constant("Morning Run"),
                selectedDate: .constant(nil), isInteractive: true
            )
            Spacer()
        }
        .padding(.top)
        .background(Color(.systemBackground))
    }
}
