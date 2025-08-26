//
//  LoginHeaderView.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//


import AuthenticationServices
import SwiftUI

struct LoginHeaderView: View{
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prijavite se kako biste nastavili.")
                .foregroundStyle(.secondary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
    }
}
