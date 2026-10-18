import SwiftUI

struct AuthContainerView: View {
    let api: AuthAPI
    let authStore: AuthStore

    @State private var selectedTab: PillTabSwitcher.AuthTab = .login
    @StateObject private var loginVM: LoginViewModel
    @StateObject private var registerVM: RegistrationViewModel

    private let softWhite = Color.appBackground

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
        _loginVM = StateObject(wrappedValue: LoginViewModel(api: api, authStore: authStore))
        _registerVM = StateObject(wrappedValue: RegistrationViewModel(api: api, authStore: authStore))
    }

    var body: some View {
        ZStack {
            softWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        header
                        formContent
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
                }

                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PillTabSwitcher(selectedTab: $selectedTab)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
        }
        .alert("Success", isPresented: successBinding) {
            Button("OK") {}
        } message: {
            Text(selectedTab == .login ? "Signed in. Token saved." : "Account created. Token saved.")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(selectedTab == .login ? "Welcome Back" : "Create Account")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.appText)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: selectedTab)

            Text(selectedTab == .login ? "Log in to your wellness space" : "Start your personalized journey")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var formContent: some View {
        switch selectedTab {
        case .login:
            LoginFormView(vm: loginVM)
        case .register:
            RegistrationFormView(vm: registerVM)
        }
    }

    private var successBinding: Binding<Bool> {
        Binding(
            get: { loginVM.isLoggedIn || registerVM.isRegistered },
            set: { _ in
                loginVM.isLoggedIn = false
                registerVM.isRegistered = false
            }
        )
    }
}
