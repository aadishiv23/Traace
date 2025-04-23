//
//  CustomColorPicker.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/22/25.
//

import Foundation
import SwiftUI
import MapKit

struct CustomColorPickerView: View {
    @Binding var selectedTheme: RouteColorTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Custom colors with defaults from vibrant theme
    @State private var walkingColor: Color
    @State private var runningColor: Color
    @State private var cyclingColor: Color
    
    // For persistence
    @AppStorage("customWalkingColor") private var storedWalkingColor: String = "#00B4FF"
    @AppStorage("customRunningColor") private var storedRunningColor: String = "#FF4B4B"
    @AppStorage("customCyclingColor") private var storedCyclingColor: String = "#4BFF7A"
    
    init(selectedTheme: Binding<RouteColorTheme>) {
        self._selectedTheme = selectedTheme
        
        // Initialize with stored values or defaults
        _walkingColor = State(initialValue: Color(hex: UserDefaults.standard.string(forKey: "customWalkingColor") ?? "#00B4FF"))
        _runningColor = State(initialValue: Color(hex: UserDefaults.standard.string(forKey: "customRunningColor") ?? "#FF4B4B"))
        _cyclingColor = State(initialValue: Color(hex: UserDefaults.standard.string(forKey: "customCyclingColor") ?? "#4BFF7A"))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 10) {
                Text("Custom Route Colors")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose your own colors for each route type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Map Preview
            customMapPreview
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)
            
            // Color pickers
            VStack(spacing: 20) {
                colorPickerRow(title: "Walking Routes", icon: "figure.walk", color: $walkingColor)
                colorPickerRow(title: "Running Routes", icon: "figure.run", color: $runningColor)
                colorPickerRow(title: "Cycling Routes", icon: "figure.outdoor.cycle", color: $cyclingColor)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Save Button
            Button(action: saveCustomColors) {
                Text("Save Custom Theme")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: walkingColor) { updatePreview() }
        .onChange(of: runningColor) { updatePreview() }
        .onChange(of: cyclingColor) { updatePreview() }
    }
    
    // Custom map preview with current colors
    private var customMapPreview: some View {
        ZStack {
            // Map
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))) {
                // Walking route
                MapPolyline(walkingPolyline)
                    .stroke(walkingColor, lineWidth: 4)
                
                // Running route
                MapPolyline(runningPolyline)
                    .stroke(runningColor, lineWidth: 4)
                
                // Cycling route
                MapPolyline(cyclingPolyline)
                    .stroke(cyclingColor, lineWidth: 4)
            }
            .disabled(true)
            
            // Legend
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(walkingColor).frame(width: 8, height: 8)
                    Text("Walking").font(.system(size: 10)).foregroundColor(.white).shadow(radius: 1)
                }
                HStack(spacing: 6) {
                    Circle().fill(runningColor).frame(width: 8, height: 8)
                    Text("Running").font(.system(size: 10)).foregroundColor(.white).shadow(radius: 1)
                }
                HStack(spacing: 6) {
                    Circle().fill(cyclingColor).frame(width: 8, height: 8)
                    Text("Cycling").font(.system(size: 10)).foregroundColor(.white).shadow(radius: 1)
                }
            }
            .padding(6)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
    
    // Color picker row with icon and title
    private func colorPickerRow(title: String, icon: String, color: Binding<Color>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color.wrappedValue)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            // Color picker with preview
            ColorPicker("", selection: color)
                .labelsHidden()
            
            // Color preview
            RoundedRectangle(cornerRadius: 6)
                .fill(color.wrappedValue)
                .frame(width: 30, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // Save custom colors and update theme
    private func saveCustomColors() {
        // Save colors to UserDefaults
        storedWalkingColor = walkingColor.toHex()
        storedRunningColor = runningColor.toHex()
        storedCyclingColor = cyclingColor.toHex()
        
        // Set theme to custom
        selectedTheme = .custom
        
        // Dismiss the sheet
        dismiss()
    }
    
    // Update preview colors (for live preview)
    private func updatePreview() {
        // Nothing needed here - the preview updates automatically due to state changes
    }
    
    // Sample polylines
    private var walkingPolyline: MKPolyline {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.776, longitude: -122.419),
            CLLocationCoordinate2D(latitude: 37.775, longitude: -122.418),
            CLLocationCoordinate2D(latitude: 37.774, longitude: -122.416),
            CLLocationCoordinate2D(latitude: 37.773, longitude: -122.415)
        ]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    private var runningPolyline: MKPolyline {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.778, longitude: -122.421),
            CLLocationCoordinate2D(latitude: 37.776, longitude: -122.422),
            CLLocationCoordinate2D(latitude: 37.774, longitude: -122.421),
            CLLocationCoordinate2D(latitude: 37.773, longitude: -122.419)
        ]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    private var cyclingPolyline: MKPolyline {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.774, longitude: -122.422),
            CLLocationCoordinate2D(latitude: 37.776, longitude: -122.424),
            CLLocationCoordinate2D(latitude: 37.778, longitude: -122.423),
            CLLocationCoordinate2D(latitude: 37.780, longitude: -122.421),
            CLLocationCoordinate2D(latitude: 37.779, longitude: -122.418)
        ]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

#if DEBUG
struct CustomColorPickerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CustomColorPickerView(selectedTheme: .constant(.custom))
        }
    }
}
#endif
