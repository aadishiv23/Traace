import CoreLocation
import MapKit
import SwiftUI

struct RouteThemeSettingsView: View {
    @Binding var selectedTheme: RouteColorTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    // No use of @Environment(\.routeColorTheme) here; only use the binding

    private let themes: [RouteColorTheme] = RouteColorTheme.allCases
    @State private var animateSelection: RouteColorTheme? = nil

    // Animation states
    @State private var headerAppeared = false
    @State private var customButtonAppeared = false
    @State private var cardsAppeared = false
    @State private var footerAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -30)

                // Custom Colors Button - Moved to top section
                customColorsButtonView
                    .opacity(customButtonAppeared ? 1 : 0)
                    .offset(y: customButtonAppeared ? 0 : 20)
                    .padding(.vertical, 16)

                // Theme cards
                themeCardsView
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 30)

                // Footer
                footerView
                    .opacity(footerAppeared ? 1 : 0)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Route Themes")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            // Staggered animations for UI elements
            withAnimation(.easeOut(duration: 0.4)) {
                headerAppeared = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                customButtonAppeared = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                cardsAppeared = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                footerAppeared = true
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 16) {
            // Animated gradient icon
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .green, .blue]),
                            center: .center
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 12)

                Image(systemName: "map.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)

            Text("Choose Your Map Style")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Select how your routes will appear on the map with different color themes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Custom Colors Button (Moved from footer)

    private var customColorsButtonView: some View {
        NavigationLink(destination: CustomColorPickerView(selectedTheme: $selectedTheme)) {
            HStack {
                Image(systemName: "eyedropper.halffull")
                    .font(.system(size: 16))

                Text("Create Custom Color Theme")
                    .font(.headline)
            }
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
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
    }

    // MARK: - Theme Cards

    private var themeCardsView: some View {
        VStack(spacing: 16) {
            ForEach(themes, id: \.self) { theme in
                themeCard(for: theme)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
                            // First deselect current theme
                            if selectedTheme != theme {
                                animateSelection = nil
                            }

                            // Then after a tiny delay, select the new theme
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
                                    selectedTheme = theme
                                    animateSelection = theme
                                }
                            }
                        }
                    }
            }
        }
    }

    private func themeCard(for theme: RouteColorTheme) -> some View {
        let isSelected = theme == selectedTheme
        let isAnimating = animateSelection == theme

        return VStack(spacing: 0) {
            // Preview area
            ZStack(alignment: .topTrailing) {
                RouteThemeMapPreview(theme: theme)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.accentColor))
                        .padding(12)
                        .transition(.scale.combined(with: .opacity))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatCount(1), value: isAnimating)
                }
            }

            // Theme info
            VStack(alignment: .leading, spacing: 6) {
                Text(theme.displayName)
                    .font(.headline)
                    .padding(.top, 12)

                Text(theme.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Color samples
                HStack(spacing: 8) {
                    ForEach([
                        RouteColors.colors(for: theme).walking,
                        RouteColors.colors(for: theme).running,
                        RouteColors.colors(for: theme).cycling,
                    ], id: \.self) { color in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(height: 8)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(
                    color: isSelected ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.05),
                    radius: isSelected ? 10 : 4,
                    x: 0,
                    y: isSelected ? 0 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                .opacity(isSelected ? (isAnimating ? 0.8 : 1.0) : 0)
        )
        // Scale effect with better spring animation
        .scaleEffect(isSelected ? (isAnimating ? 0.98 : 1.0) : 0.97)
        // Add a brightness effect on selection
        .brightness(isSelected && isAnimating ? 0.03 : 0)
    }

    // MARK: - Footer View

    private var footerView: some View {
        VStack(spacing: 12) {
            Text("Your current selection: \(selectedTheme.displayName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            Text("Changes are applied immediately")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct RouteThemeMapPreview: View {
    let theme: RouteColorTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var body: some View {
        ZStack {
            // Actual Map View
            Map(initialPosition: .region(region)) {
                // Walking route (winding through a park)
                MapPolyline(walkingPolyline)
                    .stroke(RouteColors.colors(for: theme).walking, lineWidth: 4)

                // Running route (along main roads)
                MapPolyline(runningPolyline)
                    .stroke(RouteColors.colors(for: theme).running, lineWidth: 4)

                // Cycling route (longer route)
                MapPolyline(cyclingPolyline)
                    .stroke(RouteColors.colors(for: theme).cycling, lineWidth: 4)
            }
            .disabled(true) // Prevent interaction with the map

            // Legend overlay
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(RouteColors.colors(for: theme).walking)
                        .frame(width: 8, height: 8)
                    Text("Walking")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(RouteColors.colors(for: theme).running)
                        .frame(width: 8, height: 8)
                    Text("Running")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(RouteColors.colors(for: theme).cycling)
                        .frame(width: 8, height: 8)
                    Text("Cycling")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                }
            }
            .padding(6)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    // Sample polylines for each activity
    private var walkingPolyline: MKPolyline {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.776, longitude: -122.419),
            CLLocationCoordinate2D(latitude: 37.775, longitude: -122.418),
            CLLocationCoordinate2D(latitude: 37.774, longitude: -122.416),
            CLLocationCoordinate2D(latitude: 37.773, longitude: -122.415),
            CLLocationCoordinate2D(latitude: 37.772, longitude: -122.414),
            CLLocationCoordinate2D(latitude: 37.771, longitude: -122.413),
        ]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }

    private var runningPolyline: MKPolyline {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.778, longitude: -122.421),
            CLLocationCoordinate2D(latitude: 37.776, longitude: -122.422),
            CLLocationCoordinate2D(latitude: 37.774, longitude: -122.421),
            CLLocationCoordinate2D(latitude: 37.773, longitude: -122.419),
            CLLocationCoordinate2D(latitude: 37.772, longitude: -122.418),
            CLLocationCoordinate2D(latitude: 37.771, longitude: -122.417),
        ]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }

    private var cyclingPolyline: MKPolyline {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.774, longitude: -122.422),
            CLLocationCoordinate2D(latitude: 37.776, longitude: -122.424),
            CLLocationCoordinate2D(latitude: 37.778, longitude: -122.423),
            CLLocationCoordinate2D(latitude: 37.780, longitude: -122.421),
            CLLocationCoordinate2D(latitude: 37.779, longitude: -122.418),
            CLLocationCoordinate2D(latitude: 37.778, longitude: -122.416),
            CLLocationCoordinate2D(latitude: 37.777, longitude: -122.414),
        ]
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

struct PolylinePreviewPath: View {
    let points: [CGPoint]
    let color: Color
    let animationDelay: Double

    @State private var animationProgress: CGFloat = 0.0

    var body: some View {
        ZStack {
            // Background stroke for depth
            routePath
                .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))

            // Main stroke
            routePath
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.0).delay(animationDelay)) {
                animationProgress = 1.0
            }
        }
    }

    private var routePath: Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)

            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }
}

extension RouteColorTheme {
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .vibrant: return "Vibrant Colors"
        case .pastel: return "Pastel Tones"
        case .night: return "Night Mode"
        case .earth: return "Earthy Hues"
        case .custom: return "Custom Colors"
        }
    }

    var description: String {
        switch self {
        case .default: return "Standard SwiftUI colors: blue, red, and green."
        case .vibrant: return "Bright, energetic colors for maximum contrast and visibility."
        case .pastel: return "Soft, calming tones for a gentle, relaxed map view."
        case .night: return "Dark-friendly colors optimized for low-light environments."
        case .earth: return "Natural, muted hues inspired by landscapes and terrain."
        case .custom: return "Your personally selected colors for each route type."
        }
    }
}

#if DEBUG
    struct RouteThemeSettingsView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                RouteThemeSettingsView(selectedTheme: .constant(.vibrant))
            }
            .preferredColorScheme(.light)

            NavigationView {
                RouteThemeSettingsView(selectedTheme: .constant(.night))
            }
            .preferredColorScheme(.dark)
        }
    }
#endif
