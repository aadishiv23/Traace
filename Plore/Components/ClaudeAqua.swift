import SwiftUI

// MARK: - Button Style Enum

/// The style of the button
public enum ClaudeButtonStyle {
    /// Classic Aqua-inspired style with modern colors
    case modernAqua
    /// Glossy 3D style inspired by Vision OS
    case glassy3D
}

/// A button with customizable modern styles
public struct ClaudeButton: View {
    // MARK: - Properties
    
    /// The text to display on the button
    public var text: String
    
    /// The action to perform when the button is tapped
    public var action: () -> Void
    
    /// The primary color of the button
    public var color: ClaudeButtonColor
    
    /// The size of the button
    public var size: ClaudeButtonSize
    
    /// Whether the button has rounded corners
    public var rounded: Bool
    
    /// The icon to display on the button (optional)
    public var icon: Image?
    
    /// The style of the button (modernAqua or glassy3D)
    public var style: ClaudeButtonStyle
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    
    // MARK: - Initializers
    
    /// Creates a new themed button
    /// - Parameters:
    ///   - text: The text to display on the button
    ///   - color: The primary color of the button
    ///   - size: The size of the button
    ///   - rounded: Whether the button has rounded corners
    ///   - icon: Optional icon to display on the button
    ///   - style: The style of the button (modernAqua or glassy3D)
    ///   - action: The action to perform when the button is tapped
    public init(
        _ text: String,
        color: ClaudeButtonColor = .blue,
        size: ClaudeButtonSize = .medium,
        rounded: Bool = true,
        icon: Image? = nil,
        style: ClaudeButtonStyle = .modernAqua,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.color = color
        self.size = size
        self.rounded = rounded
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.iconSize, height: size.iconSize)
                }
                
                Text(text)
                    .font(.system(size: size.fontSize, weight: style == .modernAqua ? .bold : .semibold))
                    .shadow(color: style == .modernAqua ? color.textShadowColor : .clear, radius: 0, x: 0, y: style == .modernAqua ? -1 : 0)
            }
            .foregroundColor(style == .modernAqua ? .white : color.glassyTextColor)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                Group {
                    if style == .modernAqua {
                        modernAquaBackground
                    } else {
                        glassy3DBackground
                    }
                }
            )
            .clipShape(rounded ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: style == .modernAqua ? 8 : 16)))
            .overlay(
                Group {
                    if style == .modernAqua {
                        if rounded {
                            Capsule()
                                .stroke(color.borderColor, lineWidth: 1)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color.borderColor, lineWidth: 1)
                        }
                    } else {
                        if rounded {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            color.glassyBorderColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            color.glassyBorderColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    }
                }
            )
            .shadow(
                color: style == .modernAqua
                    ? color.shadowColor.opacity(0.4)
                    : color.glassyShadowColor.opacity(isPressed ? 0.2 : 0.3),
                radius: style == .modernAqua
                    ? (isPressed ? 2 : 4)
                    : (isPressed ? 5 : 10),
                x: 0,
                y: style == .modernAqua
                    ? (isPressed ? 1 : 3)
                    : (isPressed ? 2 : 5)
            )
            .shadow(
                color: style == .modernAqua
                    ? color.highlightColor.opacity(0.4)
                    : Color.white.opacity(0.3),
                radius: style == .modernAqua ? 0 : 3,
                x: 0,
                y: style == .modernAqua
                    ? (isPressed ? 0 : -1)
                    : -2
            )
            .scaleEffect(isPressed ? 0.97 : (isHovered && style == .glassy3D ? 1.02 : 1))
            .offset(y: isPressed ? 1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .animation(.easeOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    self.isPressed = true
                    self.isHovered = false
                }
                .onEnded { _ in
                    self.isPressed = false
                    self.isHovered = false
                }
        )
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
    
    // MARK: - Background Views
    
    private var modernAquaBackground: some View {
        ZStack {
            // Vibrant main gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    isPressed ? color.pressedTopColor : color.topColor,
                    isPressed ? color.pressedBottomColor : color.bottomColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Enhanced shine effect overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(isPressed ? 0.3 : 0.8),
                    Color.white.opacity(isPressed ? 0.15 : 0.4),
                    Color.white.opacity(0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .opacity(isPressed ? 0.4 : 0.9)
            .mask(
                Rectangle()
                    .frame(height: isPressed ? 12 : 24)
                    .offset(y: 2)
                    .blur(radius: 3)
            )
            
            // Additional subtle highlight at the bottom edge
            if !isPressed {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        color.accentColor.opacity(0.3),
                        color.accentColor.opacity(0.1)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .mask(
                    Rectangle()
                        .frame(height: 20)
                        .offset(y: 20)
                        .blur(radius: 5)
                )
            }
        }
    }
    
    private var glassy3DBackground: some View {
        ZStack {
            // Base blur and color
            color.glassyBaseColor
                .opacity(isPressed ? 0.6 : 0.3)
                .blur(radius: 1)
            
            // Glossy gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    color.glassyHighlightColor.opacity(isPressed ? 0.5 : 0.7),
                    color.glassyBaseColor.opacity(isPressed ? 0.4 : 0.6),
                    color.glassyDeepColor.opacity(isPressed ? 0.5 : 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(isPressed ? 0.7 : 0.8)
            
            // Top shine
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(isPressed ? 0.3 : 0.8),
                    Color.white.opacity(0)
                ]),
                startPoint: .topLeading,
                endPoint: .center
            )
            .opacity(isPressed ? 0.3 : 0.6)
            .blendMode(.overlay)
            
            // Edge highlight
            if isHovered && !isPressed {
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.glassyHighlightColor.opacity(0.6),
                        color.glassyHighlightColor.opacity(0.2),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.overlay)
            }
            
            // Bottom depth
            if !isPressed {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        color.glassyDeepColor.opacity(0.2),
                        color.glassyDeepColor.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.multiply)
            }
            
            // Ultra-thin inner border for depth
            if rounded {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.1 : 0.3),
                                Color.clear,
                                color.glassyDeepColor.opacity(isPressed ? 0.1 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.1 : 0.3),
                                Color.clear,
                                color.glassyDeepColor.opacity(isPressed ? 0.1 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        }
        // Apply a very subtle background blur for the glassy effect
        .background(
            Color.white.opacity(0.001) // Nearly invisible, just to trigger the blur
                .background(Material.ultraThinMaterial)
        )
    }
}

// MARK: - Button Color

public struct ClaudeButtonColor {
    // Modern Aqua Colors
    var topColor: Color
    var bottomColor: Color
    var pressedTopColor: Color
    var pressedBottomColor: Color
    var borderColor: Color
    var shadowColor: Color
    var highlightColor: Color
    var textShadowColor: Color
    var accentColor: Color
    
    // Glassy 3D Colors
    var glassyBaseColor: Color
    var glassyHighlightColor: Color
    var glassyDeepColor: Color
    var glassyBorderColor: Color
    var glassyShadowColor: Color
    var glassyTextColor: Color
    
    /// Blue button (default)
    public static let blue = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.2, green: 0.7, blue: 0.98),
        bottomColor: Color(red: 0.05, green: 0.54, blue: 0.9),
        pressedTopColor: Color(red: 0.05, green: 0.48, blue: 0.85),
        pressedBottomColor: Color(red: 0.15, green: 0.58, blue: 0.95),
        borderColor: Color(red: 0.05, green: 0.41, blue: 0.74),
        shadowColor: Color(red: 0.03, green: 0.3, blue: 0.62),
        highlightColor: Color(red: 0.5, green: 0.84, blue: 1),
        textShadowColor: Color(red: 0.03, green: 0.27, blue: 0.54),
        accentColor: Color(red: 0.4, green: 0.7, blue: 1),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.15, green: 0.5, blue: 0.95),
        glassyHighlightColor: Color(red: 0.4, green: 0.75, blue: 1),
        glassyDeepColor: Color(red: 0.08, green: 0.35, blue: 0.85),
        glassyBorderColor: Color(red: 0, green: 0.45, blue: 0.9),
        glassyShadowColor: Color(red: 0.05, green: 0.35, blue: 0.8),
        glassyTextColor: Color.white
    )
    
    /// Green button
    public static let green = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.25, green: 0.9, blue: 0.4),
        bottomColor: Color(red: 0.1, green: 0.7, blue: 0.3),
        pressedTopColor: Color(red: 0.1, green: 0.65, blue: 0.25),
        pressedBottomColor: Color(red: 0.2, green: 0.75, blue: 0.35),
        borderColor: Color(red: 0.08, green: 0.57, blue: 0.23),
        shadowColor: Color(red: 0.05, green: 0.45, blue: 0.2),
        highlightColor: Color(red: 0.6, green: 0.98, blue: 0.7),
        textShadowColor: Color(red: 0.06, green: 0.4, blue: 0.15),
        accentColor: Color(red: 0.4, green: 0.9, blue: 0.5),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.2, green: 0.8, blue: 0.4),
        glassyHighlightColor: Color(red: 0.5, green: 0.95, blue: 0.6),
        glassyDeepColor: Color(red: 0.1, green: 0.6, blue: 0.3),
        glassyBorderColor: Color(red: 0.15, green: 0.7, blue: 0.35),
        glassyShadowColor: Color(red: 0.1, green: 0.5, blue: 0.25),
        glassyTextColor: Color.white
    )
    
    /// Red button
    public static let red = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.98, green: 0.3, blue: 0.4),
        bottomColor: Color(red: 0.9, green: 0.15, blue: 0.2),
        pressedTopColor: Color(red: 0.85, green: 0.1, blue: 0.15),
        pressedBottomColor: Color(red: 0.9, green: 0.2, blue: 0.3),
        borderColor: Color(red: 0.75, green: 0.1, blue: 0.15),
        shadowColor: Color(red: 0.65, green: 0.08, blue: 0.12),
        highlightColor: Color(red: 1, green: 0.65, blue: 0.7),
        textShadowColor: Color(red: 0.6, green: 0.05, blue: 0.1),
        accentColor: Color(red: 0.95, green: 0.5, blue: 0.55),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.95, green: 0.25, blue: 0.35),
        glassyHighlightColor: Color(red: 1, green: 0.5, blue: 0.55),
        glassyDeepColor: Color(red: 0.8, green: 0.1, blue: 0.2),
        glassyBorderColor: Color(red: 0.85, green: 0.2, blue: 0.3),
        glassyShadowColor: Color(red: 0.7, green: 0.1, blue: 0.2),
        glassyTextColor: Color.white
    )
    
    /// Purple button
    public static let purple = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.75, green: 0.4, blue: 0.95),
        bottomColor: Color(red: 0.6, green: 0.25, blue: 0.85),
        pressedTopColor: Color(red: 0.55, green: 0.2, blue: 0.75),
        pressedBottomColor: Color(red: 0.65, green: 0.3, blue: 0.85),
        borderColor: Color(red: 0.5, green: 0.15, blue: 0.7),
        shadowColor: Color(red: 0.4, green: 0.1, blue: 0.6),
        highlightColor: Color(red: 0.85, green: 0.65, blue: 0.98),
        textShadowColor: Color(red: 0.35, green: 0.08, blue: 0.5),
        accentColor: Color(red: 0.7, green: 0.5, blue: 0.9),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.65, green: 0.3, blue: 0.9),
        glassyHighlightColor: Color(red: 0.8, green: 0.5, blue: 1),
        glassyDeepColor: Color(red: 0.5, green: 0.2, blue: 0.8),
        glassyBorderColor: Color(red: 0.6, green: 0.25, blue: 0.85),
        glassyShadowColor: Color(red: 0.45, green: 0.15, blue: 0.7),
        glassyTextColor: Color.white
    )
    
    /// Orange button
    public static let orange = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.98, green: 0.6, blue: 0.25),
        bottomColor: Color(red: 0.9, green: 0.45, blue: 0.1),
        pressedTopColor: Color(red: 0.85, green: 0.4, blue: 0.05),
        pressedBottomColor: Color(red: 0.9, green: 0.5, blue: 0.15),
        borderColor: Color(red: 0.8, green: 0.35, blue: 0.05),
        shadowColor: Color(red: 0.7, green: 0.3, blue: 0.05),
        highlightColor: Color(red: 1, green: 0.75, blue: 0.5),
        textShadowColor: Color(red: 0.6, green: 0.25, blue: 0.05),
        accentColor: Color(red: 0.95, green: 0.65, blue: 0.35),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.95, green: 0.5, blue: 0.2),
        glassyHighlightColor: Color(red: 1, green: 0.65, blue: 0.35),
        glassyDeepColor: Color(red: 0.85, green: 0.35, blue: 0.1),
        glassyBorderColor: Color(red: 0.9, green: 0.4, blue: 0.15),
        glassyShadowColor: Color(red: 0.8, green: 0.3, blue: 0.1),
        glassyTextColor: Color.white
    )
    
    /// Teal button
    public static let teal = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.2, green: 0.85, blue: 0.8),
        bottomColor: Color(red: 0.1, green: 0.7, blue: 0.65),
        pressedTopColor: Color(red: 0.05, green: 0.6, blue: 0.55),
        pressedBottomColor: Color(red: 0.15, green: 0.7, blue: 0.65),
        borderColor: Color(red: 0.05, green: 0.55, blue: 0.5),
        shadowColor: Color(red: 0.03, green: 0.4, blue: 0.35),
        highlightColor: Color(red: 0.5, green: 0.95, blue: 0.9),
        textShadowColor: Color(red: 0.03, green: 0.35, blue: 0.3),
        accentColor: Color(red: 0.4, green: 0.85, blue: 0.8),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.15, green: 0.75, blue: 0.7),
        glassyHighlightColor: Color(red: 0.4, green: 0.9, blue: 0.85),
        glassyDeepColor: Color(red: 0.05, green: 0.6, blue: 0.55),
        glassyBorderColor: Color(red: 0.1, green: 0.7, blue: 0.65),
        glassyShadowColor: Color(red: 0.05, green: 0.5, blue: 0.45),
        glassyTextColor: Color.white
    )
    
    /// Pink button
    public static let pink = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.98, green: 0.4, blue: 0.75),
        bottomColor: Color(red: 0.9, green: 0.25, blue: 0.6),
        pressedTopColor: Color(red: 0.85, green: 0.2, blue: 0.55),
        pressedBottomColor: Color(red: 0.9, green: 0.3, blue: 0.65),
        borderColor: Color(red: 0.8, green: 0.15, blue: 0.5),
        shadowColor: Color(red: 0.7, green: 0.1, blue: 0.45),
        highlightColor: Color(red: 1, green: 0.65, blue: 0.85),
        textShadowColor: Color(red: 0.6, green: 0.1, blue: 0.4),
        accentColor: Color(red: 0.95, green: 0.5, blue: 0.7),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.95, green: 0.35, blue: 0.7),
        glassyHighlightColor: Color(red: 1, green: 0.55, blue: 0.8),
        glassyDeepColor: Color(red: 0.85, green: 0.2, blue: 0.55),
        glassyBorderColor: Color(red: 0.9, green: 0.3, blue: 0.65),
        glassyShadowColor: Color(red: 0.8, green: 0.15, blue: 0.5),
        glassyTextColor: Color.white
    )
    
    /// Gray button - modernized
    public static let gray = ClaudeButtonColor(
        // Modern Aqua colors
        topColor: Color(red: 0.65, green: 0.68, blue: 0.72),
        bottomColor: Color(red: 0.5, green: 0.54, blue: 0.58),
        pressedTopColor: Color(red: 0.45, green: 0.49, blue: 0.53),
        pressedBottomColor: Color(red: 0.55, green: 0.59, blue: 0.63),
        borderColor: Color(red: 0.4, green: 0.43, blue: 0.47),
        shadowColor: Color(red: 0.35, green: 0.38, blue: 0.42),
        highlightColor: Color(red: 0.8, green: 0.83, blue: 0.87),
        textShadowColor: Color(red: 0.25, green: 0.28, blue: 0.32),
        accentColor: Color(red: 0.7, green: 0.73, blue: 0.77),
        
        // Glassy 3D colors
        glassyBaseColor: Color(red: 0.5, green: 0.53, blue: 0.57),
        glassyHighlightColor: Color(red: 0.7, green: 0.73, blue: 0.77),
        glassyDeepColor: Color(red: 0.4, green: 0.43, blue: 0.47),
        glassyBorderColor: Color(red: 0.45, green: 0.48, blue: 0.52),
        glassyShadowColor: Color(red: 0.35, green: 0.38, blue: 0.42),
        glassyTextColor: Color.white
    )
    
    /// Create a custom button color
    public static func custom(
        // Base color
        base: Color,
        // Optional customization factors
        darkFactor: CGFloat = 0.3,
        pressedDarkenFactor: CGFloat = 0.2,
        accentBrightnessFactor: CGFloat = 0.2
    ) -> ClaudeButtonColor {
        // This would extract RGB values and create all the needed color variants
        // Simplified implementation
        return .blue // Placeholder - would return custom color in real implementation
    }
}

// MARK: - Improved Button Size

/// Button size with responsive/adaptable options
public struct ClaudeButtonSize {
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let fontSize: CGFloat
    let iconSize: CGFloat
    
    /// Small size button
    public static let small = ClaudeButtonSize(
        verticalPadding: 7,
        horizontalPadding: 14,
        fontSize: 12,
        iconSize: 12
    )
    
    /// Medium size button (default)
    public static let medium = ClaudeButtonSize(
        verticalPadding: 12,
        horizontalPadding: 18,
        fontSize: 14,
        iconSize: 16
    )
    
    /// Large size button
    public static let large = ClaudeButtonSize(
        verticalPadding: 16,
        horizontalPadding: 26,
        fontSize: 16,
        iconSize: 20
    )
    
    /// Extra large size button
    public static let xlarge = ClaudeButtonSize(
        verticalPadding: 20,
        horizontalPadding: 32,
        fontSize: 18,
        iconSize: 24
    )
    
    /// Create a custom size button
    public static func custom(vertical: CGFloat, horizontal: CGFloat, font: CGFloat, icon: CGFloat) -> ClaudeButtonSize {
        ClaudeButtonSize(
            verticalPadding: vertical,
            horizontalPadding: horizontal,
            fontSize: font,
            iconSize: icon
        )
    }
    
    /// Create an adaptable size based on container width
    public static func adaptable(minWidth: CGFloat, maxWidth: CGFloat, containerWidth: CGFloat) -> ClaudeButtonSize {
        // Calculate how far along the width range we are (0.0 to 1.0)
        let widthRatio = min(max((containerWidth - minWidth) / (maxWidth - minWidth), 0.0), 1.0)
        
        // Interpolate between small and large sizes
        return ClaudeButtonSize(
            verticalPadding: lerp(start: small.verticalPadding, end: large.verticalPadding, amount: widthRatio),
            horizontalPadding: lerp(start: small.horizontalPadding, end: large.horizontalPadding, amount: widthRatio),
            fontSize: lerp(start: small.fontSize, end: large.fontSize, amount: widthRatio),
            iconSize: lerp(start: small.iconSize, end: large.iconSize, amount: widthRatio)
        )
    }
    
    /// Create an adaptable size based on dynamic type settings
    public static func adaptableForDynamicType(baseSize: ClaudeButtonSize = .medium, dynamicTypeSize: DynamicTypeSize) -> ClaudeButtonSize {
        // Scale factors based on dynamic type size
        let scaleFactor: CGFloat
        switch dynamicTypeSize {
        case .xSmall:
            scaleFactor = 0.8
        case .small:
            scaleFactor = 0.9
        case .medium:
            scaleFactor = 1.0
        case .large:
            scaleFactor = 1.1
        case .xLarge:
            scaleFactor = 1.2
        case .xxLarge:
            scaleFactor = 1.3
        case .xxxLarge:
            scaleFactor = 1.4
        @unknown default:
            scaleFactor = 1.0
        }
        
        return ClaudeButtonSize(
            verticalPadding: baseSize.verticalPadding * scaleFactor,
            horizontalPadding: baseSize.horizontalPadding * scaleFactor,
            fontSize: baseSize.fontSize * scaleFactor,
            iconSize: baseSize.iconSize * scaleFactor
        )
    }
    
    /// Helper function to linearly interpolate between two values
    private static func lerp(start: CGFloat, end: CGFloat, amount: CGFloat) -> CGFloat {
        return start + (end - start) * amount
    }
}

// Extension to make ClaudeButton work with GeometryReader for adaptive sizing
extension ClaudeButton {
    /// Creates a new adaptable ClaudeButton that adjusts size based on available width
    /// - Parameters:
    ///   - text: The text to display on the button
    ///   - color: The primary color of the button
    ///   - minWidth: The minimum width for sizing calculations
    ///   - maxWidth: The maximum width for sizing calculations
    ///   - rounded: Whether the button has rounded corners
    ///   - icon: Optional icon to display on the button
    ///   - style: The style of the button (modernAqua or glassy3D)
    ///   - action: The action to perform when the button is tapped
    /// - Returns: A view that wraps the ClaudeButton with adaptive sizing
    public static func adaptable(
        _ text: String,
        color: ClaudeButtonColor = .blue,
        minWidth: CGFloat = 300,
        maxWidth: CGFloat = 500,
        rounded: Bool = true,
        icon: Image? = nil,
        style: ClaudeButtonStyle = .modernAqua,
        action: @escaping () -> Void
    ) -> some View {
        GeometryReader { geometry in
            ClaudeButton(
                text,
                color: color,
                size: .adaptable(minWidth: minWidth, maxWidth: maxWidth, containerWidth: geometry.size.width),
                rounded: rounded,
                icon: icon,
                style: style,
                action: action
            )
        }
    }
    
    /// Creates a new ClaudeButton that adapts to dynamic type settings
    /// - Parameters:
    ///   - text: The text to display on the button
    ///   - color: The primary color of the button
    ///   - baseSize: The base size to scale from
    ///   - rounded: Whether the button has rounded corners
    ///   - icon: Optional icon to display on the button
    ///   - style: The style of the button (modernAqua or glassy3D)
    ///   - action: The action to perform when the button is tapped
    /// - Returns: A view that wraps the ClaudeButton with accessibility scaling
    public static func accessibleSize(
        _ text: String,
        color: ClaudeButtonColor = .blue,
        baseSize: ClaudeButtonSize = .medium,
        rounded: Bool = true,
        icon: Image? = nil,
        style: ClaudeButtonStyle = .modernAqua,
        action: @escaping () -> Void
    ) -> some View {
        return DynamicTypeReader { typeSize in
            ClaudeButton(
                text,
                color: color,
                size: .adaptableForDynamicType(baseSize: baseSize, dynamicTypeSize: typeSize),
                rounded: rounded,
                icon: icon,
                style: style,
                action: action
            )
        }
    }
}

// Helper view to read dynamic type size
struct DynamicTypeReader<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    let content: (DynamicTypeSize) -> Content
    
    init(@ViewBuilder content: @escaping (DynamicTypeSize) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(dynamicTypeSize)
    }
}

// MARK: - Preview

struct Aqua: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("Modern Aqua Buttons")
                .font(.title)
                .padding(.bottom, 10)
            
            // Different colors with Modern Aqua style
            Group {
                HStack(spacing: 12) {
                    ClaudeButton("Blue", color: .blue, style: .modernAqua) {}
                    ClaudeButton("Green", color: .green, style: .modernAqua) {}
                    ClaudeButton("Red", color: .red, style: .modernAqua) {}
                }
                
                HStack(spacing: 12) {
                    ClaudeButton("Purple", color: .purple, style: .modernAqua) {}
                    ClaudeButton("Orange", color: .orange, style: .modernAqua) {}
                    ClaudeButton("Teal", color: .teal, style: .modernAqua) {}
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            Text("Glassy 3D Buttons")
                .font(.title)
                .padding(.bottom, 10)
            
            // Different colors with Glassy 3D style
            Group {
                HStack(spacing: 12) {
                    ClaudeButton("Blue", color: .blue, style: .glassy3D) {}
                    ClaudeButton("Green", color: .green, style: .glassy3D) {}
                    ClaudeButton("Red", color: .red, style: .glassy3D) {}
                }
                
                HStack(spacing: 12) {
                    ClaudeButton("Purple", color: .purple, style: .modernAqua) {}
                    ClaudeButton("Orange", color: .orange, style: .modernAqua) {}
                    ClaudeButton("Teal", color: .teal, style: .modernAqua) {}
                }
            }
        }
    }
}

struct ClaudeButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 25) {
            Text("Modern Aqua Buttons")
                .font(.title)
                .padding(.bottom, 10)
            
            // Different colors with Modern Aqua style
            Group {
                HStack(spacing: 12) {
                    ClaudeButton("Blue", color: .blue, style: .modernAqua) {}
                    ClaudeButton("Green", color: .green, style: .modernAqua) {}
                    ClaudeButton("Red", color: .red, style: .modernAqua) {}
                }
                
                HStack(spacing: 12) {
                    ClaudeButton("Purple", color: .purple, style: .modernAqua) {}
                    ClaudeButton("Orange", color: .orange, style: .modernAqua) {}
                    ClaudeButton("Teal", color: .teal, style: .modernAqua) {}
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            Text("Glassy 3D Buttons")
                .font(.title)
                .padding(.bottom, 10)
            
            // Different colors with Glassy 3D style
            Group {
                HStack(spacing: 12) {
                    ClaudeButton("Blue", color: .blue, style: .glassy3D) {}
                    ClaudeButton("Green", color: .green, style: .glassy3D) {}
                    ClaudeButton("Red", color: .red, style: .glassy3D) {}
                }
                
                HStack(spacing: 12) {
                    ClaudeButton("Purple", color: .purple, style: .glassy3D) {}
                    ClaudeButton("Orange", color: .orange, style: .glassy3D) {}
                    ClaudeButton("Teal", color: .teal, style: .glassy3D) {}
                }
            }
        }
    }
}
