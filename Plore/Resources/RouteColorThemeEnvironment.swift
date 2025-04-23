import SwiftUI

private struct RouteColorThemeKey: EnvironmentKey {
    static let defaultValue: RouteColorTheme = .vibrant
}

extension EnvironmentValues {
    var routeColorTheme: RouteColorTheme {
        get { self[RouteColorThemeKey.self] }
        set { self[RouteColorThemeKey.self] = newValue }
    }
}
