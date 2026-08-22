//
//  DependencyInjection.swift
//  Protocare
//
//  Dependency injection container using SwiftUI Environment
//

import SwiftUI

private struct APIKey: EnvironmentKey {
    static let defaultValue: AuthAPI? = nil
}

private struct AuthStoreKey: EnvironmentKey {
    static let defaultValue: AuthStore? = nil
}

extension EnvironmentValues {
    var api: AuthAPI? {
        get { self[APIKey.self] }
        set { self[APIKey.self] = newValue }
    }
    
    var authStore: AuthStore? {
        get { self[AuthStoreKey.self] }
        set { self[AuthStoreKey.self] = newValue }
    }
}

extension View {
    func withAPI(_ api: AuthAPI) -> some View {
        environment(\.api, api)
    }
    
    func withAuthStore(_ authStore: AuthStore) -> some View {
        environment(\.authStore, authStore)
    }
}
