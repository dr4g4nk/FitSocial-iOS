//
//  RegisterViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 20. 8. 2025..
//

import Observation
import SwiftUI

@MainActor
@Observable
final class RegistrationViewModel {
    private let authRepo: AuthRepository

    init(authRepo: AuthRepository) {
        self.authRepo = authRepo
    }
    // Input
    var firstName = ""
    var lastName = ""
    var email = ""
    var password = ""
    var confirm = ""

    // UI state
    var isSecurePassword = true
    var isSecureConfirm = true
    var isLoading = false
    var errorMessage: String?
    var didFinish = false

    // Basic email check (pristojan kompromis za klijent)
    private let emailRegex =
        #/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/#.ignoresCase()

    // Simple password rules (možete ih pooštriti po potrebi)
    private func isStrong(_ pwd: String) -> Bool {
        pwd.count >= 8 && pwd.rangeOfCharacter(from: .decimalDigits) != nil
            && pwd.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil
    }

    enum Strength: String {
        case weak = "Slaba"
        case medium = "Srednja"
        case strong = "Jaka"
    }
    var passwordStrength: Strength {
        switch true {
        case password.count >= 12 && isStrong(password)
            && password.rangeOfCharacter(
                from: CharacterSet.punctuationCharacters
            ) != nil:
            return .strong
        case isStrong(password):
            return .medium
        case password.isEmpty:
            return .weak
        default:
            return .weak
        }
    }

    // Per-field hints (nenametljivo; prikaži tek kad ima sadržaja ili korisnik ode dalje sa polja)
    var firstNameError: String? {
        firstName.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Unesite ime." : nil
    }
    var lastNameError: String? {
        lastName.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Unesite prezime." : nil
    }
    var emailError: String? {
        guard !email.isEmpty else { return "Unesite email adresu." }
        return email.wholeMatch(of: emailRegex) == nil
            ? "Provjerite format email adrese." : nil
    }
    var passwordError: String? {
        guard !password.isEmpty else { return "Unesite lozinku." }
        return isStrong(password)
            ? nil : "Min. 8 znakova, jedno veliko slovo i cifra."
    }
    var confirmError: String? {
        guard !confirm.isEmpty else { return "Potvrdite lozinku." }
        return confirm == password ? nil : "Lozinke se ne podudaraju."
    }

    var isFormValid: Bool {
        firstNameError == nil && lastNameError == nil && emailError == nil
            && passwordError == nil && confirmError == nil
    }

    private func clearForm() {
        firstName = ""
        lastName = ""
        email = ""
        password = ""
        confirm = ""
    }

    func register(onSuccess: @escaping () -> Void) async {
        guard !isLoading else { return }
        errorMessage = nil
        didFinish = false
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await authRepo.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password
            )
            if response.success {
                didFinish = true
                onSuccess()
            } else {
                errorMessage = response.message
            }
        } catch {

        }
    }
}
