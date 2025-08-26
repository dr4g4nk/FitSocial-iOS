//
//  AlternativeSignInView.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//


import AuthenticationServices
import SwiftUI

struct AlternativeSignInView: View{
    
    var body: some View{
        VStack {
    
            VStack(spacing: 12) {
                SignInWithAppleButtonContainer {
                    // Handle ASAuthorizationController flow u vašem koordinatoru
                }
                .frame(height: 44)
                .accessibilityLabel("Nastavi sa Apple-om")

                // Google — placeholder dugme (za pravi flow dodati GoogleSignIn SDK)
                Button {
                    // Pokreni Google sign-in
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .imageScale(.large)
                        Text("Nastavi sa Google-om")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Nastavi sa Google-om")
            }
            
            Text(
                "Nastavkom prihvatate naše Uslove korištenja i Politiku privatnosti."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            .accessibilityHint("Informacije o uslovima i privatnosti")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}
