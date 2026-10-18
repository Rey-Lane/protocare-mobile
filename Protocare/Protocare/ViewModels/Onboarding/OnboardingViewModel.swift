//
//  OnboardingViewModel.swift
//  Protocare
//
//  Drives the 6-step onboarding wizard (spec: docs/onboarding-spec-v2.md).
//  Server is the source of truth — every advance/skip persists a PATCH so
//  progress survives app-kill; the client is a stateless wizard driver.
//

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var state: OnboardingState?
    @Published var currentStepIndex: Int = 0
    @Published var selectedCategories: [ActionCategory] = []
    @Published var protocolName: String = ""
    @Published private(set) var createdProtocolId: String?
    @Published var availableActions: [ActionItem] = []
    @Published var chosenAction: ActionItem?
    @Published var timeSlot = ScheduleSlot(hour: 8, minute: 0, isReminderOn: true, reminderOffsetMinutes: 0)
    @Published var reminderEnabled: Bool = true
    @Published private(set) var notificationPermissionGranted: Bool?
    @Published private var createdProtocolActionId: String?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSaving: Bool = false
    @Published var errorMessage: String?

    let api: AuthAPI
    let authStore: AuthStore

    var steps: [OnboardingStep] { OnboardingStep.allCases }
    var currentStep: OnboardingStep { OnboardingStep(index: currentStepIndex) }

    /// Present the wizard while the server says the flow is unfinished.
    var shouldShow: Bool { state?.shouldShow ?? false }

    /// Server-known furthest step. Swipe may revisit it and anything before
    /// (spec §1: backward navigation is always allowed); forward progress
    /// beyond it happens only via the step CTAs, which persist a PATCH first.
    var serverStepIndex: Int { state?.step.index ?? 0 }

    /// Inline hint shown when a forward swipe is rejected (copy deck).
    var gateHint: String? {
        switch currentStep {
        case .category where selectedCategories.isEmpty:
            return "Select at least one."
        default:
            return nil
        }
    }

    // MARK: - Done-step summary

    var summaryFocus: String { selectedCategories.map(\.displayName).joined(separator: ", ") }
    var summaryProtocolName: String { protocolName }
    var summaryActions: String {
        guard let chosenAction else { return "—" }
        return "1 · \(chosenAction.name)"
    }
    var summaryReminder: String {
        reminderEnabled ? "✓ \(timeSlot.timeLabel)" : "— off"
    }

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    // MARK: - Step Gating

    func canContinue(_ step: OnboardingStep) -> Bool {
        switch step {
        case .welcome:
            return true
        case .category:
            return !selectedCategories.isEmpty
        case .firstProtocol:
            return !protocolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
        case .firstAction:
            return chosenAction != nil && !isSaving
        case .notifications, .done:
            return !isSaving
        }
    }

    /// Swipe gate: free navigation within the server-known progress only.
    func canMove(to index: Int) -> Bool {
        guard index >= 0, index < steps.count else { return false }
        return index <= serverStepIndex
    }

    // MARK: - Loading

    func loadState() async {
        guard !isLoading else { return }
        guard let token = authStore.accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await api.fetchOnboarding(token: token)
            applyState(fetched)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load onboarding state."
        }
    }

    private func applyState(_ newState: OnboardingState) {
        state = newState
        currentStepIndex = newState.step.index

        // A fresh/reset state (welcome + not_started — either the server's
        // synthetic default or the replay reset) starts with clean drafts;
        // don't carry stale selections over from a previous run.
        if newState.step == .welcome, newState.status == .notStarted {
            selectedCategories = []
            protocolName = ""
            createdProtocolId = nil
            createdProtocolActionId = nil
            chosenAction = nil
            availableActions = []
            reminderEnabled = true
            notificationPermissionGranted = nil
        }

        // Hydrate wizard drafts from merged server context (resume / replay).
        if let rawCategories = newState.context.selectedCategories {
            let categories = rawCategories.compactMap { ActionCategory(rawValue: $0) }
            if !categories.isEmpty {
                selectedCategories = categories
            }
        }
        if protocolName.isEmpty, let name = newState.context.firstProtocolName {
            protocolName = name
        }
        if createdProtocolId == nil, let protocolId = newState.context.firstProtocolId {
            createdProtocolId = protocolId
        }
        prefillProtocolNameIfNeeded()
    }

    private func prefillProtocolNameIfNeeded() {
        guard protocolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let topCategory = selectedCategories.first else { return }
        protocolName = "\(topCategory.displayName) routine"
    }

    // MARK: - Step Actions

    @discardableResult
    func continueFromWelcome() async -> Bool {
        await advance(to: .category)
    }

    @discardableResult
    func continueFromCategory() async -> Bool {
        guard canContinue(.category) else { return false }
        prefillProtocolNameIfNeeded()
        return await advance(to: .firstProtocol, context: [
            "selected_categories": AnyCodable(selectedCategories.map(\.rawValue))
        ])
    }

    /// Step 2 CTA: persist the chosen protocol NAME only — the backend rejects
    /// creating a protocol with empty `actions` (422 "without actions"), so the
    /// actual Protocol+first-action create is deferred to step 3 in ONE request.
    @discardableResult
    func continueFromProtocol() async -> Bool {
        guard canContinue(.firstProtocol) else { return false }
        return await advance(to: .firstAction, context: [
            "selected_categories": AnyCodable(selectedCategories.map(\.rawValue)),
            "first_protocol_name": AnyCodable(protocolName.trimmingCharacters(in: .whitespacesAndNewlines))
        ])
    }

    /// Library actions for all selected categories (`GET /actions?category=X&library_only=true`).
    func loadAvailableActions() async {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return
        }
        guard !selectedCategories.isEmpty else {
            availableActions = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var seenIds = Set<String>()
            var items: [ActionItem] = []
            for category in selectedCategories {
                let actions = try await api.fetchActions(
                    token: token,
                    category: category,
                    modality: nil,
                    query: nil,
                    libraryOnly: true
                )
                for action in actions where seenIds.insert(action.id).inserted {
                    items.append(action.toActionItem())
                }
            }
            availableActions = items
            if let chosenAction, !items.contains(where: { $0.id == chosenAction.id }) {
                self.chosenAction = nil
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load actions."
            availableActions = []
        }
    }

    /// Step 3 CTA: create the protocol WITH its first action in a single
    /// `POST /protocols` (backend rejects an empty-actions protocol). Holds the
    /// resulting protocol + action IDs, then PATCH advances to `notifications`.
    @discardableResult
    func createProtocolWithFirstAction() async -> Bool {
        guard canContinue(.firstAction) else { return false }
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return false
        }
        guard let userId = authStore.userId else {
            errorMessage = "User not authenticated."
            return false
        }
        guard createdProtocolId == nil else {
            // A protocol already exists (resume/replay) — just advance.
            return await advance(to: .notifications, context: [
                "actions_added": AnyCodable(1),
                "first_reminder_time": AnyCodable(timeSlot.timeLabel)
            ])
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        guard let action = chosenAction else {
            errorMessage = "Choose an action first."
            return false
        }

        let schedule = ActionSchedule(
            frequency: .daily,
            days: ScheduleDay.allCases,
            hour: timeSlot.hour,
            minute: timeSlot.minute
        )
        let protocolAction = ProtocolActionCreate(
            actionId: action.id,
            userParameters: action.userParameters,
            rrule: schedule.toRRule(),
            position: 0,
            notificationTime: reminderEnabled ? timeSlot.timeLabel : nil,
            notificationTimezone: reminderEnabled ? TimeZone.current.identifier : nil
        )
        let payload = ProtocolCreateRequest(
            userId: userId,
            name: protocolName.trimmingCharacters(in: .whitespacesAndNewlines),
            actions: [protocolAction],
            isActive: true,
            startedAt: nil,
            endedAt: nil,
            category: selectedCategories.first,
            metricKeys: nil
        )

        do {
            // POST /protocols expects multipart `protocol_data` — use the
            // multipart variant with no image (matches ProtocolBuilder), so the
            // action ships in the same request body as the protocol.
            let created = try await api.createProtocolWithImage(token: token, payload: payload, imageData: nil)
            createdProtocolId = created.id
            createdProtocolActionId = created.actions.first(where: { $0.actionId == action.id })?.id
            return await advance(to: .notifications, context: [
                "first_protocol_id": AnyCodable(created.id),
                "first_protocol_name": AnyCodable(created.name),
                "actions_added": AnyCodable(1),
                "first_reminder_time": AnyCodable(timeSlot.timeLabel)
            ])
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to create protocol."
            return false
        }
    }

    // MARK: - Notifications Step

    func allowNotifications() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        notificationPermissionGranted = granted
        if granted {
            await createReminderSchedule()
        }
        await advance(to: .done, context: ["notifications_enabled": AnyCodable(granted)])
    }

    /// "Skip for now" — records the outcome (not granted) and advances.
    func skipNotifications() async {
        notificationPermissionGranted = false
        await advance(to: .done, context: [
            "notifications_enabled": AnyCodable(false),
            "notifications_skipped": AnyCodable(true)
        ])
    }

    /// Creates the server-side reminder schedule for the first action
    /// (mirrors `ProtocolBuilderViewModel.upsertNotificationSchedules`).
    /// Best-effort: a failure here must not block the wizard.
    private func createReminderSchedule() async {
        guard reminderEnabled,
              let token = authStore.accessToken,
              let protocolActionId = createdProtocolActionId,
              let action = chosenAction else { return }

        let payload = NotificationScheduleCreate(
            protocolActionId: protocolActionId,
            preferredTime: timeSlot.timeLabel,
            timezone: TimeZone.current.identifier,
            isEnabled: true
        )

        do {
            let schedule = try await api.upsertNotificationSchedule(token: token, actionId: protocolActionId, payload: payload)
            NotificationManager.shared.scheduleLocalNotification(schedule: schedule, actionName: action.name)
        } catch {
            // Non-critical: reminder creation failure shouldn't block onboarding
        }
    }

    // MARK: - Skip / Complete / Reset

    /// Global Skip (visible on steps 1–5): ends the wizard, state `skipped`.
    func skipWizard() async {
        guard let token = authStore.accessToken else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let updated = try await api.patchOnboarding(
                token: token,
                payload: OnboardingUpdateRequest(status: .skipped)
            )
            state = updated
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to skip onboarding."
        }
    }

    /// Step 5 CTA: reaching `done` makes the server set `status = completed`.
    func complete() async {
        _ = await advance(to: .done)
    }

    /// `POST /onboarding/reset` — back to `welcome` / `not_started` (replay path).
    func reset() async {
        guard let token = authStore.accessToken else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fresh = try await api.resetOnboarding(token: token)
            selectedCategories = []
            protocolName = ""
            createdProtocolId = nil
            createdProtocolActionId = nil
            availableActions = []
            chosenAction = nil
            reminderEnabled = true
            timeSlot = ScheduleSlot(hour: 8, minute: 0, isReminderOn: true, reminderOffsetMinutes: 0)
            notificationPermissionGranted = nil
            applyState(fresh)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to reset onboarding."
        }
    }

    // MARK: - PATCH Helper

    @discardableResult
    private func advance(to step: OnboardingStep, context: [String: AnyCodable] = [:]) async -> Bool {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return false
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let updated = try await api.patchOnboarding(
                token: token,
                payload: OnboardingUpdateRequest(step: step, context: context.isEmpty ? nil : context)
            )
            applyState(updated)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to save progress."
            return false
        }
    }
}
