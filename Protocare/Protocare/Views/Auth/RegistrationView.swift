import SwiftUI

struct RegistrationFormView: View {
    @ObservedObject var vm: RegistrationViewModel
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password, confirm }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            formCard

            if vm.password.count > 0 && vm.password.count < 8 {
                Text("Password must be at least 8 characters.")
                    .font(.appCaption)
                    .foregroundStyle(Color.appError)
            }

            if vm.passwordConfirmation.count > 0 && vm.passwordConfirmation != vm.password {
                Text("Passwords do not match.")
                    .font(.appCaption)
                    .foregroundStyle(Color.appError)
            }

            submitButton

            if let error = vm.errorMessage {
                Text(error)
                    .font(.appCaption)
                    .foregroundStyle(Color.appError)
            }

            termsText
        }
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            fieldRow(
                icon: "person",
                placeholder: "Your Name",
                text: $vm.name,
                field: .name
            )

            Divider().padding(.leading, 44).padding(.vertical, 4)

            fieldRow(
                icon: "envelope",
                placeholder: "Email Address",
                text: $vm.email,
                field: .email,
                keyboardType: .emailAddress
            )

            Divider().padding(.leading, 44).padding(.vertical, 4)

            fieldRow(
                icon: "lock",
                placeholder: "Password (min 8 chars)",
                text: $vm.password,
                field: .password,
                isSecure: true
            )

            Divider().padding(.leading, 44).padding(.vertical, 4)

            fieldRow(
                icon: "lock.rotation",
                placeholder: "Confirm Password",
                text: $vm.passwordConfirmation,
                field: .confirm,
                isSecure: true
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: Color.appText.opacity(0.04), radius: 16, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color.appText.opacity(0.03), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private var submitButton: some View {
        Button {
            Task { await vm.submit() }
        } label: {
            HStack {
                Spacer()
                if vm.isLoading {
                    ProgressView().tint(Color.appOnAccent)
                } else {
                    Text("Create Account")
                        .font(.appBody.weight(.bold))
                        .foregroundStyle(Color.appOnAccent)
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(Color.appPrimary)
            )
            .shadow(color: Color.appPrimary.opacity(0.25), radius: 16, y: 8)
        }
        .disabled(!vm.canSubmit)
        .opacity(vm.canSubmit ? 1 : 0.6)
    }

    private var termsText: some View {
        (
            Text("By continuing, you agree to our ")
            + Text("Terms of Service").fontWeight(.semibold).foregroundStyle(Color.appPrimary)
            + Text(" and ")
            + Text("Privacy Policy").fontWeight(.semibold).foregroundStyle(Color.appPrimary)
            + Text(".")
        )
        .font(.appCaption)
        .foregroundStyle(Color.appTextSecondary)
        .multilineTextAlignment(.center)
    }

    private func fieldRow(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appSectionTitle)
                .foregroundStyle(focusedField == field ? Color.appPrimaryDark : Color.appTextSecondary)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.appBody)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: text)
                    .font(.appBody)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
            }
        }
        .padding(.vertical, 12)
    }
}
