//
//  LoginView.swift
//  FitSocial
//
//  Created by Dragan Kos on 13. 8. 2025..
//

import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Bindable private var vm: LoginViewModel
    var onLoggedIn:
        (_ access: String, _ refresh: String?, _ user: User?) -> Void
    var onCancel: () -> Void
    let onRegistration: () -> Void

    @FocusState private var focusedField: Field?

    init(
        vm: LoginViewModel,
        onLoggedIn: @escaping (
            _ access: String, _ refresh: String?, _ user: User?
        ) ->
            Void,
        onCancel: @escaping () -> Void,
        onRegistration: @escaping () -> Void
    ) {
        self.vm = vm
        self.onLoggedIn = onLoggedIn
        self.onCancel = onCancel
        self.onRegistration = onRegistration
    }

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1) Naslov i kratki opis (HIG: jasnoća i hijerarhija)
                LoginHeaderView()

                // 2) Form polja (HIG: eksplicitni labeli, nativni elementi)
                VStack(spacing: 16) {
                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email ili korisničko ime")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        TextField("ime@domena.com", text: $vm.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                            .padding(12)
                            .background(
                                .thinMaterial,
                                in: .rect(cornerRadius: 12)
                            )
                            .accessibilityLabel("Email adresa")
                    }

                    // Lozinka
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lozinka")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        HStack {
                            Group {
                                if vm.isSecure {
                                    SecureField(
                                        "Vaša lozinka",
                                        text: $vm.password
                                    )
                                } else {
                                    TextField(
                                        "Vaša lozinka",
                                        text: $vm.password
                                    )
                                }
                            }
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                vm.login {
                                    token,
                                    refreshToken,
                                    user in
                                    onLoggedIn(token, refreshToken, user)
                                }

                            }

                            Button {
                                vm.isSecure.toggle()
                            } label: {
                                Image(
                                    systemName: vm.isSecure
                                        ? "eye.slash" : "eye"
                                )
                                .imageScale(.medium)
                                .padding(8)
                            }
                            .accessibilityLabel(
                                vm.isSecure
                                    ? "Prikaži lozinku" : "Sakrij lozinku"
                            )
                        }
                        .padding(12)
                        .background(.thinMaterial, in: .rect(cornerRadius: 12))
                    }
                }

                // 3) Inline greška (HIG: saopštiti problem odmah, nenametljivo)
                if let error = vm.error {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .imageScale(.medium)
                        Text(error)
                    }
                    .foregroundStyle(Color(.systemRed))
                    .font(.footnote)
                    .accessibilityHint("Došlo je do greške prilikom prijave")
                    .transition(.opacity)
                }

                Button {
                    vm.login {
                        token,
                        refreshToken,
                        user in
                        onLoggedIn(token, refreshToken, user)
                    }

                } label: {
                    HStack {
                        if vm.isLoading { ProgressView().controlSize(.regular) }
                        Text(vm.isLoading ? "Prijavljivanje…" : "Prijavi se")
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.isValid || vm.isLoading)
                .accessibilityHint("Pokušaj prijave sa unesenim podacima")
                
                AdditionalButtons(onForgotPassword: vm.forgotPassword, onRegistration: onRegistration)

                AlternativeSignInView()

            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(.background)
        .scrollDismissesKeyboard(.never)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Zatvori tastaturu") { focusedField = nil }
            }
        }
    }
}
