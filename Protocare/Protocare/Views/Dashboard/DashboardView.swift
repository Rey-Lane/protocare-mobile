import SwiftUI

struct DailyDashboardView: View {
    @ObservedObject var vm: DailyDashboardViewModel
    let api: AuthAPI
    let authStore: AuthStore
    @ObservedObject var profileVM: ProfileViewModel

    private let accent = Color.appPrimary

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if vm.isLoading && vm.dailyStatus == nil {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let error = vm.errorMessage, vm.dailyStatus == nil {
                    VStack(spacing: 12) {
                        Text(error)
                            .foregroundStyle(Color.appError)
                        Button("Retry") { Task { await vm.load() } }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
                } else if let status = vm.dailyStatus {
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.appBody)
                            .foregroundStyle(Color.appError)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    WeekCalendarView(selectedDate: $vm.selectedDate)

                    if !vm.isViewingToday {
                        pastDayBanner
                    }

                    statsRow(streak: status.streak, percentage: status.dailyProgressPercentage)
                    protocolsSection(status.protocols)
                }
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await profileVM.loadProfile()
            await vm.load()
        }
        .refreshable {
            await profileVM.loadProfile()
            await vm.load()
        }
    }

    private var pastDayBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
            Text("Viewing past day — check-ins are read-only")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                Text(userName)
                    .font(.appScreenTitle)
            }
            Spacer()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5, hour < 12 { return "Good morning," }
        if hour >= 12, hour < 17 { return "Good afternoon," }
        return "Good evening,"
    }

    private var userName: String {
        let name = profileVM.profile.name
        if name == "—" || name.isEmpty {
            return "there"
        }
        // Use first name only for the greeting
        return name.components(separatedBy: " ").first ?? name
    }

    private func statsRow(streak: StreakInfo, percentage: Int) -> some View {
        HStack(spacing: 12) {
            StreakCardView(streak: streak)
            ProgressCardView(percentage: percentage)
        }
    }

    private func protocolsSection(_ protocols: [DailyProtocolStatus]) -> some View {
        VStack(spacing: 16) {
            if protocols.isEmpty {
                emptyProtocolsView
            } else {
                ForEach(protocols) { proto in
                    protocolSection(proto)
                }
            }
        }
    }

    private var emptyProtocolsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.appEmptyStateIcon)
                .foregroundStyle(Color.appTextSecondary.opacity(0.5))
            Text("No active protocols yet")
                .font(.appCardTitle)
            Text("Create your first protocol to start tracking your routine.")
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
            NavigationLink {
                ProtocolBuilderView(api: api, authStore: authStore)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Protocol")
                }
                .font(.appBody.weight(.semibold))
                .foregroundStyle(Color.appOnAccent)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(accent)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func protocolSection(_ proto: DailyProtocolStatus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(proto.protocolName)
                    .font(.appCardTitle)
                Spacer()
                Text("\(proto.completedActions)/\(proto.totalActions) Done")
                    .font(.appCaption.weight(.medium))
                    .foregroundStyle(proto.completedActions == proto.totalActions && proto.totalActions > 0 ? accent : Color.appTextSecondary)
            }

            ForEach(proto.actions) { action in
                ActionRowView(action: action, isReadOnly: !vm.isViewingToday, onToggle: {
                    Task { await vm.toggleAction(protocolId: proto.protocolId, action: action) }
                }, onCheckinWithDosage: { quantity, unit, duration in
                    Task {
                        await vm.performCheckin(
                            protocolId: proto.protocolId,
                            action: action,
                            quantity: quantity,
                            unit: unit,
                            durationSeconds: duration
                        )
                    }
                })
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: Color.appText.opacity(0.04), radius: 8, y:4)
    }
}
