import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var vm: NotificationSettingsViewModel

    private let accent = Color.appPrimary

    init(api: AuthAPI, authStore: AuthStore) {
        _vm = StateObject(wrappedValue: NotificationSettingsViewModel(api: api, authStore: authStore))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading && vm.items.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 60)
                } else if let error = vm.errorMessage, vm.items.isEmpty {
                    errorView(error)
                } else if vm.items.isEmpty {
                    emptyView
                } else {
                    counterCard
                    timelineList
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    // MARK: - Counter Card

    private var counterCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.appBody)
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.activeCount) of \(vm.totalCount) active")
                    .font(.appCardTitle)
                    .foregroundStyle(Color.appText)
                Text("Toggle reminders on or off")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        VStack(spacing: 0) {
            ForEach(vm.items) { item in
                timelineRow(item: item)
            }
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private func timelineRow(item: NotificationScheduleItem) -> some View {
        // 0 = top (midnight), 1 = bottom (23:59)
        let timeFraction = timeToFraction(item.preferredTime)
        let dotDiameter: CGFloat = 10
        let rowHeight: CGFloat = 56 // consistent row height for dot positioning

        return HStack(spacing: 14) {
            // Time column (24h format)
            Text(item.preferredTime)
                .font(.appCaptionBold)
                .foregroundStyle(Color.appText)
                .frame(width: 52, alignment: .trailing)

            // Timeline dot + connector — dot position reflects time of day
            ZStack(alignment: .top) {
                // Full-height vertical line
                Rectangle()
                    .fill(Color.appBorder)
                    .frame(width: 2)

                // Dot positioned by time: top = early, bottom = late
                Circle()
                    .fill(item.isEnabled ? accent : Color.appBorder)
                    .frame(width: dotDiameter, height: dotDiameter)
                    .offset(y: timeFraction * (rowHeight - dotDiameter))
            }
            .frame(minWidth: dotDiameter, idealWidth: dotDiameter, maxWidth: dotDiameter, minHeight: rowHeight, idealHeight: rowHeight)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.actionName)
                    .font(.appCardTitle)
                    .foregroundStyle(Color.appText)
                Text(item.protocolName)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Toggle
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in vm.toggleItem(item) }
            ))
            .tint(accent)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.appEmptyStateIcon)
                .foregroundStyle(Color.appBorder)
            Text("No Reminders Set")
                .font(.appCardTitle)
                .foregroundStyle(Color.appText)
            Text("When you schedule reminders for your protocol actions, they'll appear here.")
                .font(.appBody)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.appBody)
                .foregroundStyle(Color.appError)
            Button("Retry") {
                Task { await vm.load() }
            }
            .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Helpers

    /// Converts "HH:MM" to 0...1 where 0 = midnight, 1 = 23:59
    private func timeToFraction(_ time: String) -> CGFloat {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return 0.5
        }
        let totalMinutes = hour * 60 + minute
        return CGFloat(totalMinutes) / CGFloat(23 * 60 + 59)
    }
}
