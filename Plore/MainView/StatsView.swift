import SwiftUI
import HealthKit // For HKWorkoutActivityType
import MapKit // For MKPolyline, if ever needed here, though unlikely for pure stats

struct StatsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.routeColorTheme) private var routeColorTheme // Access theme for consistent colors

    // Pre-calculated stats
    private let aggregateStats: AggregateStatistics

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        self.aggregateStats = AggregateStatistics(routeInfos: healthKitManager.allRouteInfos)
    }
    
    private var currentRouteColors: (walking: Color, running: Color, cycling: Color) {
        RouteColors.colors(for: routeColorTheme)
    }

    var body: some View {
        NavigationStack {
            List {
                // Section for Overall Activity Totals
                Section {
                    OverallStatCard(
                        title: "Total Activity",
                        icon: "flame.fill",
                        accentColor: .pink,
                        items: [
                            .init(label: "Routes Tracked", value: "\(aggregateStats.totalRoutes)", icon: "number.circle.fill", iconColor: .pink.opacity(0.8)),
                            .init(label: "Walking Distance", value: formatDistance(aggregateStats.totalWalkingDistance), icon: "figure.walk.circle.fill", iconColor: currentRouteColors.walking),
                            .init(label: "Running Distance", value: formatDistance(aggregateStats.totalRunningDistance), icon: "figure.run.circle.fill", iconColor: currentRouteColors.running),
                            .init(label: "Cycling Distance", value: formatDistance(aggregateStats.totalCyclingDistance), icon: "figure.outdoor.cycle.circle.fill", iconColor: currentRouteColors.cycling)
                        ]
                    )
                } header: {
                    Text("Summary")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.leading)
                        .padding(.bottom, 5)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)


                // Section for Route Records
                Section {
                    if let route = aggregateStats.longestWalkingRoute {
                        RouteRecordCard(type: .walking, recordType: "Longest Walk", route: route)
                    }
                    if let route = aggregateStats.longestRunningRoute {
                        RouteRecordCard(type: .running, recordType: "Longest Run", route: route)
                    }
                    if let route = aggregateStats.longestCyclingRoute {
                        RouteRecordCard(type: .cycling, recordType: "Longest Cycle", route: route)
                    }
                     if aggregateStats.longestWalkingRoute == nil && aggregateStats.longestRunningRoute == nil && aggregateStats.longestCyclingRoute == nil {
                        ContentUnavailableView(
                           "No Route Records Yet",
                           systemImage: "figure.mixed.cardio",
                           description: Text("Once you record some routes, your longest distances will appear here.")
                       )
                       .padding(.vertical)
                    }
                } header: {
                     Text("Personal Records")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.leading)
                        .padding(.bottom, 5)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)

                // Placeholder for "Most Common Areas"
                Section {
                     ContentUnavailableView(
                        "Activity Hotspots",
                        systemImage: "map.magnifyingglass",
                        description: Text("Analysis of your most frequent workout locations is planned for a future update.")
                    )
                    .cornerRadius(12)
                    .padding(.vertical, 5)

                } header: {
                    Text("Future Features")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.leading)
                        .padding(.bottom, 5)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            }
            .listStyle(.grouped)
            .navigationTitle("Activity Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatDistance(_ distanceMeters: Double) -> String {
        let distanceMiles = distanceMeters / 1609.34
        if distanceMiles < 0.05 && distanceMiles > 0 { // Show ft for very short distances > 0
             let distanceFeet = distanceMeters * 3.28084
             return String(format: "%.0f ft", distanceFeet)
        }
        return String(format: "%.1f mi", distanceMiles)
    }
}

// MARK: - Data Structures for Stats

private struct AggregateStatistics {
    let totalWalkingDistance: Double
    let totalRunningDistance: Double
    let totalCyclingDistance: Double
    let totalRoutes: Int
    let longestWalkingRoute: RouteInfo?
    let longestRunningRoute: RouteInfo?
    let longestCyclingRoute: RouteInfo?

    init(routeInfos: [RouteInfo]) {
        var twd: Double = 0
        var trd: Double = 0
        var tcd: Double = 0
        
        var lwr: RouteInfo? = nil
        var lrr: RouteInfo? = nil
        var lcr: RouteInfo? = nil

        for route in routeInfos {
            let coords = route.polyline.coordinates()
            var distance: Double = 0
            if coords.count > 1 {
                for i in 0..<(coords.count - 1) {
                    let loc1 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
                    let loc2 = CLLocation(latitude: coords[i+1].latitude, longitude: coords[i+1].longitude)
                    distance += loc1.distance(from: loc2)
                }
            }
            
            switch route.type {
            case .walking:
                twd += distance
                if lwr == nil || distance > (lwr?.polyline.coordinates().reduce((0.0, nil as CLLocationCoordinate2D?)) { (res, coord) -> (Double, CLLocationCoordinate2D?) in
                    var cd = res.0
                    if let prevCoord = res.1 {
                        let loc1 = CLLocation(latitude: prevCoord.latitude, longitude: prevCoord.longitude)
                        let loc2 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                        cd += loc1.distance(from: loc2)
                    }
                    return (cd, coord)
                }.0 ?? 0) {
                    lwr = route
                }
            case .running:
                trd += distance
                if lrr == nil || distance > (lrr?.polyline.coordinates().reduce((0.0, nil as CLLocationCoordinate2D?)) { (res, coord) -> (Double, CLLocationCoordinate2D?) in
                    var cd = res.0
                    if let prevCoord = res.1 {
                        let loc1 = CLLocation(latitude: prevCoord.latitude, longitude: prevCoord.longitude)
                        let loc2 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                        cd += loc1.distance(from: loc2)
                    }
                    return (cd, coord)
                }.0 ?? 0) {
                    lrr = route
                }
            case .cycling:
                tcd += distance
                 if lcr == nil || distance > (lcr?.polyline.coordinates().reduce((0.0, nil as CLLocationCoordinate2D?)) { (res, coord) -> (Double, CLLocationCoordinate2D?) in
                    var cd = res.0
                    if let prevCoord = res.1 {
                        let loc1 = CLLocation(latitude: prevCoord.latitude, longitude: prevCoord.longitude)
                        let loc2 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                        cd += loc1.distance(from: loc2)
                    }
                    return (cd, coord)
                }.0 ?? 0) {
                    lcr = route
                }
            default:
                break
            }
        }
        
        self.totalWalkingDistance = twd
        self.totalRunningDistance = trd
        self.totalCyclingDistance = tcd
        self.longestWalkingRoute = lwr
        self.longestRunningRoute = lrr
        self.longestCyclingRoute = lcr
        self.totalRoutes = routeInfos.count
    }
}


// MARK: - Helper Views for StatsView

struct OverallStatCardItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String
    let iconColor: Color
}

struct OverallStatCard: View {
    let title: String
    let icon: String
    let accentColor: Color
    let items: [OverallStatCardItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.title2.weight(.semibold))
                Spacer()
            }
            
            ForEach(items) { item in
                HStack {
                    Image(systemName: item.icon)
                        .font(.headline)
                        .foregroundColor(item.iconColor)
                        .frame(width: 25, alignment: .center)
                    Text(item.label)
                        .font(.callout)
                    Spacer()
                    Text(item.value)
                        .font(.callout.weight(.medium))
                }
                if item.id != items.last?.id { // Add divider if not the last item
                   Divider().padding(.leading, 35)
                }
            }
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .cornerRadius(12)
    }
}


struct RouteRecordCard: View {
    let type: HKWorkoutActivityType
    let recordType: String
    let route: RouteInfo // Assumes RouteInfo is accessible and contains necessary details
    @Environment(\.routeColorTheme) private var routeColorTheme

    private var typeColor: Color {
        let colors = RouteColors.colors(for: routeColorTheme)
        switch type {
        case .walking: return colors.walking
        case .running: return colors.running
        case .cycling: return colors.cycling
        default: return .gray
        }
    }
    
    private var typeIcon: String {
        switch type {
        case .walking: "figure.walk.circle.fill"
        case .running: "figure.run.circle.fill"
        case .cycling: "figure.outdoor.cycle.circle.fill"
        default: "mappin.and.ellipse.circle.fill"
        }
    }
    
    private func formatDistance(_ distanceMeters: Double) -> String {
        let distanceMiles = distanceMeters / 1609.34
         if distanceMiles < 0.05 && distanceMiles > 0 {
             let distanceFeet = distanceMeters * 3.28084
             return String(format: "%.0f ft", distanceFeet)
        }
        return String(format: "%.1f mi", distanceMiles)
    }
    
    private var routeDistance: Double {
        let coords = route.polyline.coordinates()
        var distance: Double = 0
        if coords.count > 1 {
            for i in 0..<(coords.count - 1) {
                let loc1 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
                let loc2 = CLLocation(latitude: coords[i+1].latitude, longitude: coords[i+1].longitude)
                distance += loc1.distance(from: loc2)
            }
        }
        return distance
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: typeIcon)
                    .font(.title.weight(.semibold))
                    .foregroundColor(typeColor)
                Text(recordType)
                    .font(.title3.weight(.semibold))
                Spacer()
            }
            
            if let name = route.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(name)\"")
                    .font(.headline)
                    .italic()
                    .lineLimit(1)
            } else {
                Text("Unnamed Route")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .italic()
            }
            
            HStack(spacing: 15) {
                StatItem(icon: "arrow.left.and.right.circle.fill", value: formatDistance(routeDistance), color: typeColor)
                StatItem(icon: "calendar.circle.fill", value: route.date.formatted(date: .abbreviated, time: .omitted), color: typeColor)
            }
            .padding(.top, 2)
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

extension HealthKitManager { // Helper to get all routes easily
    var allRouteInfos: [RouteInfo] {
        walkingRouteInfos + runningRouteInfos + cyclingRouteInfos
    }
}

// Extension for MKPolyline to calculate its points (needed for distance calculation in Stats)
extension MKPolyline {
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}


#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock HealthKitManager
        let mockManager = HealthKitManager()
        
        // Create some mock RouteInfo data
        let P1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let P2 = CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4205)
        let P3 = CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4220)
        
        let coords1 = [P1, P2, P3].map { MKMapPoint($0) }
        let polyline1 = MKPolyline(points: coords1, count: coords1.count)
        
        let coords2 = [P2, P3].map { MKMapPoint($0) }
        let polyline2 = MKPolyline(points: coords2, count: coords2.count)

        mockManager.walkingRouteInfos = [
            RouteInfo(
                id: UUID(),
                name: "Morning Stroll",
                type: .walking,
                date: Date().addingTimeInterval(-86400*2),
                locations: [
                    CLLocation(
                        latitude: P1.latitude,
                        longitude: P1.longitude
                    ),
                    CLLocation(latitude: P2.latitude, longitude: P2.longitude)
                ]
            )
        ]
        mockManager.runningRouteInfos = [
            RouteInfo(id: UUID(), name: "Park Run", type: .running, date: Date().addingTimeInterval(-86400), locations: [CLLocation(latitude: P2.latitude, longitude: P2.longitude), CLLocation(latitude: P3.latitude, longitude: P3.longitude)])
        ]
         mockManager.cyclingRouteInfos = []


        return StatsView(healthKitManager: mockManager)
            .environment(\.routeColorTheme, .vibrant)
    }
}
#endif 
