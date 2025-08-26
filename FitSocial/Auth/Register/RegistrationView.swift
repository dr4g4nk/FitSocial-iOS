//
//  RegisterationView.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//
import SwiftUI

struct RegistrationView: View {
    @Bindable private var vm: RegistrationViewModel
    
    let onSuccess: ()->Void
    
    init(vm: RegistrationViewModel, onSuccess: @escaping ()->Void) {
        self.vm = vm
        self.onSuccess = onSuccess
    }
    
    
    @FocusState private var focus: Field?
    enum Field { case first, last, email, pass, confirm }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Naslov
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kreiraj nalog")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                    Text("Unesite osnovne podatke kako biste započeli.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // Forma
                VStack(spacing: 16) {
                    // Ime
                    LabeledField(
                        title: "Ime",
                        error: vm.firstName.isEmpty ? nil : vm.firstNameError
                    ) {
                        TextField("Vaše ime", text: $vm.firstName)
                            .textContentType(.givenName)
                            .submitLabel(.next)
                            .focused($focus, equals: .first)
                            .onSubmit { focus = .last }
                    }

                    // Prezime
                    LabeledField(
                        title: "Prezime",
                        error: vm.lastName.isEmpty ? nil : vm.lastNameError
                    ) {
                        TextField("Vaše prezime", text: $vm.lastName)
                            .textContentType(.familyName)
                            .submitLabel(.next)
                            .focused($focus, equals: .last)
                            .onSubmit { focus = .email }
                    }

                    // Email
                    LabeledField(
                        title: "Email",
                        error: vm.email.isEmpty ? nil : vm.emailError
                    ) {
                        TextField("ime@domena.com", text: $vm.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(.emailAddress)
                            .submitLabel(.next)
                            .focused($focus, equals: .email)
                            .onSubmit { focus = .pass }
                    }

                    // Lozinka
                    LabeledField(
                        title: "Lozinka",
                        helper: helperForStrength(vm.passwordStrength),
                        error: vm.password.isEmpty ? nil : vm.passwordError
                    ) {
                        HStack {
                            Group {
                                if vm.isSecurePassword {
                                    SecureField(
                                        "Najmanje 8 znakova",
                                        text: $vm.password
                                    )
                                } else {
                                    TextField(
                                        "Najmanje 8 znakova",
                                        text: $vm.password
                                    )
                                }
                            }
                            .textContentType(.newPassword)
                            .submitLabel(.next)
                            .focused($focus, equals: .pass)
                            .onSubmit { focus = .confirm }

                            Button {
                                vm.isSecurePassword.toggle()
                            } label: {
                                Image(
                                    systemName: vm.isSecurePassword
                                        ? "eye.slash" : "eye"
                                )
                                .imageScale(.medium)
                                .padding(8)
                            }
                            .accessibilityLabel(
                                vm.isSecurePassword
                                    ? "Prikaži lozinku" : "Sakrij lozinku"
                            )
                        }
                    }

                    // Potvrda lozinke
                    LabeledField(
                        title: "Potvrda lozinke",
                        error: vm.confirm.isEmpty ? nil : vm.confirmError
                    ) {
                        HStack {
                            Group {
                                if vm.isSecureConfirm {
                                    SecureField(
                                        "Ponovite lozinku",
                                        text: $vm.confirm
                                    )
                                } else {
                                    TextField(
                                        "Ponovite lozinku",
                                        text: $vm.confirm
                                    )
                                }
                            }
                            .textContentType(.newPassword)
                            .submitLabel(.go)
                            .focused($focus, equals: .confirm)
                            .onSubmit {
                                if vm.isFormValid && !vm.isLoading {
                                    Task { await vm.register(onSuccess: onSuccess) }
                                }
                            }

                            Button {
                                vm.isSecureConfirm.toggle()
                            } label: {
                                Image(
                                    systemName: vm.isSecureConfirm
                                        ? "eye.slash" : "eye"
                                )
                                .imageScale(.medium)
                                .padding(8)
                            }
                            .accessibilityLabel(
                                vm.isSecureConfirm
                                    ? "Prikaži potvrdu lozinke"
                                    : "Sakrij potvrdu lozinke"
                            )
                        }
                    }
                }

                // Globalna greška (npr. email zauzet)
                if let error = vm.errorMessage {
                    InlineError(text: error)
                }

                // CTA
                Button {
                    Task { await vm.register(onSuccess: onSuccess) }
                } label: {
                    HStack {
                        if vm.isLoading { ProgressView() }
                        Text(vm.isLoading ? "Kreiranje…" : "Kreiraj nalog")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.isFormValid || vm.isLoading)
                .accessibilityHint("Kreiraj nalog sa unesenim podacima")

                // Pravila i privatnost
                Text(
                    "Kreiranjem naloga prihvatate Uslove korištenja i Politiku privatnosti."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                // Uspjeh (po želji zamijeniti navigacijom)
                if vm.didFinish {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").imageScale(
                            .medium
                        )
                        Text("Nalog je uspješno kreiran.")
                    }
                    .foregroundStyle(.green)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(.background)
        .scrollDismissesKeyboard(.never)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Zatvori tastaturu") { focus = nil }
            }
        }
        .navigationTitle("Registracija")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helperForStrength(_ s: RegistrationViewModel.Strength)
        -> String
    {
        switch s {
        case .weak: return "Snaga lozinke: Slaba"
        case .medium: return "Snaga lozinke: Srednja"
        case .strong: return "Snaga lozinke: Jaka"
        }
    }
}

// MARK: - Pomoćni UI elementi

private struct LabeledField<Content: View>: View {
    let title: String
    var helper: String? = nil
    var error: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            content()
                .padding(12)
                .background(.thinMaterial, in: .rect(cornerRadius: 12))
                .overlay {
                    // Subtilan fokus/greška indikator (HIG: nenametljivo)
                    if error != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red.opacity(0.6), lineWidth: 1)
                    }
                }

            if let helper, error == nil {
                Text(helper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
                    .accessibilityHint(error)
            }
        }
    }
}

private struct InlineError: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").imageScale(
                .medium
            )
            Text(text)
        }
        .foregroundStyle(.red)
        .font(.footnote)
        .accessibilityHint("Greška prilikom registracije")
    }
}
