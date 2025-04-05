//
//  CDWorkout+Extensions.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 6/24/25.
//

import Foundation
import HealthKit

extension CDWorkout {
    /// Computed property that converts the stored type string to HKWorkoutActivityType
    var activityType: HKWorkoutActivityType? {
        guard let typeString = type, let typeInt = Int(typeString) else {
            return nil
        }
        
        return HKWorkoutActivityType(rawValue: UInt(typeInt))
    }
    
    /// Returns a Boolean indicating if this workout is a walking activity
    var isWalking: Bool {
        return activityType == .walking
    }
    
    /// Returns a Boolean indicating if this workout is a running activity
    var isRunning: Bool {
        return activityType == .running
    }
    
    /// Returns a Boolean indicating if this workout is a cycling activity
    var isCycling: Bool {
        return activityType == .cycling
    }
} 