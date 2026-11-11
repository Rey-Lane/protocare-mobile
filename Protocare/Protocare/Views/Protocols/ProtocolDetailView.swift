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
        api: AuthAPI,
        authStore: AuthStore,
        viewModel: ProtocolsViewModel,
        initialProtocolImageURL: String? = nil,
        autoOpenEdit: Bool = false
    ) {
        _viewModel = StateObject(wrappedValue: ProtocolDetailViewModel(
            item: item,
            actionsLookup: actionsLookup,
            api: api,
            authStore: authStore,
            parentViewModel: viewModel,
            initialProtocolImageURL: initialProtocolImageURL,
            autoOpenEdit: autoOpenEdit
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero

                metrics
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.bottom, 8)

            stepsSection
                .padding(.horizontal, AppSpacing.pagePadding)
                .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle(viewModel.currentProtocol.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(Color.appPrimaryDark)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        settingsVM = ProtocolSettingsViewModel(
                            item: viewModel.currentProtocol,
                            actionsLookup: viewModel.actionsLookup,
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
                        .font(.appScreenTitle)
                        .foregroundStyle(viewModel.protocolImageURL == nil ? Color.appText : Color.appOnAccent)
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
                    action: viewModel.actionsLookup[action.actionId],
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
            // Unified model (Step 23): single non-optional action_id lookup.
            // Bug #4 fix: hydrate slots/schedule from the stored ProtocolAction
            // so the sheet shows the persisted time instead of the 8:00 default
            // (and Save no longer overwrites the real schedule).
            let actionItem = viewModel.actionsLookup[action.actionId]?.hydrated(from: action)
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
                        .font(.appCaptionBold)
                        .foregroundStyle(viewModel.protocolImageURL == nil ? Color.appTextSecondary : Color.appOnAccent.opacity(0.7))
                        .tracking(1.5)
                }

                HStack(spacing: 8) {
                    statusPill
                    stepsPill
                }
            }
            .padding(16)
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
                    colors: [Color.appText.opacity(0.15), Color.appText.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.viewer, style: .continuous))
        } else {
            heroFallbackBackground
        }
    }

    private var heroFallbackBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.viewer, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.viewer, style: .continuous)
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
                .font(.appSectionTitle)
                .padding(.horizontal, 4)

            if viewModel.isLoadingStatus {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let status = viewModel.dailyStatus {
                let sorted = status.actions.sorted(by: { $0.position < $1.position })
                VStack(spacing: 12) {
                    ForEach(sorted) { actionStatus in
                        let protocolAction = viewModel.currentProtocol.actions.first { $0.id == actionStatus.protocolActionId }
                        // Unified model (Step 23): single action_id resolution —
                        // category icon comes straight from the unified Action.
                        let resolvedAction = actionStatus.actionId.flatMap { viewModel.actionsLookup[$0] }
                        let categoryIcon = resolvedAction?.category.tagIcon ?? "star.fill"
                        StepRow(
                            title: actionStatus.actionName,
                            subtitle: actionStatus.subtitle,
                            categoryIcon: categoryIcon,
                            category: resolvedAction?.category,
                            modality: resolvedAction?.modality,
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
                                .font(.appBody.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else if let error = viewModel.statusError {
                Text("Error loading status: \(error)")
                    .foregroundStyle(Color.appError)
                    .font(.appCaption)
            }
        }
    }

    private func metricTile(title: String, value: String, system: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.appCaptionBold)
                .foregroundStyle(Color.appTextSecondary)
            HStack(spacing: 4) {
                Image(systemName: system)
                    .font(.appCaptionBold)
                    .foregroundStyle(highlight ? accent : Color.appTextSecondary)
                Text(value)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(highlight ? accent : Color.appText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private var statusPill: some View {
        Text(viewModel.currentProtocol.statusLabel.uppercased())
            .font(.appCaptionBold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                viewModel.protocolImageURL == nil
                ? (viewModel.currentProtocol.isActive == true ? accent.opacity(0.18) : Color(.systemGray5))
                : Color.appText.opacity(0.35)
            )
            .foregroundStyle(viewModel.protocolImageURL == nil ? (viewModel.currentProtocol.isActive == true ? accent : Color.appTextSecondary) : Color.appOnAccent)
            .clipShape(Capsule())
    }

    private var stepsPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "list.bullet")
                .font(.appCaptionBold)
            Text(viewModel.currentProtocol.stepsLabel)
                .font(.appCaptionBold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(viewModel.protocolImageURL == nil ? Color(.systemGray5) : Color.appText.opacity(0.35))
        .foregroundStyle(viewModel.protocolImageURL == nil ? Color.appTextSecondary : Color.appOnAccent)
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
    var category: ActionCategory?
    var modality: ActionModality?
    let isCompleted: Bool
    let onCheckin: () -> Void
    let onSettings: () -> Void
    private let accent = Color.appPrimary

    var body: some View {
        HStack(spacing: 12) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.appScreenTitle)
                    .foregroundStyle(accent)
            } else {
                ZStack {
                    Circle()
                        .fill((category?.tagColor ?? Color(.systemGray5)).opacity(0.16))
                    Image(systemName: categoryIcon)
                        .font(.appCaptionBold)
                        .foregroundStyle(category?.tagColor ?? Color.appTextSecondary)
                }
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appCardTitle)
                    .strikethrough(isCompleted)
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(isCompleted ? accent : Color.appTextSecondary)
                // Unified model (Step 23): show category/modality instead of
                // the old "Library"/"Custom" provenance labels.
                if !isCompleted, let category {
                    HStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: category.tagIcon)
                                .font(.appCaptionBold)
                            Text(category.displayName)
                                .font(.appCaptionBold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .foregroundStyle(category.tagColor)
                        .background(category.tagColor.opacity(0.14))
                        .clipShape(Capsule())

                        if let modality {
                            Text(modality.displayName)
                                .font(.appCaption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .foregroundStyle(Color.appTextSecondary)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Button {
                onSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
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
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "star.fill").font(.appCaptionBold).foregroundStyle(Color.appTextSecondary))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appCardTitle)
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
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
        func fetchProtocols(token: String, category: ActionCategory? = nil) async throws -> [ProtocolItem] { [] }
        func fetchActions(token: String, category: ActionCategory? = nil, modality: ActionModality? = nil, query: String? = nil, libraryOnly: Bool? = nil) async throws -> [Action] { [] }
        func createAction(token: String, payload: ActionCreate) async throws -> Action {
            Action(id: UUID().uuidString, name: payload.name, description: payload.description, category: payload.category, modality: payload.modality)
        }
        func updateAction(token: String, actionId: String, payload: ActionUpdate) async throws -> Action {
            Action(id: actionId, name: payload.name ?? "", category: payload.category ?? .custom)
        }
        func createProtocol(token: String, payload: ProtocolCreateRequest) async throws -> ProtocolItem {
            ProtocolItem(
                id: UUID().uuidString,
                userId: payload.userId,
                name: payload.name,
                actions: payload.actions.map { action in
                    ProtocolAction(
                        id: UUID().uuidString,
                        actionId: action.actionId,
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
            return CheckIn(protocolActionId: payload.protocolActionId, ts: payload.ts, quantity: payload.quantity, unit: payload.unit, durationSeconds: payload.durationSeconds, completed: payload.completed, id: UUID().uuidString, userId: nil)
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
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Gentle Cleanser", position: 0, scheduledTime: "08:00", isCompleted: true, completedAt: "2024-01-01T10:00:00Z", checkinId: UUID().uuidString, quantity: 2, unit: .ml, durationSeconds: nil, completed: true),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Hydrating Toner", position: 1, scheduledTime: "08:05", isCompleted: true, completedAt: "2024-01-01T10:05:00Z", checkinId: UUID().uuidString, quantity: 3, unit: .ml, durationSeconds: nil, completed: true),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Vitamin C Serum", position: 2, scheduledTime: "08:10", isCompleted: false, completedAt: nil, checkinId: nil, quantity: nil, unit: nil, durationSeconds: nil, completed: true),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Moisturizer", position: 3, scheduledTime: "08:15", isCompleted: false, completedAt: nil, checkinId: nil, quantity: nil, unit: nil, durationSeconds: nil, completed: true),
                    ActionCheckinStatus(protocolActionId: UUID().uuidString, actionId: UUID().uuidString, actionName: "Sunscreen SPF 50", position: 4, scheduledTime: "08:20", isCompleted: false, completedAt: nil, checkinId: nil, quantity: nil, unit: nil, durationSeconds: nil, completed: true)
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
        func fetchOnboarding(token: String) async throws -> OnboardingState { OnboardingState() }
        func patchOnboarding(token: String, payload: OnboardingUpdateRequest) async throws -> OnboardingState { OnboardingState() }
        func resetOnboarding(token: String) async throws -> OnboardingState { OnboardingState() }
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
            api: api,
            authStore: authStore,
            viewModel: vm
        )
    }
}
