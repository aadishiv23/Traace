//
//  ToggleButton.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import Foundation
import SwiftUI

/// A toggle button that changes style based on its on/off state.
struct ToggleButton: View {
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            VStack {
                Circle()
                    .fill(isOn ? color : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isOn ? color : .gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray6).cornerRadius(10))
    }
}
