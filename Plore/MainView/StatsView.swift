import Charts
import HealthKit // For HKWorkoutActivityType
import MapKit // For MKPolyline, if ever needed here, though unlikely for pure stats
import SwiftUI

struct StatsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.routeColorTheme) private var routeColorTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @State private var animateOnAppear = false
    @State private var timeframeSelection = 0 // 0 = weekly, 1 = monthly

    /// Pre-calculated stats
    private let aggregateStats: AggregateStatistics

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        aggregateStats = AggregateStatistics(routeInfos: healthKitManager.allRouteInfos)
    }

    private var currentRouteColors: (walking: Color, running: Color, cycling: Color) {
        RouteColors.colors(for: routeColorTheme)
    }

    private var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [
                colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.7),
                colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Activity Summary Card
                    ActivitySummaryCard(aggregateStats: aggregateStats, colors: currentRouteColors)
                        .padding(.horizontal)
                        .offset(y: animateOnAppear ? 0 : 30)
                        .opacity(animateOnAppear ? 1 : 0)

                    // Activity Distribution Chart
                    VStack(alignment: .leading) {
                        Label("Activity Distribution", systemImage: "chart.pie.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.indigo)
                            .padding(.horizontal)
                            .padding(.top)

                        ImprovedActivityDistributionChart(
                            walkingDistance: aggregateStats.totalWalkingDistance,
                            runningDistance: aggregateStats.totalRunningDistance,
                            cyclingDistance: aggregateStats.totalCyclingDistance,
                            colors: currentRouteColors
                        )
                        .frame(height: 220)
                        .padding(.horizontal)
                    }
                    .background(Material.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .offset(y: animateOnAppear ? 0 : 30)
                    .opacity(animateOnAppear ? 1 : 0.2)

                    // Time-based Activity Chart
                    VStack(alignment: .leading) {
                        Label("Activity Timeline", systemImage: "chart.xyaxis.line")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.teal)
                            .padding(.horizontal)
                            .padding(.top)

                        Picker("Timeframe", selection: $timeframeSelection) {
                            Text("Weekly").tag(0)
                            Text("Monthly").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        TimeBasedActivityChart(
                            routeInfos: healthKitManager.allRouteInfos,
                            isMonthly: timeframeSelection == 1,
                            colors: currentRouteColors
                        )
                        .frame(height: 220)
                        .padding()
                    }
                    .background(Material.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .offset(y: animateOnAppear ? 0 : 30)
                    .opacity(animateOnAppear ? 1 : 0.2)

                    // Personal Records Section
                    PersonalRecordsSection(
                        aggregateStats: aggregateStats,
                        colors: currentRouteColors
                    )
                    .offset(y: animateOnAppear ? 0 : 30)
                    .opacity(animateOnAppear ? 1 : 0)

                    // Future Features Card
                    FutureFeaturesCard()
                        .padding(.horizontal)
                        .offset(y: animateOnAppear ? 0 : 30)
                        .opacity(animateOnAppear ? 1 : 0)
                }
                .padding(.vertical)
            }
            .background(gradientBackground)
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
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateOnAppear = true
                }
            }
        }
    }
}

// MARK: - Activity Summary Card

struct ActivitySummaryCard: View {
    let aggregateStats: AggregateStatistics
    let colors: (walking: Color, running: Color, cycling: Color)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Activity Summary", systemImage: "flame.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.pink)
                Spacer()
                Text("\(aggregateStats.totalRoutes)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.pink.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            // Activities Row
            HStack(spacing: 20) {
                ActivityStatItem(
                    icon: "figure.walk.circle.fill",
                    value: formatDistance(aggregateStats.totalWalkingDistance),
                    title: "Walking",
                    color: colors.walking
                )

                Divider()

                ActivityStatItem(
                    icon: "figure.run.circle.fill",
                    value: formatDistance(aggregateStats.totalRunningDistance),
                    title: "Running",
                    color: colors.running
                )

                Divider()

                ActivityStatItem(
                    icon: "figure.outdoor.cycle.circle.fill",
                    value: formatDistance(aggregateStats.totalCyclingDistance),
                    title: "Cycling",
                    color: colors.cycling
                )
            }
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func formatDistance(_ distanceMeters: Double) -> String {
        let distanceMiles = distanceMeters / 1609.34
        if distanceMiles < 0.05, distanceMiles > 0 {
            let distanceFeet = distanceMeters * 3.28084
            return String(format: "%.0f ft", distanceFeet)
        }
        return String(format: "%.1f mi", distanceMiles)
    }
}

struct ActivityStatItem: View {
    let icon: String
    let value: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Improved Activity Distribution Chart

struct ImprovedActivityDistributionChart: View {
    let walkingDistance: Double
    let runningDistance: Double
    let cyclingDistance: Double
    let colors: (walking: Color, running: Color, cycling: Color)
    @State private var selectedActivity: String? = nil
    @State private var animateChart = false

    var body: some View {
        VStack {
            if totalDistance > 0 {
                ZStack {
                    // Chart
                    Chart {
                        SectorMark(
                            angle: .value("Walking", animateChart ? walkingDistance : 0.01),
                            innerRadius: .ratio(0.618),
                            angularInset: 2
                        )
                        .foregroundStyle(colors.walking.gradient)
                        .opacity(selectedActivity == nil || selectedActivity == "Walking" ? 1 : 0.4)
                        .cornerRadius(6)
                        .annotation(position: .overlay) {
                            if walkingPercent > 0.15 {
                                Text("\(Int(walkingPercent * 100))%")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .opacity(animateChart ? 1 : 0)
                            }
                        }

                        SectorMark(
                            angle: .value("Running", animateChart ? runningDistance : 0.01),
                            innerRadius: .ratio(0.618),
                            angularInset: 2
                        )
                        .foregroundStyle(colors.running.gradient)
                        .opacity(selectedActivity == nil || selectedActivity == "Running" ? 1 : 0.4)
                        .cornerRadius(6)
                        .annotation(position: .overlay) {
                            if runningPercent > 0.15 {
                                Text("\(Int(runningPercent * 100))%")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .opacity(animateChart ? 1 : 0)
                            }
                        }

                        SectorMark(
                            angle: .value("Cycling", animateChart ? cyclingDistance : 0.01),
                            innerRadius: .ratio(0.618),
                            angularInset: 2
                        )
                        .foregroundStyle(colors.cycling.gradient)
                        .opacity(selectedActivity == nil || selectedActivity == "Cycling" ? 1 : 0.4)
                        .cornerRadius(6)
                        .annotation(position: .overlay) {
                            if cyclingPercent > 0.15 {
                                Text("\(Int(cyclingPercent * 100))%")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .opacity(animateChart ? 1 : 0)
                            }
                        }
                    }
                    .chartLegend(position: .bottom, alignment: .center, spacing: 20) {
                        HStack(spacing: 24) {
                            LegendItem(
                                color: colors.walking,
                                label: "Walking",
                                value: formatDistance(walkingDistance),
                                isSelected: selectedActivity == "Walking",
                                action: { toggleSelection("Walking") }
                            )
                            LegendItem(
                                color: colors.running,
                                label: "Running",
                                value: formatDistance(runningDistance),
                                isSelected: selectedActivity == "Running",
                                action: { toggleSelection("Running") }
                            )
                            LegendItem(
                                color: colors.cycling,
                                label: "Cycling",
                                value: formatDistance(cyclingDistance),
                                isSelected: selectedActivity == "Cycling",
                                action: { toggleSelection("Cycling") }
                            )
                        }
                    }

                    // Center text
                    VStack(spacing: 2) {
                        Text(selectedActivity ?? "Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(
                            selectedActivity == nil
                                ? formatDistance(totalDistance)
                                : selectedActivity == "Walking" ? formatDistance(walkingDistance) :
                                selectedActivity == "Running" ? formatDistance(runningDistance) :
                                formatDistance(cyclingDistance)
                        )
                        .font(.headline.bold())
                    }
                }
                .padding(.vertical)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        animateChart = true
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Activity Data",
                    systemImage: "chart.pie",
                    description: Text("Start recording routes to see your activity distribution")
                )
                .padding()
            }
        }
    }

    private func toggleSelection(_ activity: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if selectedActivity == activity {
                selectedActivity = nil
            } else {
                selectedActivity = activity
            }
        }
    }

    private var walkingPercent: Double {
        totalDistance > 0 ? walkingDistance / totalDistance : 0
    }

    private var runningPercent: Double {
        totalDistance > 0 ? runningDistance / totalDistance : 0
    }

    private var cyclingPercent: Double {
        totalDistance > 0 ? cyclingDistance / totalDistance : 0
    }

    private var totalDistance: Double {
        walkingDistance + runningDistance + cyclingDistance
    }

    private func formatDistance(_ distanceMeters: Double) -> String {
        let distanceMiles = distanceMeters / 1609.34
        if distanceMiles < 0.05, distanceMiles > 0 {
            let distanceFeet = distanceMeters * 3.28084
            return String(format: "%.0f ft", distanceFeet)
        }
        return String(format: "%.1f mi", distanceMiles)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .fontWeight(isSelected ? .bold : .regular)

                    Text(value)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isSelected ? color.opacity(0.1) : .clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time-based Activity Chart

struct TimeBasedActivityChart: View {
    let routeInfos: [RouteInfo]
    let isMonthly: Bool
    let colors: (walking: Color, running: Color, cycling: Color)
    @State private var animateChart = false

    private var chartData: [TimeframeData] {
        isMonthly ? monthlyData : weeklyData
    }

    private var weeklyData: [TimeframeData] {
        // Get current calendar week number
        let calendar = Calendar.current
        let currentDate = Date()
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yy"

        // Create data for last 4 weeks
        var data: [TimeframeData] = []

        for weekOffset in 0 ..< 12 {
            guard let weekStartDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentDate),
                  let weekStart = calendar.date(from: calendar.dateComponents(
                      [.yearForWeekOfYear, .weekOfYear],
                      from: weekStartDate
                  ))
            else {
                continue
            }
            let weekNumber = calendar.component(.weekOfYear, from: weekStart)
            let yearForWeek = calendar.component(.yearForWeekOfYear, from: weekStart)
            let weekLabel = "W\(weekNumber) '\(yearFormatter.string(from: weekStart))"

            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()

            let weekRoutes = routeInfos.filter {
                $0.date >= weekStart && $0.date < weekEnd
            }

            // Calculate distances
            var walkingDistance: Double = 0
            var runningDistance: Double = 0
            var cyclingDistance: Double = 0

            for route in weekRoutes {
                let distance = calculateRouteDistance(route)

                switch route.type {
                case .walking: walkingDistance += distance
                case .running: runningDistance += distance
                case .cycling: cyclingDistance += distance
                default: break
                }
            }

            data.append(TimeframeData(
                label: weekLabel,
                walking: walkingDistance,
                running: runningDistance,
                cycling: cyclingDistance
            ))
        }

        return data.reversed() // Show oldest to newest
    }

    private var monthlyData: [TimeframeData] {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yy"

        var data: [TimeframeData] = []

        for monthOffset in 0 ..< 12 {
            guard let targetDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate),
                  let monthStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: targetDate))
            else {
                continue
            }

            let monthLabel =
                "\(monthFormatter.string(from: monthStartDate)) '\(yearFormatter.string(from: monthStartDate))"

            let monthComponent = calendar.component(.month, from: monthStartDate)
            let yearComponent = calendar.component(.year, from: monthStartDate)

            let monthRoutes = routeInfos.filter {
                let routeMonth = calendar.component(.month, from: $0.date)
                let routeYear = calendar.component(.year, from: $0.date)
                return routeMonth == monthComponent && routeYear == yearComponent
            }

            // Calculate distances
            var walkingDistance: Double = 0
            var runningDistance: Double = 0
            var cyclingDistance: Double = 0

            for route in monthRoutes {
                let distance = calculateRouteDistance(route)

                switch route.type {
                case .walking: walkingDistance += distance
                case .running: runningDistance += distance
                case .cycling: cyclingDistance += distance
                default: break
                }
            }

            data.append(TimeframeData(
                label: monthLabel,
                walking: walkingDistance,
                running: runningDistance,
                cycling: cyclingDistance
            ))
        }

        return data.reversed() // Show oldest to newest
    }

    private func calculateRouteDistance(_ route: RouteInfo) -> Double {
        let coords = route.polyline.coordinates()
        var distance: Double = 0

        if coords.count > 1 {
            for i in 0 ..< (coords.count - 1) {
                let loc1 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
                let loc2 = CLLocation(latitude: coords[i + 1].latitude, longitude: coords[i + 1].longitude)
                distance += loc1.distance(from: loc2)
            }
        }

        return distance
    }

    var body: some View {
        if chartData.isEmpty || (chartData.allSatisfy { $0.walking + $0.running + $0.cycling == 0 }) {
            ContentUnavailableView(
                "No Activity Timeline",
                systemImage: "chart.xyaxis.line",
                description: Text("Start recording routes to see your activity over time")
            )
            .padding()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                    ForEach(chartData) { dataPoint in
                        BarMark(
                            x: .value("Time", dataPoint.label),
                            y: .value("Walking", animateChart ? dataPoint.walking / 1609.34 : 0),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(colors.walking.gradient)
                        .position(by: .value("Activity", "Walking"))

                        BarMark(
                            x: .value("Time", dataPoint.label),
                            y: .value("Running", animateChart ? dataPoint.running / 1609.34 : 0),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(colors.running.gradient)
                        .position(by: .value("Activity", "Running"))

                        BarMark(
                            x: .value("Time", dataPoint.label),
                            y: .value("Cycling", animateChart ? dataPoint.cycling / 1609.34 : 0),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(colors.cycling.gradient)
                        .position(by: .value("Activity", "Cycling"))
                    }
                }
                .chartXAxis {
                    AxisMarks(preset: .aligned)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let distance = value.as(Double.self) {
                                Text("\(distance, specifier: "%.1f") mi")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom)
                .chartYScale(domain: .automatic(includesZero: true))
                .padding(.horizontal)
                .frame(minWidth: CGFloat(chartData.count) * 60)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animateChart = true
                    }
                }
            }
        }
    }
}

struct TimeframeData: Identifiable {
    let id = UUID()
    let label: String
    let walking: Double
    let running: Double
    let cycling: Double
}

// MARK: - Personal Records Section

struct PersonalRecordsSection: View {
    let aggregateStats: AggregateStatistics
    let colors: (walking: Color, running: Color, cycling: Color)
    @Environment(\.routeColorTheme) private var routeColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            Label("Personal Records", systemImage: "trophy.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal)

            if hasRecords {
                TabView {
                    if let route = aggregateStats.longestWalkingRoute {
                        PersonalRecordCard(
                            type: .walking,
                            recordType: "Longest Walk",
                            route: route,
                            color: colors.walking
                        )
                        .padding(.horizontal)
                    }

                    if let route = aggregateStats.longestRunningRoute {
                        PersonalRecordCard(
                            type: .running,
                            recordType: "Longest Run",
                            route: route,
                            color: colors.running
                        )
                        .padding(.horizontal)
                    }

                    if let route = aggregateStats.longestCyclingRoute {
                        PersonalRecordCard(
                            type: .cycling,
                            recordType: "Longest Cycle",
                            route: route,
                            color: colors.cycling
                        )
                        .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 200)
            } else {
                ContentUnavailableView(
                    "No Route Records Yet",
                    systemImage: "figure.mixed.cardio",
                    description: Text("Once you record some routes, your longest distances will appear here.")
                )
                .padding(.vertical)
            }
        }
    }

    private var hasRecords: Bool {
        aggregateStats.longestWalkingRoute != nil ||
            aggregateStats.longestRunningRoute != nil ||
            aggregateStats.longestCyclingRoute != nil
    }
}

struct PersonalRecordCard: View {
    let type: HKWorkoutActivityType
    let recordType: String
    let route: RouteInfo
    let color: Color

    private var typeIcon: String {
        switch type {
        case .walking: "figure.walk.circle.fill"
        case .running: "figure.run.circle.fill"
        case .cycling: "figure.outdoor.cycle.circle.fill"
        default: "mappin.and.ellipse.circle.fill"
        }
    }

    private var routeDistance: Double {
        let coords = route.polyline.coordinates()
        var distance: Double = 0
        if coords.count > 1 {
            for i in 0 ..< (coords.count - 1) {
                let loc1 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
                let loc2 = CLLocation(latitude: coords[i + 1].latitude, longitude: coords[i + 1].longitude)
                distance += loc1.distance(from: loc2)
            }
        }
        return distance
    }

    private func formatDistance(_ distanceMeters: Double) -> String {
        let distanceMiles = distanceMeters / 1609.34
        if distanceMiles < 0.05, distanceMiles > 0 {
            let distanceFeet = distanceMeters * 3.28084
            return String(format: "%.0f ft", distanceFeet)
        }
        return String(format: "%.1f mi", distanceMiles)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: typeIcon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(recordType)
                    .font(.title3.weight(.semibold))

                Spacer()

                Text(formatDistance(routeDistance))
                    .font(.headline.weight(.heavy))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }

            if let name = route.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\"\(name)\"")
                    .font(.headline)
                    .italic()
                    .lineLimit(1)
            } else {
                Text("Unnamed Route")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            HStack {
                Label(route.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
//        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 3)
        )
    }
}

// MARK: - Future Features Card

struct FutureFeaturesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Coming Soon", systemImage: "sparkles")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.purple)

            HStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .font(.title)
                        .foregroundStyle(.purple.opacity(0.8))

                    Text("Activity Hotspots")
                        .font(.callout.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundStyle(.teal.opacity(0.8))

                    Text("Pace Analytics")
                        .font(.callout.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.title)
                        .foregroundStyle(.orange.opacity(0.8))

                    Text("Goal Tracking")
                        .font(.callout.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Data Structures for Stats

struct AggregateStatistics {
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

        var lwr: RouteInfo?
        var lrr: RouteInfo?
        var lcr: RouteInfo?

        for route in routeInfos {
            let coords = route.polyline.coordinates()
            var distance: Double = 0
            if coords.count > 1 {
                for i in 0 ..< (coords.count - 1) {
                    let loc1 = CLLocation(latitude: coords[i].latitude, longitude: coords[i].longitude)
                    let loc2 = CLLocation(latitude: coords[i + 1].latitude, longitude: coords[i + 1].longitude)
                    distance += loc1.distance(from: loc2)
                }
            }

            switch route.type {
            case .walking:
                twd += distance
                if lwr == nil || distance > (lwr?.polyline.coordinates().reduce((
                    0.0,
                    nil as CLLocationCoordinate2D?
                )) { res, coord -> (Double, CLLocationCoordinate2D?) in
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
                if lrr == nil || distance > (lrr?.polyline.coordinates().reduce((
                    0.0,
                    nil as CLLocationCoordinate2D?
                )) { res, coord -> (Double, CLLocationCoordinate2D?) in
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
                if lcr == nil || distance > (lcr?.polyline.coordinates().reduce((
                    0.0,
                    nil as CLLocationCoordinate2D?
                )) { res, coord -> (Double, CLLocationCoordinate2D?) in
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

        totalWalkingDistance = twd
        totalRunningDistance = trd
        totalCyclingDistance = tcd
        longestWalkingRoute = lwr
        longestRunningRoute = lrr
        longestCyclingRoute = lcr
        totalRoutes = routeInfos.count
    }
}

/// Helper function for distance formatting
private func formatDistance(_ distanceMeters: Double) -> String {
    let distanceMiles = distanceMeters / 1609.34
    if distanceMiles < 0.05, distanceMiles > 0 {
        let distanceFeet = distanceMeters * 3.28084
        return String(format: "%.0f ft", distanceFeet)
    }
    return String(format: "%.1f mi", distanceMiles)
}

extension HealthKitManager { // Helper to get all routes easily
    var allRouteInfos: [RouteInfo] {
        walkingRouteInfos + runningRouteInfos + cyclingRouteInfos
    }
}

/// Extension for MKPolyline to calculate its points (needed for distance calculation in Stats)
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
                    date: Date().addingTimeInterval(-86400 * 2),
                    locations: [
                        CLLocation(
                            latitude: P1.latitude,
                            longitude: P1.longitude
                        ),
                        CLLocation(latitude: P2.latitude, longitude: P2.longitude),
                    ]
                ),
            ]
            mockManager.runningRouteInfos = [
                RouteInfo(
                    id: UUID(),
                    name: "Park Run",
                    type: .running,
                    date: Date().addingTimeInterval(-86400),
                    locations: [
                        CLLocation(latitude: P2.latitude, longitude: P2.longitude),
                        CLLocation(latitude: P3.latitude, longitude: P3.longitude),
                    ]
                ),
            ]
            mockManager.cyclingRouteInfos = [
                RouteInfo(
                    id: UUID(),
                    name: "Bike Ride", type: .cycling,
                    date: Date().addingTimeInterval(-86400 * 3),
                    locations: [
                        CLLocation(latitude: P2.latitude, longitude: P2.longitude),
                        CLLocation(latitude: P3.latitude, longitude: P3.longitude),
                    ]
                ),
            ]

            return StatsView(healthKitManager: mockManager)
                .environment(\.routeColorTheme, .vibrant)
        }
    }
#endif
