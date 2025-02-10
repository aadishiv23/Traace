//
//  ColorBox.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import Foundation
import SwiftUI

/// A color box component.
struct ColorBox: View {
    let color: Color
    let text: String

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).foregroundStyle(color))
    }
}
