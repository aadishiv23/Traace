import Foundation

enum PolylineStyle: String, CaseIterable, Identifiable {
    case standard
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .custom:
            return "Enhanced"
        }
    }
}
