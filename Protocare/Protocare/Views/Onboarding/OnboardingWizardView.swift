//
//  OnboardingWizardView.swift
//  Protocare
//
//  6-step onboarding wizard — variant B swipe carousel (prototypes/onboarding-ui.html):
//  horizontal swipe between steps, large circular SF Symbol illustrations,
//  custom pill page indicator, large bell on the notifications step.
//  Swipe forward past an incomplete step bounces back with an inline hint;
//  forward progress happens via the step CTAs, which persist a PATCH first.
//

import SwiftUI

struct OnboardingWizardView: View {
    @ObservedObject var vm: OnboardingViewModel

    @State private var isClamping = false
    @State private var showGateHint = false
    @State private var hintTask: Task<Void, Never>?

    private let primary = Color.appPrimary

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $vm.currentStepIndex) {
                    welcomeStep.tag(OnboardingStep.welcome.index)
                    categoryStep.tag(OnboardingStep.category.index)
                    firstProtocolStep.tag(OnboardingStep.firstProtocol.index)
                    firstActionStep.tag(OnboardingStep.firstAction.index)
                    notificationsStep.tag(OnboardingStep.notifications.index)
                    doneStep.tag(OnboardingStep.done.index)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pillIndicator
                bottomControls
            }
        }
        .interactiveDismissDisabled()
        .onChange(of: vm.currentStepIndex) { oldValue, newValue in
            guard !isClamping else { return }
            guard !vm.canMove(to: newValue) else { return }
            // Forward swipe beyond the server-known progress: bounce back and
            // surface the step hint (e.g. "Select at least one.").
            if newValue > oldValue, vm.gateHint != nil {
                presentGateHint()
            }
            isClamping = true
            vm.currentStepIndex = oldValue
            isClamping = false
        }
        .onChange(of: vm.currentStepIndex) { _, newValue in
            if OnboardingStep(index: newValue) == .firstAction, vm.availableActions.isEmpty {
                Task { await vm.loadAvailableActions() }
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Spacer()
            if vm.currentStepIndex > 0, vm.currentStep != .done {
                Button {
                    Task { await vm.skipWizard() }
                } label: {
                    Text("Skip")
                        .font(.appBody.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .disabled(vm.isSaving)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, AppSpacing.pagePadding)
    }

    private var pillIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(vm.steps.indices), id: \.self) { index in
                if index == vm.currentStepIndex {
                    RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                        .fill(primary)
                        .frame(width: 24, height: 8)
                } else {
                    Circle()
                        .fill(Color.appBorder)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 16)
    }

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(.appCaption.weight(.medium))
                    .foregroundStyle(Color.appError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            switch vm.currentStep {
            case .notifications:
                primaryButton(title: "Allow") {
                    Task { await vm.allowNotifications() }
                }
                Button {
                    Task { await vm.skipNotifications() }
                } label: {
                    Text("Skip for now")
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .disabled(vm.isSaving)
            default:
                primaryButton(title: primaryTitle) {
                    Task { await runPrimaryAction() }
                }
            }
        }
        .padding(.horizontal, AppSpacing.pagePadding)
        .padding(.bottom, 28)
    }

    private var primaryTitle: String {
        switch vm.currentStep {
        case .welcome: return "Get Started"
        case .category: return "Continue"
        case .firstProtocol: return "Create protocol"
        case .firstAction: return "Continue"
        case .done: return "Go to Dashboard"
        case .notifications: return "Continue"
        }
    }

    @MainActor
    private func runPrimaryAction() async {
        switch vm.currentStep {
        case .welcome:
            await vm.continueFromWelcome()
        case .category:
            await vm.continueFromCategory()
        case .firstProtocol:
            await vm.continueFromProtocol()
        case .firstAction:
            await vm.createProtocolWithFirstAction()
        case .done:
            await vm.complete()
        case .notifications:
            break
        }
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.appBody.weight(.heavy))
                .foregroundStyle(Color.appOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(vm.canContinue(vm.currentStep) ? primary : Color.appBorder)
                .clipShape(Capsule())
                .shadow(color: primary.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!vm.canContinue(vm.currentStep) || vm.isSaving)
    }

    private func presentGateHint() {
        hintTask?.cancel()
        showGateHint = true
        hintTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            showGateHint = false
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                ZStack {
                    illustrationCircle(systemName: "checklist", size: 180)
                    smallSatellite(systemName: "target", size: 56)
                        .offset(x: 96, y: -64)
                    smallSatellite(systemName: "bell.fill", size: 56, tint: primary)
                        .offset(x: -92, y: 68)
                }
                .padding(.bottom, 8)

                VStack(spacing: 8) {
                    Text("Protocare")
                        .font(.appScreenTitle)
                        .foregroundStyle(Color.appText)
                    Text("Track your routines, see the results.")
                        .font(.appBody.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    welcomeBullet("Pick what you work on — skincare, fitness, sleep")
                    welcomeBullet("Schedule actions & gentle reminders")
                    welcomeBullet("See the daily check-in work for you")
                }
                .padding(.horizontal, 8)

                Text("You'll be set up in under 3 minutes.")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 24)
        }
    }

    private func welcomeBullet(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.appBody)
                .foregroundStyle(primary)
            Text(text)
                .font(.appBody.weight(.medium))
                .foregroundStyle(Color.appText)
        }
    }

    // MARK: - Step 1: Category

    private var categoryStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepTitle("What are you working on?")
                Text("Select 1 or more. This tunes your suggestions.")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 12)], spacing: 12) {
                    ForEach(ActionCategory.allCases) { category in
                        categoryPill(category)
                    }
                }
                .padding(.horizontal, 24)

                if showGateHint, let hint = vm.gateHint {
                    Text(hint)
                        .font(.appCaptionBold)
                        .foregroundStyle(Color.appError)
                        .transition(.opacity)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
        }
    }

    private func categoryPill(_ category: ActionCategory) -> some View {
        let selected = vm.selectedCategories.contains(category)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if selected {
                    vm.selectedCategories.removeAll { $0 == category }
                } else {
                    vm.selectedCategories.append(category)
                }
            }
            showGateHint = false
        } label: {
            HStack(spacing: 4) {
                Image(systemName: category.tagIcon)
                    .font(.appCaptionBold)
                Text(category.displayName)
                    .font(.appCaption.weight(selected ? .bold : .semibold))
            }
            .foregroundStyle(selected ? Color.appOnAccent : Color.appText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(selected ? primary : Color.appSurface)
                    .overlay(
                        Capsule()
                            .strokeBorder(selected ? primary : Color.appBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: First Protocol

    private var firstProtocolStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                illustrationCircle(systemName: "list.clipboard.fill", size: 140)
                    .padding(.top, 24)

                stepTitle("Name your first protocol")

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.appBody)
                            .foregroundStyle(Color.appTextSecondary)
                        TextField("e.g. Skincare routine", text: $vm.protocolName)
                            .font(.appBody)
                            .foregroundStyle(Color.appText)
                            .textInputAutocapitalization(.sentences)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .strokeBorder(Color.appBorder, lineWidth: 1)
                    )

                    Text("This becomes a tab in your app. You can add actions right after.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Step 3: First Action

    private var firstActionStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                stepTitle("Add your first action")
                    .padding(.top, 12)

                if vm.isLoading {
                    ProgressView()
                        .padding(.vertical, 24)
                } else if vm.availableActions.isEmpty {
                    Text("No ready-made actions yet. Create your own.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(vm.selectedCategories, id: \.self) { category in
                        let actions = vm.availableActions.filter { $0.category == category }
                        if !actions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.displayName.uppercased())
                                    .font(.appCaptionBold)
                                    .foregroundStyle(Color.appTextSecondary)
                                    .tracking(1.2)
                                    .padding(.leading, 4)
                                ForEach(actions) { action in
                                    actionCard(action)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                VStack(spacing: 8) {
                    TimeDrumPicker(
                        hour: Binding(
                            get: { vm.timeSlot.hour },
                            set: { newValue in
                                vm.timeSlot.hour = newValue
                                vm.timeSlot.isReminderOn = vm.reminderEnabled
                            }
                        ),
                        minute: Binding(
                            get: { vm.timeSlot.minute },
                            set: { newValue in
                                vm.timeSlot.minute = newValue
                                vm.timeSlot.isReminderOn = vm.reminderEnabled
                            }
                        )
                    )
                    .frame(height: 150)

                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.appBody)
                            .foregroundStyle(vm.reminderEnabled ? primary : Color.appTextSecondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remind me")
                                .font(.appBody.weight(.medium))
                                .foregroundStyle(Color.appText)
                            Text("Daily local push at the action's time.")
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: $vm.reminderEnabled)
                            .tint(primary)
                            .labelsHidden()
                            .onChange(of: vm.reminderEnabled) { _, newValue in
                                vm.timeSlot.isReminderOn = newValue
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .strokeBorder(Color.appBorder, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 8)
        }
    }

    private func actionCard(_ action: ActionItem) -> some View {
        let selected = vm.chosenAction?.id == action.id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                vm.chosenAction = action
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: action.category.tagIcon)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(Color.appOnAccent)
                    .frame(width: 36, height: 36)
                    .background(action.category.tagColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.name)
                        .font(.appCardTitle)
                        .foregroundStyle(Color.appText)
                    Text(actionSubtitle(action))
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.appSectionTitle)
                        .foregroundStyle(primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(selected ? Color.appPrimaryLight : Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(selected ? primary : Color.appBorder, lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionSubtitle(_ action: ActionItem) -> String {
        var parts: [String] = []
        if let modality = action.modality {
            parts.append(modality.displayName.uppercased())
        }
        if let volume = action.volume {
            parts.append(volume.displayString)
        } else if let duration = action.durationLabel {
            parts.append(duration)
        }
        return parts.isEmpty ? action.category.displayName : parts.joined(separator: " · ")
    }

    // MARK: - Step 4: Notifications

    private var notificationsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                illustrationCircle(systemName: "bell.badge.fill", size: 200)
                    .padding(.bottom, 8)

                stepTitle("Stay on track")
                Text("One gentle reminder per action, just when you're meant to do it.")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer(minLength: 8)
            }
        }
    }

    // MARK: - Step 5: Done

    private var doneStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                illustrationCircle(
                    systemName: "checkmark",
                    size: 160,
                    colors: [Color.appSuccess.opacity(0.6), Color.appSuccess]
                )
                .padding(.top, 24)

                stepTitle("You're all set!")
                Text("Your first check-in appears on the Daily tab.")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 0) {
                    summaryRow(label: "Focus", value: vm.summaryFocus)
                    summaryDivider
                    summaryRow(label: "Protocol", value: vm.summaryProtocolName)
                    summaryDivider
                    summaryRow(label: "Actions", value: vm.summaryActions)
                    summaryDivider
                    summaryRow(label: "Reminder", value: vm.summaryReminder)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(Color.appBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.appCaptionBold)
                .foregroundStyle(Color.appText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private var summaryDivider: some View {
        Divider()
            .foregroundStyle(Color.appBorder)
            .padding(.leading, 8)
    }

    // MARK: - Shared

    private func stepTitle(_ text: String) -> some View {
        Text(text)
            .font(.appScreenTitle)
            .foregroundStyle(Color.appText)
            .multilineTextAlignment(.center)
    }

    private func illustrationCircle(
        systemName: String,
        size: CGFloat,
        colors: [Color] = [Color.appPrimaryLight, Color.appPrimary]
    ) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.appEmptyStateIconLarge.weight(.semibold))
                    .foregroundStyle(Color.appOnAccent)
            }
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 16, y: 8)
    }

    private func smallSatellite(systemName: String, size: CGFloat, tint: Color = Color.appTextSecondary) -> some View {
        Circle()
            .fill(Color.appSurface)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.appSectionTitle)
                    .foregroundStyle(tint)
            }
            .shadow(color: Color.appText.opacity(0.08), radius: 6, y: 3)
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://localhost:8000/v1")!)
    OnboardingWizardView(
        vm: OnboardingViewModel(api: api, authStore: AuthStore())
    )
}
