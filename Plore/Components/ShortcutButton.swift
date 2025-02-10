//
//  ShortcutButton.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import Foundation
import SwiftUI

/// A button used in the "Get Started" section.
struct ShortcutButton: View {
    let title: String
    let icon: String
    let gradient: Gradient
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            )
        }
    }
}
