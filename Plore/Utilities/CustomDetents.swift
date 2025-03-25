//
//  CustomDetents.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/10/25.
//

import Foundation
import SwiftUI

// MARK: - Custom Sheet Detents

/// A custom sheet detent that is one point less than the maximum.
struct OneSmallThanMaxDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue - 1
    }
}

/// A compact custom sheet detent.
struct CompactDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        // Define a minimum height needed to display your top UI (e.g., search bar)
        let minimumHeight: CGFloat = 130
        let computedHeight = context.maxDetentValue * 0.08
        return max(minimumHeight, computedHeight)
    }
}
