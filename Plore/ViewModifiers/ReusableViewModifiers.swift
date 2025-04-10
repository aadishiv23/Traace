//
//  ReusableViewModifiers.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 4/10/25.
//

import Foundation
import SwiftUI

extension View {
    func glassmorphic() -> some View {
        background(.ultraThinMaterial)
            .background(
                Color(UIColor.systemBackground).opacity(0.7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    /// Neumorphic effect modifier
    func neumorphic(isPressed: Bool = false) -> some View {
        shadow(color: Color.black.opacity(0.2), radius: 8, x: 5, y: 5)
            .shadow(color: Color.white.opacity(0.7), radius: 8, x: -5, y: -5)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .black.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    /// 3D pressed effect for buttons
    func pressedEffect(isPressed: Bool) -> some View {
        scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
}

/*
 usage on collapsibleroute
 .padding()
 .background(
     ZStack {
         RoundedRectangle(cornerRadius: 16)
             .fill(Color(UIColor.systemBackground))

         // subtle grad to give bit depth
         RoundedRectangle(cornerRadius: 16)
             .fill(
                 LinearGradient(
                     colors: [
                         Color(UIColor.systemBackground).opacity(0.9),
                         Color(UIColor.systemBackground)
                     ],
                     startPoint: .topLeading,
                     endPoint: .bottomTrailing
                 )
             )
     }
 )
 .neumorphic()
 */
