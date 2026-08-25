import SwiftUI

struct ProtocolDetailView: View {
    @StateObject private var viewModel: ProtocolDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draggedActionId: String?
    @State private var showSettings = false
    @State private var settingsVM: ProtocolSettingsViewModel?
    private let accent = Color.appPrimary

    init(
        item: ProtocolItem,
        actionsLookup: [String: ActionItem],
        userActionsLookup: [String: ActionItem],
        api: AuthAPI,
        authStore: AuthStore,
        viewModel: ProtocolsViewModel,
        initialProtocolImageURL: String? = nil,
        autoOpenEdit: Bool = false
    ) {
        _viewModel = StateObject(wrappedValue: ProtocolDetailViewModel(
            item: item,
            actionsLookup: actionsLookup,
            userActionsLookup: userActionsLookup,
            api: api,
            authStore: authStore,
            parentViewModel: viewModel,
            initialProtocolImageURL: initialProtocolImageURL,
            autoOpenEdit: autoOpenEdit
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero

                metrics
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)

            stepsSection
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.appPrimaryDark)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        settingsVM = ProtocolSettingsViewModel(
                            item: viewModel.currentProtocol,
                            actionsLookup: viewModel.actionsLookup,
                            userActionsLookup: viewModel.userActionsLookup,
                            api: viewModel.api,
                            authStore: viewModel.authStore,
                            protocolImageURL: viewModel.protocolImageURL,
                            protocolImageId: viewModel.protocolImageId
                        )
                        showSettings = true
                    } label: {
                        Label("Edit Protocol", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("Delete Protocol", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(viewModel.protocolImageURL == nil ? Color.primary : Color.white)
                }
            }
        }
        .confirmationDialog(
            "Delete Protocol?",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProtocol()
                    if viewModel.parentViewModel.deletionErrorMessage == nil {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .navigationDestination(isPresented: $showSettings) {
            if let settingsVM {
                ProtocolSettingsView(vm: settingsVM)
            }
        }

        .task(id: viewModel.item.id) {
            await viewModel.loadInitialData()
            if viewModel.autoOpenEdit {
                settingsVM = ProtocolSettingsViewModel(
                    item: viewModel.currentProtocol,
                    actionsLookup: viewModel.actionsLookup,
                    userActionsLookup: viewModel.userActionsLookup,
                    api: viewModel.api,
                    authStore: viewModel.authStore,
                    protocolImageURL: viewModel.protocolImageURL,
                    protocolImageId: viewModel.protocolImageId
                )
                showSettings = true
                viewModel.autoOpenEdit = false
            }
        }
        .sheet(item: $viewModel.selectedAction) { action in
            if let actionStatus = viewModel.dailyStatus?.actions.first(where: { $0.protocolActionId == action.id }) {
                ActionCheckinView(
                    protocolId: viewModel.item.id,
                    protocolAction: action,
                    action: action.actionId.flatMap { viewModel.actionsLookup[$0] } ?? action.userActionId.flatMap { viewModel.userActionsLookup[$0.uuidString] },
                    vm: ActionCheckinViewModel(api: viewModel.api, authStore: viewModel.authStore, protocolId: viewModel.item.id, protocolActionId: action.id),
                    onSubmit: {
                        Task {
                            await viewModel.loadDailyStatus()
                        }
                    }
                )
            }
        }
        .sheet(item: $viewModel.selectedActionForSchedule) { action in
            let actionItem = action.actionId.flatMap { viewModel.actionsLookup[$0] }
                ?? action.userActionId.flatMap { viewModel.userActionsLookup[$0.uuidString] }
            if let actionItem {
                ScheduleActionSheet(action: actionItem) { schedule, slots in
                    Task {
                        await saveNotificationSchedule(
                            protocolAction: action,
                            actionItem: actionItem,
                            schedule: schedule,
                            slots: slots
                        )
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
        .sheet(isPresented: $viewModel.isShowingActionPicker) {
            ActionPickerView(
                api: viewModel.api,
                authStore: viewModel.authStore,
                onSelect: { actionItem in
                    Task {
                        await viewModel.addActionToProtocol(actionItem: actionItem)
                    }
                }
            )
        }
        .alert("Failed to Add Action", isPresented: .constant(viewModel.addActionError != nil), actions: {
            Button("OK") { viewModel.addActionError = nil }
        }, message: {
            Text(viewModel.addActionError ?? "")
        })
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground

            VStack(alignment: .leading, spacing: 8) {
                if let category = viewModel.currentProtocol.category {
                    Text(category.displayName.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(viewModel.protocolImageURL == nil ? .secondary : Color.white.opacity(0.7))
                        .tracking(1.5)
                }

                Text(viewModel.currentProtocol.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(viewModel.protocolImageURL == nil ? Color.primary : Color.white)

                HStack(spacing: 10) {
                    statusPill
                    stepsPill
                }
            }
            .padding(18)
        }
    }

    @ViewBuilder
    private var heroBackground: some View {
        if let urlString = viewModel.protocolImageURL, !urlString.isEmpty {
            ResilientAsyncImage(urlString: urlString) {
                heroFallbackBackground
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.15), Color.black.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            heroFallbackBackground
        }
    }

    private var heroFallbackBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator).opacity(0.08))
            )
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            metricTile(title: "Length", value: viewModel.currentProtocol.stepsLabel, system: "list.number")
            metricTile(
                title: "Streak",
                value: viewModel.dailyStatus?.completionPercentage != nil ? "\(viewModel.dailyStatus!.completionPercentage)%" : "—",
                system: "flame",
                highlight: (viewModel.dailyStatus?.completionPercentage ?? 0) > 50
            )
                metricTile(title: "Status", value: viewModel.currentProtocol.statusLabel, system: viewModel.currentProtocol.isActive == true ? "bolt.fill" : "pause.fill", highlight: viewModel.currentProtocol.isActive == true)
        }
        .frame(maxWidth: .infinity)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protocol Steps")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.isLoadingStatus {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let status = viewModel.dailyStatus {
                let sorted = status.actions.sorted(by: { $0.position < $1.position })
                VStack(spacing: 10) {
                    ForEach(sorted) { actionStatus in
                        let protocolAction = viewModel.currentProtocol.actions.first { $0.id == actionStatus.protocolActionId }
                        let categoryIcon: String = {
                            if let userActionId = actionStatus.userActionId,
                               let actionItem = viewModel.userActionsLookup[userActionId.uuidString],
                               let category = actionItem.userActionCategory {
                                return category.icon
                            }
                            return "star.fill"
                        }()
                        StepRow(
                            title: actionStatus.actionName,
                            subtitle: actionStatus.subtitle,
                            categoryIcon: categoryIcon,
                            isCompleted: actionStatus.isCompleted,
                            onCheckin: {
                                if let pa = protocolAction {
                                    viewModel.selectedAction = pa
                                }
                            },
                            onSettings: {
                                if let pa = protocolAction {
                                    viewModel.selectedActionForSchedule = pa
                                }
                            }
                        )
                        .opacity(draggedActionId == actionStatus.protocolActionId ? 0.35 : 1)
                        .draggable(actionStatus.protocolActionId) {
                            StepRowDragPreview(title: actionStatus.actionName, subtitle: actionStatus.subtitle)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            draggedActionId = nil
                            guard let droppedId = items.first,
                                  let sourceIndex = sorted.firstIndex(where: { $0.protocolActionId == droppedId })
                            else { return false }
                            let destIndex = sorted.firstIndex(where: { $0.protocolActionId == actionStatus.protocolActionId }) ?? 0
                            guard sourceIndex != destIndex else { return false }
                            Task {
                                await viewModel.reorderActions(from: IndexSet(integer: sourceIndex), to: destIndex)
                            }
                            return true
                        } isTargeted: { isTargeted in
                            draggedActionId = isTargeted ? actionStatus.protocolActionId : nil
                        }
                    }

                    Button {
                        viewModel.isShowingActionPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Action")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else if let error = viewModel.statusError {
                Text("Error loading status: \(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    private func metricTile(title: String, value: String, system: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Image(systemName: system)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(highlight ? accent : .secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(highlight ? accent : .primary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private var statusPill: some View {
        Text(viewModel.currentProtocol.statusLabel.uppercased())
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                viewModel.protocolImageURL == nil
                ? (viewModel.currentProtocol.isActive == true ? accent.opacity(0.18) : Color(.systemGray5))
                : Color.black.opacity(0.35)
            )
            .foregroundStyle(viewModel.protocolImageURL == nil ? (viewModel.currentProtocol.isActive == true ? accent : .secondary) : Color.white)
            .clipShape(Capsule())
    }

    private var stepsPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet")
                .font(.system(size: 12, weight: .semibold))
            Text(viewModel.currentProtocol.stepsLabel)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(viewModel.protocolImageURL == nil ? Color(.systemGray5) : Color.black.opacity(0.35))
        .foregroundStyle(viewModel.protocolImageURL == nil ? Color.secondary : Color.white)
        .clipShape(Capsule())
    }

    // MARK: - Notification Schedule Save

    private func saveNotificationSchedule(
        protocolAction: ProtocolAction,
        actionItem: ActionItem,
        schedule: ActionSchedule,
        slots: [ScheduleSlot]
    ) async {
        guard let token = viewModel.authStore.accessToken else { return }
        let granted = await NotificationManager.shared.requestAuthorization()
        guard granted else { return }

        let reminderSlots = slots.filter { $0.isReminderOn }
        guard !reminderSlots.isEmpty else {
            // No reminders — cancel any existing schedule for this action
            NotificationManager.shared.cancelNotificationsForSlot(
                slotId: UUID(), protocolActionId: protocolAction.id
            )
            return
        }

        for slot in reminderSlots {
            let payload = NotificationScheduleCreate(
                protocolActionId: protocolAction.id,
                preferredTime: slot.timeLabel,
                timezone: TimeZone.current.identifier,
                isEnabled: true
            )
            do {
                let result = try await viewModel.api.upsertNotificationSchedule(
                    token: token, actionId: protocolAction.id, payload: payload
                )
                NotificationManager.shared.scheduleLocalNotification(
                    schedule: result, actionName: actionItem.displayName
                )
            } catch {
                // Non-critical: per-slot upsert failure shouldn't block save
            }
        }

        // Refresh daily status to reflect schedule changes
        await viewModel.loadDailyStatus()
    }
}

private struct StepRow: View {
    let title: String
    let subtitle: String
    let categoryIcon: String
    let isCompleted: Bool
    let onCheckin: () -> Void
    let onSettings: () -> Void
    private let accent = Color.appPrimary

    var body: some View {
        HStack(spacing: 14) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(accent)
            } else {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                    Image(systemName: categoryIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .strikethrough(isCompleted)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isCompleted ? accent : .secondary)
            }

            Spacer()

            Button {
                onSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isCompleted ? accent.opacity(0.3) : Color(.separator).opacity(0.08), lineWidth: isCompleted ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCheckin()
        }
    }
}

private struct StepRowDragPreview: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "star.fill").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .frame(width: 300)
    }
}

struct ProtocolDetailView_Previews: PreviewProvider {
    struct PreviewAPI: AuthAPI {
        func register(email: String, password: String, name: String) async throws -> AccessToken { .init(userId: UUID().uuidString, accessToken: "t", refreshToken: "r", tokenType: "Bearer") }
        func login(email: String, password: String) async throws -> AccessToken { .init(userId: UUID().uuidString, accessToken: "t", refreshToken: "r", tokenType: "Bearer") }
        func refresh(request: RefreshTokenRequest) async throws -> TokenPair { .init(userId: UUID().uuidString, accessToken: "t", refreshToken: "r") }
        func logout(refreshToken: String) async throws {}
        func fetchProtocols(token: String, category: ProtocolCategory? = nil) async throws -> [ProtocolItem] { [] }
        func fetchActions(token: String, query: String? = nil) async throws -> [Action] { [] }
        func fetchSubstances(token: String, query: String? = nil) async throws -> [Substance] { [] }
        func createProtocol(token: String, payload: ProtocolCreateRequest) async throws -> ProtocolItem {
            ProtocolItem(
                id: UUID().uuidString,
                userId: payload.userId,
                name: payload.name,
                actions: payload.actions.map { action in
                    ProtocolAction(
                        id: UUID().uuidString,
                        actionId: action.actionId,
                        userActionId: action.userActionId,
                        rrule: action.rrule,
                        position: action.position,
                        checkins: nil
                    )
                },
                isActive: payload.isActive,
                startedAt: payload.startedAt,
                endedAt: payload.endedAt
            )
        }
        func deleteProtocol(token: String, protocolId: String) async throws { }
        func createProtocolWithImage(token: String, payload: ProtocolCreateRequest, imageData: Data?) async throws -> ProtocolItem {
            ProtocolItem(
                id: UUID().uuidString,
                userId: payload.userId,
                name: payload.name,
                actions: payload.actions.map { action in
                    ProtocolAction(
                        id: UUID().uuidString,
                        actionId: action.actionId,
                        userActionId: action.userActionId,
                        rrule: action.rrule,
                        position: action.position,
                        checkins: nil
                    )
                },
                isActive: payload.isActive,
                startedAt: payload.startedAt,
                endedAt: payload.endedAt
            )
        }
        func updateProtocol(token: String, protocolId: String, payload: ProtocolUpdate) async throws -> ProtocolItem {
            ProtocolItem(id: protocolId, userId: UUID().uuidString, name: payload.name ?? "Updated", actions: [], isActive: payload.isActive, startedAt: payload.startedAt, endedAt: payload.endedAt)
        }
        func createCheckin(token: String, payload: ProtocolCheckinCreate) async throws -> CheckIn {
            return CheckIn(protocolActionId: payload.protocolActionId, ts: payload.ts, appliedVolume: payload.appliedVolume, appliedDurationSeconds: payload.appliedDurationSeconds, id: UUID().uuidString, userId: nil)
        }
        func deleteCheckin(token: String, protocolId: String, checkinId: String) async throws {}
        func uploadProtocolImage(token: String, protocolId: String, imageData: Data) async throws -> ImageAttachmentCreate {
            ImageAttachmentCreate(id: UUID().uuidString, filename: "image.jpg", contentType: "image/jpeg", fileSize: imageData.count, width: 100, height: 100, url: "https://example.com/image.jpg")
        }
        func fetchProtocolImage(token: String, protocolId: String) async throws -> ImageAttachment {
            ImageAttachment(id: UUID().uuidString, ownerId: UUID().uuidString, attachableType: "protocol", attachableId: protocolId, filename: "image.jpg", contentType: "image/jpeg", fileSize: 1024, width: 100, height: 100, url: "https://example.com/image.jpg", createdAt: "2024-01-01T12:00:00Z")
        }
        func deleteImage(token: String, imageId: String) async throws { }

        // Daily Status stubs
        func fetchDailyStatus(token: String, date: Date?) async throws -> DailyStatusResponse {
            DailyStatusResponse(date: "", streak: StreakInfo(currentStreak: 0, longestStreak: 0), dailyProgressPercentage: 0, totalActions: 0, completedActions: 0, protocols: [])
        }
        func fetchProtocolDailyStatus(token: String, protocolId: String, date: Date?) async throws -> ProtocolDailyStatus {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            let dateString = fmt.string(from: date ?? Date())

            return ProtocolDailyStatus(
                protocolId: protocolId,
                date: dateString,
                totalActions: 5,
                completedActions: 2,
                completionPercentage: 40,
                actions: [
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Gentle Cleanser", position: 0, scheduledTime: "08:00", isCompleted: true, completedAt: "2024-01-01T10:00:00Z", checkinId: UUID().uuidString, appliedVolume: Quantity(amount: 2, unit: .ml), appliedDurationSeconds: nil),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Hydrating Toner", position: 1, scheduledTime: "08:05", isCompleted: true, completedAt: "2024-01-01T10:05:00Z", checkinId: UUID().uuidString, appliedVolume: Quantity(amount: 3, unit: .ml), appliedDurationSeconds: nil),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Vitamin C Serum", position: 2, scheduledTime: "08:10", isCompleted: false, completedAt: nil, checkinId: nil, appliedVolume: nil, appliedDurationSeconds: nil),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Moisturizer", position: 3, scheduledTime: "08:15", isCompleted: false, completedAt: nil, checkinId: nil, appliedVolume: nil, appliedDurationSeconds: nil),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Sunscreen SPF 50", position: 4, scheduledTime: "08:20", isCompleted: false, completedAt: nil, checkinId: nil, appliedVolume: nil, appliedDurationSeconds: nil)
                ]
            )
        }
        func fetchProtocolWithCheckins(token: String, protocolId: String) async throws -> ProtocolWithCheckins {
            ProtocolWithCheckins(id: protocolId, userId: UUID().uuidString, name: "Preview", actions: [], isActive: true, startedAt: nil, endedAt: nil)
        }
        func fetchProtocolCheckins(token: String, protocolId: String, dateFrom: Date?, dateTo: Date?) async throws -> [CheckIn] { [] }
        func fetchJournalEntries(token: String, protocolId: String, dateFrom: String?, dateTo: String?) async throws -> [JournalEntry] { [] }
        func fetchJournalEntry(token: String, protocolId: String, date: String) async throws -> JournalEntryDetail {
            JournalEntryDetail(id: UUID().uuidString, protocolId: protocolId, date: date, dayNumber: 1, metrics: [:], availableMetrics: [], checkins: [], createdAt: "2024-01-01T12:00:00Z", updatedAt: "2024-01-01T12:00:00Z")
        }
        func saveJournalEntry(token: String, protocolId: String, date: String, metrics: [String: Int], notes: String?) async throws -> JournalEntry {
            JournalEntry(id: UUID().uuidString, protocolId: protocolId, date: date, dayNumber: 1, metrics: metrics, notes: notes)
        }
        func uploadJournalPhoto(token: String, protocolId: String, date: String, imageData: Data) async throws -> JournalEntry {
            JournalEntry(id: UUID().uuidString, protocolId: protocolId, date: date, dayNumber: 1, metrics: [:], photoUrl: "https://example.com/photo.jpg")
        }
        func fetchNotificationSchedules(token: String, protocolActionId: String?) async throws -> [NotificationScheduleResponse] { [] }
        func fetchNotificationSchedule(token: String, scheduleId: String) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: scheduleId, protocolActionId: UUID().uuidString, userId: UUID().uuidString, preferredTime: "08:00", timezone: "UTC", isEnabled: true, createdAt: "2024-01-01T12:00:00Z")
        }
        func createNotificationSchedule(token: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: UUID().uuidString, protocolActionId: payload.protocolActionId, userId: UUID().uuidString, preferredTime: payload.preferredTime, timezone: payload.timezone, isEnabled: payload.isEnabled ?? true, createdAt: "2024-01-01T12:00:00Z")
        }
        func updateNotificationSchedule(token: String, scheduleId: String, payload: NotificationScheduleUpdate) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: scheduleId, protocolActionId: UUID().uuidString, userId: UUID().uuidString, preferredTime: "08:00", timezone: "UTC", isEnabled: true, createdAt: "2024-01-01T12:00:00Z")
        }
        func deleteNotificationSchedule(token: String, scheduleId: String) async throws { }
        func upsertNotificationSchedule(token: String, actionId: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: UUID().uuidString, protocolActionId: actionId, userId: UUID().uuidString, preferredTime: payload.preferredTime, timezone: payload.timezone, isEnabled: payload.isEnabled ?? true, createdAt: "2024-01-01T12:00:00Z")
        }

        func fetchUserActions(token: String, category: ActionCategory?, isActive: Bool?, page: Int?, pageSize: Int?) async throws -> PaginatedUserActions {
            PaginatedUserActions(items: [], total: 0, page: 1, pageSize: 20)
        }
        func createUserAction(token: String, payload: UserActionCreate) async throws -> UserAction {
            UserAction(id: UUID(), userId: UUID(), name: payload.name, category: payload.category)
        }
        func fetchUserAction(token: String, actionId: UUID) async throws -> UserAction {
            UserAction(id: actionId, userId: UUID(), name: "", category: .custom)
        }
        func updateUserAction(token: String, actionId: UUID, payload: UserActionUpdate) async throws -> UserAction {
            UserAction(id: actionId, userId: UUID(), name: payload.name ?? "", category: .custom)
        }
        func deleteUserAction(token: String, actionId: UUID) async throws {}
        func fetchUserActionTemplates(token: String) async throws -> [UserAction] { [] }
        func duplicateUserAction(token: String, actionId: UUID) async throws -> UserAction {
            UserAction(id: UUID(), userId: UUID(), name: "", category: .custom)
        }
        func fetchUserActionUsage(token: String, actionId: UUID) async throws -> UserActionUsage {
            []
        }

        func fetchCurrentUser(token: String) async throws -> UserMeResponse {
            UserMeResponse(id: UUID().uuidString, email: "preview@protocare.app", name: "Preview", avatarURL: nil, isActive: true, role: "user", timezone: nil, protocolsCount: 3, streak: StreakInfo(currentStreak: 7, longestStreak: 14), totalCheckins: 42)
        }
        func updateProfile(token: String, payload: ProfileUpdateRequest) async throws -> UserMeResponse {
            UserMeResponse(id: UUID().uuidString, email: "preview@protocare.app", name: "Preview", avatarURL: nil, isActive: true, role: "user", timezone: nil, protocolsCount: 3, streak: StreakInfo(currentStreak: 7, longestStreak: 14), totalCheckins: 42)
        }
        func uploadProfileImage(token: String, imageData: Data) async throws -> UserMeResponse {
            UserMeResponse(id: UUID().uuidString, email: "preview@protocare.app", name: "Preview", avatarURL: nil, isActive: true, role: "user", timezone: nil, protocolsCount: 3, streak: StreakInfo(currentStreak: 7, longestStreak: 14), totalCheckins: 42)
        }
        func deleteAccount(token: String) async throws {}
        func reorderProtocolActions(token: String, protocolId: String, actionIds: [String]) async throws {}
        func fetchProtocolNotificationSchedules(token: String, protocolId: String) async throws -> [String: NotificationScheduleResponse] { [:] }
        func addActionToProtocol(token: String, protocolId: String, payload: ProtocolActionCreate) async throws -> ProtocolItem {
            let newAction = ProtocolAction(
                id: UUID().uuidString,
                actionId: payload.actionId,
                userActionId: payload.userActionId,
                rrule: payload.rrule,
                position: payload.position ?? 0,
                checkins: nil
            )
            return ProtocolItem(
                id: protocolId,
                userId: UUID().uuidString,
                name: "Preview Protocol",
                actions: [newAction],
                isActive: true,
                startedAt: nil,
                endedAt: nil
            )
        }
        func removeActionFromProtocol(token: String, protocolId: String, protocolActionId: String) async throws {}

        func fetchMetricsTrend(token: String, protocolId: String, days: Int?) async throws -> MetricTrendResponse {
            MetricTrendResponse(protocolId: protocolId, days: 14, series: [])
        }
    }

    static var previews: some View {
        let api = PreviewAPI()
        let authStore: AuthStore = {
            let store = AuthStore()
            store.setAuth(tokens: AuthTokens(userId: UUID().uuidString, accessToken: "preview", refreshToken: "preview", tokenType: "Bearer"))
            return store
        }()
        let vm = ProtocolsViewModel(api: api, authStore: authStore)

        return ProtocolDetailView(
            item: ProtocolItem(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                name: "Morning Glow",
                actions: [
                    ProtocolAction(id: UUID().uuidString, actionId: UUID().uuidString, rrule: "Daily at 8:00 AM", position: 0, checkins: nil),
                    ProtocolAction(id: UUID().uuidString, actionId: UUID().uuidString, rrule: "Daily at 8:20 AM", position: 1, checkins: nil),
                    ProtocolAction(id: UUID().uuidString, actionId: UUID().uuidString, rrule: "Daily at 8:30 AM", position: 2, checkins: nil),
                    ProtocolAction(id: UUID().uuidString, actionId: UUID().uuidString, rrule: "Daily at 8:35 AM", position: 3, checkins: nil)
                ],
                isActive: true,
                startedAt: "2026-01-01",
                endedAt: nil
            ),
            actionsLookup: [:],
            userActionsLookup: [:],
            api: api,
            authStore: authStore,
            viewModel: vm
        )
    }
}
