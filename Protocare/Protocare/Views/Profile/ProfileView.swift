import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: ProfileViewModel
    let api: AuthAPI
    let authStore: AuthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    accountSection
                    supportSection
                    logoutButton
                    versionLabel
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await vm.loadProfile()
            }
            .refreshable {
                await vm.loadProfile()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            avatar

            VStack(spacing: 4) {
                Text(vm.profile.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(vm.profile.email)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }

            statsRow
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
        .padding(.bottom, 24)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 2)
                )
            Text(vm.profile.initials)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 1) {
            statItem(value: "\(vm.profile.stats.protocolsCount)", label: "PROTOCOLS")
            statItem(value: "\(vm.profile.stats.streak)", label: "STREAK", icon: "flame.fill")
            statItem(value: "\(vm.profile.stats.checkinsCount)", label: "CHECK-INS")
        }
        .padding(10)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statItem(value: String, label: String, icon: String? = nil) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("ACCOUNT")

            settingsRow(
                icon: "person.fill",
                iconColor: Color.appPrimaryDark,
                iconBg: Color.appPrimary.opacity(0.15),
                title: "Edit Profile",
                subtitle: "Name, photo, email"
            )
            divider
            settingsRow(
                icon: "bell.fill",
                iconColor: Color(red: 0.35, green: 0.50, blue: 0.85),
                iconBg: Color(red: 0.35, green: 0.50, blue: 0.85).opacity(0.12),
                title: "Notifications",
                subtitle: "Reminders & sounds"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("SUPPORT")

            settingsRow(
                icon: "questionmark.circle.fill",
                iconColor: Color.appTextSecondary,
                iconBg: Color.appTextSecondary.opacity(0.1),
                title: "Help Center"
            )
            divider
            settingsRow(
                icon: "envelope.fill",
                iconColor: Color.appTextSecondary,
                iconBg: Color.appTextSecondary.opacity(0.1),
                title: "Send Feedback"
            )
            divider
            settingsRow(
                icon: "hand.raised.fill",
                iconColor: Color.appTextSecondary,
                iconBg: Color.appTextSecondary.opacity(0.1),
                title: "Privacy Policy"
            )
            divider
            settingsRow(
                icon: "doc.text.fill",
                iconColor: Color.appTextSecondary,
                iconBg: Color.appTextSecondary.opacity(0.1),
                title: "Terms of Service"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Shared Components

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.appTextSecondary)
            .textCase(.uppercase)
            .padding(.bottom, 8)
    }

    private func settingsRow(
        icon: String,
        iconColor: Color,
        iconBg: Color,
        title: String,
        subtitle: String? = nil
    ) -> some View {
        NavigationLink {
            Text(title)
                .navigationTitle(title)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.appText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appBorder)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Divider()
            .padding(.leading, 48)
            .foregroundStyle(Color.appBorder)
    }

    private var logoutButton: some View {
        Button {
            vm.logout()
        } label: {
            Text("Log Out")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.appError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var versionLabel: some View {
        Text("Protocare 1.0.0 (42)")
            .font(.system(size: 12))
            .foregroundStyle(Color.appTextSecondary)
            .frame(maxWidth: .infinity)
    }
}
