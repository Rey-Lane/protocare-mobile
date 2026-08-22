import SwiftUI

@main
struct ProtocareApp: App {
    @StateObject private var authStore = AuthStore()
    private let api: APIClient
    @State private var showSplash = true

    init() {
        let api = APIClient(baseURL: AppEnvironment.current.baseURL)
        self.api = api
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView(
                    authStore: authStore,
                    api: api
                )
                .onAppear {
                    api.configure(authStore: authStore)
                    authStore.api = api
                }
                .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .task {
                            // Minimum splash display time (brand visibility).
                            async let minimumDelay: Void = Task.sleep(for: .seconds(1.5))
                            // Validate stored auth tokens (refresh if expired).
                            async let validation: Void = authStore.validateStoredAuth()

                            // Wait for both: brand splash + auth validation.
                            _ = try? await (minimumDelay, validation)

                            withAnimation(.easeOut(duration: 0.35)) {
                                showSplash = false
                            }
                        }
                }
            }
        }
    }
}
