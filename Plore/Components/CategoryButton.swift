//
//  CategoryButton.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/4/25.
//

import Foundation
import SwiftUI

/// A category button for horizontal scrolling.
struct CategoryButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 30, height: 30)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
    }
}
