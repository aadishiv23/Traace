//
//  SearchBarView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/11/25.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedDate: Date?

    @State private var showDatePicker = false
    @State private var tempDate = Date()

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search routes", text: $searchText)
                        .font(.system(size: 16))

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
        .padding(.horizontal)
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
                selectedDate: .constant(Date())
            )
            SearchBarView(
                searchText: .constant("Morning Run"),
                selectedDate: .constant(nil)
            )
            Spacer()
        }
        .padding(.top)
        .background(Color(.systemBackground))
    }
}
