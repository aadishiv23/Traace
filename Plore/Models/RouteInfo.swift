//
//  RouteInfo.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 3/24/25.
//

import CoreLocation
import Foundation
import HealthKit
import MapKit

/// A lightweight model to hold a route's type, date, and location (plus computed polyline).
struct RouteInfo: Identifiable, Equatable {
    /// An identifier for this `RouteInfo` instance.
    var id = UUID()

    /// The name of this route. Optional, as some routes may not have names initially.
    var name: String?

    /// The type of this workout: Running, Walking, or Cycling.
    var type: HKWorkoutActivityType

    /// The date the activity occured.
    var date: Date

    /// A list of location points representing the route taken during the activity.
    var locations: [CLLocation]

    /// A visual representation of the route.
    var polyline: MKPolyline {
        let coordinates = locations.map(\.coordinate)
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}
