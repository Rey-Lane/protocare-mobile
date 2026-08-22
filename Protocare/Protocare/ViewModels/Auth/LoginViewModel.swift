//
//  LoginViewModel.swift
//  Protocare
//
//  Created by Codex on 21.12.2025.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false

    private let api: AuthAPI
    private let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    var canSubmit: Bool {
        guard email.isValidEmail else { return false }
        guard password.count >= 8 else { return false }
        return !isLoading
    }

    func submit() async {
        guard canSubmit else {
            errorMessage = "Введите корректный email и пароль (мин. 8 символов)."
            return
        }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await api.login(email: email, password: password)
            authStore.setAuth(tokens: result)
            isLoggedIn = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Неизвестная ошибка"
        }
    }
}
