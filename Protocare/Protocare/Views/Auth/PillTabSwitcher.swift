import SwiftUI

struct PillTabSwitcher: View {
    enum AuthTab { case login, register }

    @Binding var selectedTab: AuthTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(title: "Login", icon: "arrow.right.to.line", tab: .login)
            tabButton(title: "Register", icon: "person.badge.plus", tab: .register)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(Color.appSurface.opacity(0.7))
                .shadow(color: Color.appText.opacity(0.04), radius: 12, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.appSurface.opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }

    private func tabButton(title: String, icon: String, tab: AuthTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.appBody.weight(.semibold))
                Text(title)
                    .font(.appCaptionBold)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextSecondary)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.appSurface)
                        .shadow(color: Color.appText.opacity(0.06), radius: 4, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

