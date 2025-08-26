//
//  SignInWithAppleButtonContainer.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//


import AuthenticationServices
import SwiftUI

/// Tanki omotač oko Sign in with Apple dugmeta, tako da zadržimo SwiftUI stilizaciju i layout.
struct SignInWithAppleButtonContainer: View {
    var action: () -> Void
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { _ in },
            onCompletion: { _ in
                action()
            }
        )
        .signInWithAppleButtonStyle(.black)  // automatski prebacuje svijetlo/tamno gdje je podržano
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}