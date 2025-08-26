//
//  LoginViewModel.swift
//  FitSocial
//
//  Created by Dragan Kos on 13. 8. 2025..
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    private let authRepo: AuthRepository
    init(authRepo: AuthRepository) { self.authRepo = authRepo }

    var email = ""
    var password = ""
    var isLoading = false
    var isSecure = true
    var error: String?

    var isValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }
    
    private func clearForm(){
        email = ""
        password = ""
    }

    func login(
        onSuccess: @escaping (
            _ access: String, _ refresh: String?, _ user: User?
        ) -> Void
    ) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let res = try await authRepo.loginReturningTokens(
                    email: email,
                    password: password
                )
                onSuccess(res.token, res.refreshToken, res.user)
                clearForm()
            } catch {
                if let apiErr = error as? APIError {
                    switch apiErr {
                    case .unauthorized:
                        self.error =
                            "Prijava nije uspjela. Provjerite unesene podatke."
                    default:
                        self.error = error.localizedDescription
                    }
                } else {
                    self.error = error.localizedDescription
                }

            }
        }
    }
    func forgotPassword() {
        // Otvori ekran/opciju za reset lozinke
    }

    func register() {
        // Navigacija na registraciju
    }
}
