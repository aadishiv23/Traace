//
//  CategoryButton.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import Foundation
import SwiftUI

/// A simple category button.
struct CategoryButton: View {
    let title: String
    let icon: String

    var body: some View {
        Button {
            // Placeholder action.
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(.gray.opacity(0.2))
            )
        }
        .foregroundStyle(.blue)
    }
}
