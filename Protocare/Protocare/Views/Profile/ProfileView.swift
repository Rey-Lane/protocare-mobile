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
                    .font(.appScreenTitle)
                    .foregroundStyle(Color.appOnAccent)
                Text(vm.profile.email)
                    .font(.appCaption)
                    .foregroundStyle(Color.appOnAccent.opacity(0.8))
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
        ResilientAsyncImage(urlString: vm.profile.avatarURL, contentMode: .fill) {
            initialsCircle
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.appOnAccent.opacity(0.4), lineWidth: 2)
        )
    }

    private var initialsCircle: some View {
        Circle()
            .fill(Color.appOnAccent.opacity(0.25))
            .frame(width: 64, height: 64)
            .overlay(
                Circle()
                    .stroke(Color.appOnAccent.opacity(0.4), lineWidth: 2)
            )
            .overlay {
                Text(vm.profile.initials)
                    .font(.appSectionTitle)
                    .foregroundStyle(Color.appOnAccent)
            }
    }

    private var statsRow: some View {
        HStack(spacing: 1) {
            statItem(value: "\(vm.profile.stats.protocolsCount)", label: "PROTOCOLS")
            statItem(value: "\(vm.profile.stats.streak)", label: "STREAK", icon: "flame.fill")
            statItem(value: "\(vm.profile.stats.checkinsCount)", label: "CHECK-INS")
        }
        .padding(10)
        .background(Color.appOnAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func statItem(value: String, label: String, icon: String? = nil) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Text(value)
                    .font(.appNumericDisplay)
                    .foregroundStyle(Color.appOnAccent)
                if let icon {
                    Image(systemName: icon)
                        .font(.appCaption)
                        .foregroundStyle(Color.appOnAccent.opacity(0.7))
                }
            }
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appOnAccent.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("ACCOUNT")

            editProfileRow
            divider
            notificationsRow
            divider
            replayOnboardingRow
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
            .font(.appCaptionBold)
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
                    .font(.appBody)
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.appCardTitle)
                        .foregroundStyle(Color.appText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaptionBold)
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

    // MARK: - Notifications Row

    private var editProfileRow: some View {
        NavigationLink {
            EditProfileView(vm: vm, api: api, authStore: authStore)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.fill")
                    .font(.appBody)
                    .foregroundStyle(Color.appPrimaryDark)
                    .frame(width: 34, height: 34)
                    .background(Color.appPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Edit Profile")
                        .font(.appCardTitle)
                        .foregroundStyle(Color.appText)
                    Text("Name, photo")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaptionBold)
                    .foregroundStyle(Color.appBorder)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notifications Row

    private var notificationsRow: some View {
        NavigationLink {
            NotificationSettingsView(api: api, authStore: authStore)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "bell.fill")
                    .font(.appBody)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .font(.appCardTitle)
                        .foregroundStyle(Color.appText)
                    Text("Reminders & schedules")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaptionBold)
                    .foregroundStyle(Color.appBorder)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Replay Onboarding Row

    private var replayOnboardingRow: some View {
        Button {
            Task { await vm.replayOnboarding() }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.appBody)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Replay onboarding")
                        .font(.appCardTitle)
                        .foregroundStyle(Color.appText)
                    Text("Run the setup wizard again")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appCaptionBold)
                    .foregroundStyle(Color.appBorder)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var logoutButton: some View {
        Button {
            vm.logout()
        } label: {
            Text("Log Out")
                .font(.appBody.weight(.semibold))
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
            .font(.appCaption)
            .foregroundStyle(Color.appTextSecondary)
            .frame(maxWidth: .infinity)
    }
}
