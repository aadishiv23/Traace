//
//  SearchBarView.swift
//  Plore
//
//  Created by Aadi Shiv Malhotra on 2/11/25.
//

import Foundation
import SwiftUI


struct SearchBarView: View {
    
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray.opacity(0.8))
            TextField("Search", text: $searchText)
                .foregroundStyle(.gray.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.top, 15)
        .padding(.bottom, 15)
    }
}

// #Preview {
//    SearchBarView()
// }
