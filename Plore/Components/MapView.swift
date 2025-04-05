//
//  MapView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import SwiftUI
import MapKit
import HealthKit

/// A SwiftUI view that displays a map with route polylines
struct MapView: View {
    // MARK: - Properties
    
    /// The routes to display on the map
    let routes: [WorkoutRoute]
    
    /// Binding to the map's region
    @Binding var region: MKCoordinateRegion
    
    /// Optional binding to track when the map is interacting with user gestures
    @Binding var isInteracting: Bool
    
    /// The map type (standard, satellite, hybrid)
    let mapType: MKMapType
    
    // MARK: - Initialization
    
    /// Initializes a new MapView
    /// - Parameters:
    ///   - routes: The routes to display
    ///   - region: Binding to the map region
    ///   - isInteracting: Optional binding to track user interaction with the map
    ///   - mapType: The map type to display (defaults to standard)
    init(routes: [WorkoutRoute], 
         region: Binding<MKCoordinateRegion>,
         isInteracting: Binding<Bool> = .constant(false),
         mapType: MKMapType = .standard) {
        self.routes = routes
        self._region = region
        self._isInteracting = isInteracting
        self.mapType = mapType
    }
    
    // MARK: - Body
    
    var body: some View {
        Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: nil, annotationItems: []) { _ in
            // No annotations for now
        }
        .overlay {
            MapOverlay(routes: routes)
        }
        .onChange(of: region) { _, _ in
            // When region changes from user interaction, update isInteracting
            isInteracting = true
        }
        .mapStyle(mapType == .standard ? .standard : (mapType == .satellite ? .imagery : .hybrid))
    }
}

/// A UIViewRepresentable that displays route polylines on the map
struct MapOverlay: UIViewRepresentable {
    let routes: [WorkoutRoute]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add route polylines
        for route in routes {
            if let polyline = route.polyline {
                mapView.addOverlay(polyline)
            }
        }
        
        // Update the coordinator's routes
        context.coordinator.routes = routes
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(routes: routes)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var routes: [WorkoutRoute]
        
        init(routes: [WorkoutRoute]) {
            self.routes = routes
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Find the corresponding route
                if let route = routes.first(where: { $0.polyline === polyline }) {
                    // Set color based on activity type
                    let color: UIColor
                    switch route.workoutActivityType {
                    case .walking, .hiking:
                        color = UIColor.systemBlue
                    case .running:
                        color = UIColor.systemRed
                    case .cycling:
                        color = UIColor.systemGreen
                    default:
                        color = UIColor.gray
                    }
                    
                    renderer.strokeColor = color
                    renderer.lineWidth = 4
                    renderer.lineCap = .round
                    renderer.lineJoin = .round
                    renderer.alpha = 0.8
                    
                    return renderer
                }
                
                // Default fallback
                renderer.strokeColor = UIColor.purple
                renderer.lineWidth = 3
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#if DEBUG
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(
            routes: [],
            region: .constant(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        )
    }
}
#endif 