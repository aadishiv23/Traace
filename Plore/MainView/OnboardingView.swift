import Foundation
import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var currentPage = 0
    @State private var animateBackground = false
    @State private var animateForeground = false

    // Page content data
    let pages = [
        OnboardingPage(
            title: "Welcome to Trace",
            subtitle: "Your personal workout journey tracker",
            icon: "figure.hiking",
            description: "Trace automatically captures and beautifully displays your outdoor activities from your workout history"
        ),
        OnboardingPage(
            title: "Your Routes in One Place",
            subtitle: "Syncs seamlessly with HealthKit",
            icon: "heart.circle.fill",
            description: "Running, walking, cycling - all your routes are automatically synced and stored for you to explore anytime"
        ),
        OnboardingPage(
            title: "Explore Your Progress",
            subtitle: "Filter, search, and organize",
            icon: "slider.horizontal.3",
            description: "Find past workouts by date, activity type, or name - then dive deeper to see detailed stats for each route"
        ),
        OnboardingPage(
            title: "Share Your Achievements",
            subtitle: "Create beautiful snapshots",
            icon: "square.and.arrow.up",
            description: "Capture stunning map snapshots of your favorite routes to share with friends and on social media"
        ),
    ]

    var body: some View {
        ZStack {
            // Dynamic background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(UIColor.systemBackground) : Color(.systemGray6),
                    colorScheme == .dark ? Color.blue.opacity(animateBackground ? 0.2 : 0.1) : Color.blue.opacity(animateBackground ? 0.1 : 0.05),
                    colorScheme == .dark ? Color.cyan.opacity(animateBackground ? 0.15 : 0.05) : Color.cyan.opacity(animateBackground ? 0.08 : 0.03),
                ]),
                startPoint: animateBackground ? .topLeading : .top,
                endPoint: animateBackground ? .bottomTrailing : .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateBackground)
            .onAppear { animateBackground = true }

            // Floating shapes for enhanced background effect
            ZStack {
                // Subtle floating shapes
                ForEach(0 ..< 8) { _ in
                    FloatingShape(
                        size: CGFloat.random(in: 100 ... 200),
                        opacity: Double.random(in: 0.03 ... 0.07),
                        animationDuration: Double.random(in: 20 ... 35),
                        xOffset: CGFloat.random(in: -200 ... 200),
                        yOffset: CGFloat.random(in: -400 ... 400)
                    )
                }
            }
            .blendMode(.plusLighter)

            VStack(spacing: 0) {
                // Page content with improved TabView
                TabView(selection: $currentPage) {
                    ForEach(0 ..< pages.count, id: \.self) { index in
                        pageView(for: pages[index])
                            .padding(.bottom, 30)
                            .padding(.top, 50) // Added top padding for better spacing
                            .tag(index)
                            .transition(.opacity)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(height: 500) // Increased height for better spacing
                .padding(.bottom, 30) // Added bottom padding to fix clipping with page indicators

                Spacer()

                // Progress and action buttons
                VStack(spacing: 25) {
                    // Page indicator dots (custom implementation for better animation control)
                    HStack(spacing: 12) {
                        ForEach(0 ..< pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .shadow(color: currentPage == index ? Color.blue.opacity(0.3) : Color.clear, radius: 2, x: 0, y: 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.bottom, 5)

                    // Action button with enhanced styling
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                // Add a subtle animation before completing onboarding
                                withAnimation(.easeOut(duration: 0.3)) {
                                    hasCompletedOnboarding = true
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))

                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace.downUp))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                // Base gradient
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )

                                // Animated overlay for shimmer effect
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(animateForeground ? 0.1 : 0.0),
                                        Color.white.opacity(0.0),
                                    ]),
                                    startPoint: animateForeground ? .topLeading : .bottomTrailing,
                                    endPoint: animateForeground ? .bottomTrailing : .topLeading
                                )
                                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: false), value: animateForeground)
                                .onAppear { animateForeground = true }
                            }
                        )
                        .foregroundColor(.white)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 5)
                        .padding(.horizontal, 30)
                    }
                    .buttonStyle(ScaleButtonStyle(scaleFactor: 0.97, duration: 0.2, dampingFraction: 0.8))

                    // Skip button for direct access
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                // Jump to the last page
                                currentPage = pages.count - 1
                            }
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(ScaleButtonStyle.subtle)
                        .padding(.top, -5)
                    } else {
                        // Spacer for equal height
                        Spacer().frame(height: 31)
                    }
                }
                .padding(.bottom, 50)
            }
            .padding(.top, 20)
        }
        .onChange(of: currentPage) { _, _ in
            // Play haptic feedback on page change
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    @ViewBuilder
    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 40) {
            // Feature icon with enhanced animation
            ZStack {
                // Pulsating background circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.blue.opacity(0.15) : Color.blue.opacity(0.08),
                                colorScheme == .dark ? Color.cyan.opacity(0.1) : Color.cyan.opacity(0.05),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)

                // Rotating accent circle
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .blue.opacity(0.3),
                                .cyan.opacity(0.1),
                                .blue.opacity(0),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(animateForeground ? 360 : 0))
                    .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animateForeground)

                // Inner circle
                Circle()
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                // Icon with dynamic gradient
                Image(systemName: page.icon)
                    .font(.system(size: 55, weight: .light))
                    .symbolEffect(.pulse, options: .repeating)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Feature title and subtitle with improved typography
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .shadow(color: colorScheme == .dark ? Color.blue.opacity(0.2) : Color.clear, radius: 2, x: 0, y: 0)

                Text(page.subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Feature description with better readability
            Text(page.description)
                .font(.system(size: 17, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.clear, radius: 1, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

/// A floating shape that adds subtle movement to the background
struct FloatingShape: View {
    let size: CGFloat
    let opacity: Double
    let animationDuration: Double
    let xOffset: CGFloat
    let yOffset: CGFloat

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .cyan]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .opacity(opacity)
            .blur(radius: size / 3)
            .offset(
                x: animate ? xOffset : -xOffset,
                y: animate ? yOffset : -yOffset
            )
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

// Data model for onboarding pages
struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let description: String
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}
