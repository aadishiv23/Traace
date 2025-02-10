//
//  ToggleButton.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import Foundation
import SwiftUI

struct ToggleButton: View {
    let title: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(isOn ? color : Color.gray))
                .foregroundStyle(.white)
        }
    }
}
