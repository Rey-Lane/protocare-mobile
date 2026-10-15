//
//  OnboardingViewModelTests.swift
//  ProtocareTests
//
//  Onboarding wizard gating, PATCH payloads, step transitions, skip/reset paths.
//

import XCTest
@testable import Protocare

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    var sut: OnboardingViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        mockAuthStore.mockAccessToken = "test_access_token"
        mockAuthStore.mockUserId = "test-user-id"
        sut = OnboardingViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - Gating

    func testLoadState_SyntheticNotStarted_ShowsWizard() async {
        // Zero-UUID id is the server's synthetic default for "no row yet".
        mockAPI.fetchOnboardingResult = .success(OnboardingState())

        await sut.loadState()

        XCTAssertTrue(sut.shouldShow)
        XCTAssertEqual(sut.state?.isSyntheticDefault, true)
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func testLoadState_InProgress_ShowsWizard() async {
        mockAPI.fetchOnboardingResult = .success(
            OnboardingState(step: .firstAction, status: .inProgress)
        )

        await sut.loadState()

        XCTAssertTrue(sut.shouldShow)
        XCTAssertEqual(sut.currentStep, .firstAction)
    }

    func testLoadState_Completed_DoesNotShow() async {
        mockAPI.fetchOnboardingResult = .success(
            OnboardingState(step: .done, status: .completed, completedAt: Date())
        )

        await sut.loadState()

        XCTAssertFalse(sut.shouldShow)
    }

    func testLoadState_Skipped_DoesNotShow() async {
        mockAPI.fetchOnboardingResult = .success(
            OnboardingState(step: .firstProtocol, status: .skipped, completedAt: Date())
        )

        await sut.loadState()

        XCTAssertFalse(sut.shouldShow)
    }

    func testLoadState_ResumeHydratesContext() async {
        mockAPI.fetchOnboardingResult = .success(
            OnboardingState(
                step: .firstProtocol,
                status: .inProgress,
                context: OnboardingContextData(
                    selectedCategories: ["skincare", "exercise"],
                    firstProtocolName: "Skincare routine"
                )
            )
        )

        await sut.loadState()

        XCTAssertEqual(sut.selectedCategories, [.skincare, .exercise])
        XCTAssertEqual(sut.protocolName, "Skincare routine")
    }

    // MARK: - Swipe Gating

    func testCanMove_AllowsRevisitButBlocksForwardJump() async {
        mockAPI.fetchOnboardingResult = .success(
            OnboardingState(step: .category, status: .inProgress)
        )
        await sut.loadState()

        XCTAssertTrue(sut.canMove(to: 0))
        XCTAssertTrue(sut.canMove(to: 1))
        XCTAssertFalse(sut.canMove(to: 2))
        XCTAssertFalse(sut.canMove(to: 5))
    }

    // MARK: - Category Step

    func testCanContinue_CategoryRequiresAtLeastOneSelection() {
        XCTAssertFalse(sut.canContinue(.category))

        sut.selectedCategories = [.skincare]
        XCTAssertTrue(sut.canContinue(.category))
    }

    func testGateHint_CategoryEmptySelection() {
        sut.currentStepIndex = OnboardingStep.category.index
        XCTAssertEqual(sut.gateHint, "Select at least one.")

        sut.selectedCategories = [.skincare]
        XCTAssertNil(sut.gateHint)
    }

    func testContinueFromWelcome_PatchesCategoryStep() async {
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .category, status: .inProgress)
        )

        let result = await sut.continueFromWelcome()

        XCTAssertTrue(result)
        XCTAssertEqual(mockAPI.patchOnboardingCallCount, 1)
        XCTAssertEqual(mockAPI.lastPatchOnboardingPayload?.step, .category)
        XCTAssertNil(mockAPI.lastPatchOnboardingPayload?.status)
        XCTAssertEqual(sut.currentStep, .category)
    }

    func testContinueFromCategory_PatchesSelectedCategoriesAndPrefillsName() async {
        sut.selectedCategories = [.skincare, .exercise]
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .firstProtocol, status: .inProgress)
        )

        let result = await sut.continueFromCategory()

        XCTAssertTrue(result)
        let payload = mockAPI.lastPatchOnboardingPayload
        XCTAssertEqual(payload?.step, .firstProtocol)
        XCTAssertEqual(
            payload?.context?["selected_categories"]?.value as? [String],
            ["skincare", "exercise"]
        )
        XCTAssertEqual(sut.protocolName, "Skincare routine")
        XCTAssertEqual(sut.currentStep, .firstProtocol)
    }

    func testContinueFromCategory_WithoutSelection_DoesNotPatch() async {
        let result = await sut.continueFromCategory()

        XCTAssertFalse(result)
        XCTAssertEqual(mockAPI.patchOnboardingCallCount, 0)
    }

    // MARK: - First Protocol Step

    func testContinueFromProtocol_PersistsNameAndAdvancesToFirstAction() async {
        sut.selectedCategories = [.skincare]
        sut.protocolName = "Skincare routine"
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .firstAction, status: .inProgress)
        )

        let result = await sut.continueFromProtocol()

        XCTAssertTrue(result)
        XCTAssertNil(mockAPI.lastCreateProtocolPayload, "Step 2 must NOT create a protocol (backend rejects empty actions)")
        let payload = mockAPI.lastPatchOnboardingPayload
        XCTAssertEqual(payload?.step, .firstAction)
        XCTAssertEqual(payload?.context?["first_protocol_name"]?.value as? String, "Skincare routine")
        XCTAssertEqual(sut.currentStep, .firstAction)
    }

    func testContinueFromProtocol_WithoutName_DoesNotPatch() async {
        sut.protocolName = "   "

        let result = await sut.continueFromProtocol()

        XCTAssertFalse(result)
        XCTAssertEqual(mockAPI.patchOnboardingCallCount, 0)
    }

    // MARK: - First Action Step

    func testCreateProtocolWithFirstAction_Success_CreatesProtocolWithAction() async {
        // Drive the wizard to the first_action step (no protocol created yet).
        sut.selectedCategories = [.skincare]
        sut.protocolName = "Skincare routine"
        sut.chosenAction = ActionItem(id: "action-1", name: "Retinol serum", category: .skincare)
        sut.timeSlot = ScheduleSlot(hour: 21, minute: 30, isReminderOn: true, reminderOffsetMinutes: 0)
        mockAPI.createProtocolWithImageResult = .success(
            ProtocolItem(
                id: "protocol-1",
                userId: "test-user-id",
                name: "Skincare routine",
                actions: [ProtocolAction(id: "pa-1", actionId: "action-1", rrule: "RRULE:FREQ=DAILY;BYHOUR=21;BYMINUTE=30", position: 0)],
                isActive: true
            )
        )
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .notifications, status: .inProgress)
        )

        let result = await sut.createProtocolWithFirstAction()

        XCTAssertTrue(result)
        XCTAssertEqual(mockAPI.createProtocolWithImageCallCount, 1, "Protocol + first action created in ONE request")
        let createPayload = mockAPI.lastCreateProtocolPayload
        XCTAssertEqual(createPayload?.name, "Skincare routine")
        XCTAssertEqual(createPayload?.actions.count, 1)
        XCTAssertEqual(createPayload?.actions.first?.actionId, "action-1")
        XCTAssertTrue(createPayload?.actions.first?.rrule.contains("FREQ=DAILY") == true)
        XCTAssertTrue(createPayload?.actions.first?.rrule.contains("BYHOUR=21") == true)
        XCTAssertTrue(createPayload?.actions.first?.rrule.contains("BYMINUTE=30") == true)
        XCTAssertEqual(createPayload?.actions.first?.notificationTime, "21:30")
        XCTAssertNotNil(createPayload?.actions.first?.notificationTimezone)
        XCTAssertEqual(sut.createdProtocolId, "protocol-1")
        let patchPayload = mockAPI.lastPatchOnboardingPayload
        XCTAssertEqual(patchPayload?.step, .notifications)
        XCTAssertEqual(patchPayload?.context?["first_protocol_id"]?.value as? String, "protocol-1")
        XCTAssertEqual(patchPayload?.context?["first_protocol_name"]?.value as? String, "Skincare routine")
        XCTAssertEqual(patchPayload?.context?["actions_added"]?.value as? Int, 1)
        XCTAssertEqual(patchPayload?.context?["first_reminder_time"]?.value as? String, "21:30")
        XCTAssertEqual(sut.currentStep, .notifications)
    }

    func testCreateProtocolWithFirstAction_WithoutChosenAction_DoesNotPatch() async {
        let result = await sut.createProtocolWithFirstAction()

        XCTAssertFalse(result)
        XCTAssertEqual(mockAPI.patchOnboardingCallCount, 0)
    }

    func testLoadAvailableActions_FetchesLibraryOnlyPerCategory() async {
        sut.selectedCategories = [.skincare, .exercise]
        mockAPI.fetchActionsResult = .success([
            Action(id: "a1", name: "Retinol serum", category: .skincare),
            Action(id: "a2", name: "Push-ups", category: .exercise)
        ])

        await sut.loadAvailableActions()

        XCTAssertEqual(sut.availableActions.count, 2)
        XCTAssertEqual(mockAPI.lastFetchActionsLibraryOnly, true)
        XCTAssertEqual(mockAPI.lastFetchActionsFilters?.category, .exercise)
    }

    // MARK: - Notifications / Skip / Complete / Reset

    func testSkipNotifications_PatchesNotEnabledContext() async {
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .done, status: .inProgress)
        )

        await sut.skipNotifications()

        let payload = mockAPI.lastPatchOnboardingPayload
        XCTAssertEqual(payload?.step, .done)
        XCTAssertEqual(payload?.context?["notifications_enabled"]?.value as? Bool, false)
        XCTAssertEqual(payload?.context?["notifications_skipped"]?.value as? Bool, true)
        XCTAssertEqual(sut.currentStep, .done)
    }

    func testSkipWizard_PatchesSkippedStatusAndDismisses() async {
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .firstAction, status: .skipped, completedAt: Date())
        )

        await sut.skipWizard()

        let payload = mockAPI.lastPatchOnboardingPayload
        XCTAssertEqual(payload?.status, .skipped)
        XCTAssertNil(payload?.step)
        XCTAssertFalse(sut.shouldShow)
    }

    func testComplete_PatchesDoneStep() async {
        mockAPI.patchOnboardingResult = .success(
            OnboardingState(step: .done, status: .completed, completedAt: Date())
        )

        await sut.complete()

        XCTAssertEqual(mockAPI.lastPatchOnboardingPayload?.step, .done)
        XCTAssertFalse(sut.shouldShow)
    }

    func testReset_ClearsLocalDraftsAndReturnsToWelcome() async {
        sut.selectedCategories = [.skincare]
        sut.protocolName = "Skincare routine"
        mockAPI.resetOnboardingResult = .success(OnboardingState())

        await sut.reset()

        XCTAssertEqual(mockAPI.resetOnboardingCallCount, 1)
        XCTAssertTrue(sut.selectedCategories.isEmpty)
        XCTAssertTrue(sut.protocolName.isEmpty)
        XCTAssertEqual(sut.currentStep, .welcome)
        XCTAssertTrue(sut.shouldShow)
    }
}
