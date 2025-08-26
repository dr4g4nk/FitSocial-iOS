//
//  DividerWithLabel.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//


import AuthenticationServices
import SwiftUI

struct DividerWithLabel: View {
    let label: String
    var body: some View {
        HStack {
            Rectangle().fill(.quaternary).frame(height: 1)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            Rectangle().fill(.quaternary).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}