//
//  SearchBarView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/11/25.
//

import SwiftUI

/// A reusable search bar. The `isInteractive` flag lets us disable typing
/// in the “compact” version but enable it in the “expanded” overlay.
struct SearchBarView: View {

    /// The string passed in as the search variable.
    @Binding var searchText: String

    /// The date passed in as the optional search var.
    @Binding var selectedDate: Date?

    /// Whether the user can actually type here (in the search overlay).
    var isInteractive: Bool

    @State private var showDatePicker = false
    @State private var tempDate = Date()

    /// Focus state for the text field
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search routes", text: $searchText)
                        .font(.system(size: 16))
                        .disabled(isInteractive)
                        .focused($textFieldFocused)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(4)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )

                // Date filter button
                Button(action: {
                    tempDate = selectedDate ?? Date()
                    showDatePicker.toggle()
                }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedDate != nil ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                }
                .disabled(isInteractive)
            }

            // Date filter chips (only shown when date is selected)
            if let date = selectedDate {
                HStack {
                    Spacer()

                    Text("Filtered by: ")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 14, weight: .medium))

                        Button(action: {
                            selectedDate = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: selectedDate)
        .onAppear {
            if isInteractive {
                // A slight delay allows the overlay transition to complete.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    textFieldFocused = true
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack(spacing: 20) {
                HStack {
                    Button("Cancel") {
                        showDatePicker = false
                    }

                    Spacer()

                    Text("Filter by Date")
                        .font(.headline)

                    Spacer()

                    Button("Apply") {
                        selectedDate = tempDate
                        showDatePicker = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)

                DatePicker("", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal)

                Button(action: {
                    selectedDate = nil
                    showDatePicker = false
                }) {
                    Text("Clear Filter")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .presentationDetents([.height(500)])
            .presentationCornerRadius(20)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
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
