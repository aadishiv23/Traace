//
//  SearchOverlayView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 3/28/25.
//

import Foundation
import SwiftUI

struct SearchOverlayView: View {
    @Binding var isPresented: Bool
    @Binding var searchText: String
    @Binding var selectedDate: Date?
    @State private var tempDate = Date()

    var onDateChanged: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            // Background blur
            VisualEffectBlur(blurStyle: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                        onDismiss?()
                    }
                }

            VStack(spacing: 20) {
                // Top search + gear
                HStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search routes", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

                    Button(action: {
                        // Optionally add actions for settings
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)

                // Calendar date picker
                DatePicker("", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal)

                // Apply / Clear
                HStack(spacing: 20) {
                    Button("Clear") {
                        withAnimation {
                            selectedDate = nil
                            isPresented = false
                            onDismiss?()
                        }
                    }
                    .foregroundColor(.red)

                    Spacer()

                    Button("Apply") {
                        withAnimation {
                            selectedDate = tempDate
                            isPresented = false
                            onDateChanged?()
                        }
                    }
                    .fontWeight(.bold)
                }
                .padding(.horizontal)
            }
            .padding(.top, 60)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - VisualEffectBlur (for iOS 15+)

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
