//
//  RegistrationViewModel.swift
//  Protocare
//
//  Created by Alex Gorev on 13.12.2025.
//

import Foundation
import Combine

@MainActor
final class RegistrationViewModel: ObservableObject {
    // Ввод пользователя
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    // UI состояние
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isRegistered: Bool = false
    
    private let api: AuthAPI
    private let authStore: AuthStore
    
    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }
    
    var canSubmit: Bool {
        guard email.isValidEmail else { return false }
        guard password.count >= 8 else { return false }
        guard password == passwordConfirmation else { return false }
        return !isLoading
    }
    
    func submit() async {
        errorMessage = nil
        guard canSubmit else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await api.register(email: email, password: password)
            authStore.setAuth(tokens: result)
            isRegistered = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Неизвестная ошибка"
        }
    }
}


