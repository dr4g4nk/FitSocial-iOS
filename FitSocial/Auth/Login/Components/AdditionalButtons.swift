//
//  AdditionalButtons.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//

import SwiftUI

struct AdditionalButtons: View{

    private var onForgotPassword: ()->Void
    private var onRegistration: ()-> Void
    
    init(onForgotPassword: @escaping () -> Void, onRegistration: @escaping () -> Void) {
        self.onForgotPassword = onForgotPassword
        self.onRegistration = onRegistration
    }
    
    var body:some View{
        VStack {
            HStack {
                Button("Zaboravljena lozinka?") { onForgotPassword() }
                Spacer()
                Button("Novi nalog") {
                    onRegistration()
                }
            }
            .font(.footnote)
            .tint(.accentColor)

            DividerWithLabel(label: "ili")
        }
    }
}
