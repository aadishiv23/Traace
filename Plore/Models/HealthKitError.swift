//
//  HealthKitError.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation

/// Errors that can occur during HealthKit operations
enum HealthKitError: Error {
    case notAvailable
    case notAuthorized
    case dataTypeMismatch
    case queryFailed
    case noRoutesFound
    case dataProcessingFailed
}

// MARK: - Error Localization

extension HealthKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "Not authorized to access HealthKit data."
        case .dataTypeMismatch:
            return "Data type mismatch in HealthKit query."
        case .queryFailed:
            return "HealthKit query failed."
        case .noRoutesFound:
            return "No routes found for this workout."
        case .dataProcessingFailed:
            return "Failed to process HealthKit data."
        }
    }
} 