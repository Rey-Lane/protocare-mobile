import SwiftUI
import Combine

/// Unified action creator (Step 25d of the unified action model migration).
///
/// Creates/edits a user-created `Action` via `POST /actions` /
/// `PATCH /actions/{id}` — the former `POST /user-actions` flow is gone.
/// Category (primary axis) + modality (secondary axis) pickers replace the
/// old single category picker, and default parameters are derived from a
/// simple amount/unit or duration input instead of the legacy
/// `ActionField`/`ActionParameters` schema system.
struct ActionCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActionCreatorViewModel
    private let onCreated: (Action) -> Void

    init(
        api: AuthAPI,
        authStore: AuthStore,
        editingAction: Action? = nil,
        onCreated: @escaping (Action) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ActionCreatorViewModel(api: api, authStore: authStore, editingAction: editingAction))
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Action name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)

                    TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
                }

                Section {
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(ActionCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.tagIcon).tag(cat)
                        }
                    }

                    Picker("Modality", selection: $viewModel.modality) {
                        Text("None").tag(ActionModality?.none)
                        ForEach(ActionModality.allCases, id: \.self) { mod in
                            Text(mod.displayName).tag(ActionModality?.some(mod))
                        }
                    }
                } header: {
                    Text("Classification")
                } footer: {
                    Text("Category is the primary filter; modality describes how the action is performed.")
                }

                Section {
                    Picker("Default tracking", selection: $viewModel.parameterMode) {
                        ForEach(ActionCreatorViewModel.ParameterMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    switch viewModel.parameterMode {
                    case .none:
                        Text("Just a yes/no check-in each day.")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextSecondary)
                    case .amount:
                        HStack {
                            // Bug #3 fix: leading alignment — the old .trailing
                            // pushed the placeholder to the right edge of the
                            // full-width field.
                            TextField("Amount", value: $viewModel.amount, format: .number)
                                .keyboardType(.decimalPad)
                            Picker("Unit", selection: $viewModel.unit) {
                                ForEach(SubstanceUnit.amountUnits, id: \.self) { unit in
                                    Text(unit.displayName).tag(unit)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 110)
                        }
                    case .duration:
                        HStack {
                            // Bug #3 fix: leading alignment (same as Amount).
                            TextField("Minutes", value: $viewModel.durationMinutes, format: .number)
                                .keyboardType(.numberPad)
                            Text("min")
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                } header: {
                    Text("Default Parameters")
                } footer: {
                    Text("Pre-fills the check-in form when this action is added to a protocol.")
                }

                Section {
                    ColorPicker("Color", selection: $viewModel.accentColor)

                    Picker("Icon", selection: $viewModel.iconKey) {
                        ForEach(ActionIcon.allCases, id: \.self) { icon in
                            Label(icon.displayName, systemImage: icon.systemName).tag(icon.rawValue as String?)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.isEditing ? "Edit Action" : "New Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isEditing ? "Save" : "Create") {
                        Task {
                            if let action = await viewModel.save() {
                                onCreated(action)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(viewModel.canSave ? Color.appPrimary : Color.appTextSecondary)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

enum ActionIcon: String, CaseIterable {
    case pill = "pill.fill"
    case drop = "drop.fill"
    case figureRun = "figure.run"
    case heart = "heart.fill"
    case moon = "moon.fill"
    case brain = "brain.head.profile.fill"
    case sparkles = "sparkles"
    case leaf = "leaf.fill"
    case flame = "flame.fill"
    case dumbbell = "dumbbell.fill"
    case forkKnife = "fork.knife"
    case clock = "clock.fill"
    case star = "star.fill"
    case bolt = "bolt.fill"
    case custom = "square.and.pencil"

    var displayName: String {
        switch self {
        case .pill: return "Pill"
        case .drop: return "Drop"
        case .figureRun: return "Running"
        case .heart: return "Heart"
        case .moon: return "Moon"
        case .brain: return "Brain"
        case .sparkles: return "Sparkles"
        case .leaf: return "Leaf"
        case .flame: return "Flame"
        case .dumbbell: return "Dumbbell"
        case .forkKnife: return "Nutrition"
        case .clock: return "Clock"
        case .star: return "Star"
        case .bolt: return "Bolt"
        case .custom: return "Custom"
        }
    }

    var systemName: String { rawValue }
}

@MainActor
final class ActionCreatorViewModel: ObservableObject {
    /// Which default-parameter shape the new action carries.
    enum ParameterMode: String, CaseIterable, Identifiable {
        case none
        case amount
        case duration

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "None (yes/no)"
            case .amount: return "Amount"
            case .duration: return "Duration"
            }
        }
    }

    @Published var name: String = ""
    @Published var description: String = ""
    @Published var category: ActionCategory = .custom
    @Published var modality: ActionModality?
    @Published var parameterMode: ParameterMode = .none
    @Published var amount: Double?
    @Published var unit: SubstanceUnit = .ml
    @Published var durationMinutes: Double?
    @Published var iconKey: String? = "sparkles"
    @Published var accentColor: Color = .green
    @Published var errorMessage: String? = nil
    @Published var isSaving: Bool = false

    let isEditing: Bool
    private let editingActionId: String?
    private let api: AuthAPI
    let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore, editingAction: Action? = nil) {
        self.api = api
        self.authStore = authStore
        self.editingActionId = editingAction?.id
        self.isEditing = editingAction != nil

        if let action = editingAction {
            self.name = action.name
            self.description = action.description ?? ""
            self.category = action.category
            self.modality = action.modality
            self.iconKey = action.iconKey
            if let hex = action.color {
                self.accentColor = Color(hex: hex)
            }
            // Derive the parameter mode from the existing default_parameters,
            // mirroring CheckInFormResolver's key priority.
            let formKind = CheckInFormResolver.formKind(for: action.defaultParameters)
            switch formKind {
            case .substance:
                self.parameterMode = .amount
                if let quantity = CheckInFormResolver.defaultQuantity(in: action.defaultParameters) {
                    self.amount = quantity.amount
                    self.unit = quantity.unit
                }
            case .timedActivity:
                self.parameterMode = .duration
                if let seconds = CheckInFormResolver.defaultDurationSeconds(in: action.defaultParameters) {
                    self.durationMinutes = Double(seconds) / 60.0
                }
            case .binary:
                self.parameterMode = .none
            }
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && name.count >= 2
        && name.count <= 100
        && !isSaving
    }

    /// Builds `default_parameters` from the picker inputs, using the backend's
    /// canonical keys (`volume_amount`/`volume_unit` or `duration_seconds`).
    private var defaultParameters: [String: AnyCodable]? {
        switch parameterMode {
        case .none:
            return nil
        case .amount:
            guard let amount, amount > 0 else { return nil }
            return [
                "volume_amount": AnyCodable(amount),
                "volume_unit": AnyCodable(unit.rawValue)
            ]
        case .duration:
            guard let minutes = durationMinutes, minutes > 0 else { return nil }
            return [
                "duration_seconds": AnyCodable(Int(minutes * 60))
            ]
        }
    }

    func save() async -> Action? {
        guard canSave else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return nil
        }

        let colorHex = accentColor.toHex()

        if let editingId = editingActionId {
            let payload = ActionUpdate(
                name: name,
                description: description.isEmpty ? nil : description,
                category: category,
                modality: modality,
                defaultParameters: defaultParameters,
                iconKey: iconKey,
                color: colorHex
            )
            do {
                return try await api.updateAction(token: token, actionId: editingId, payload: payload)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to update action."
                return nil
            }
        } else {
            let payload = ActionCreate(
                name: name,
                description: description.isEmpty ? nil : description,
                category: category,
                modality: modality,
                defaultParameters: defaultParameters,
                iconKey: iconKey,
                color: colorHex
            )
            do {
                return try await api.createAction(token: token, payload: payload)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to create action."
                return nil
            }
        }
    }
}

extension SubstanceUnit {
    /// Units that make sense for a user-configured default amount.
    static let amountUnits: [SubstanceUnit] = [.ml, .mg, .g, .drop, .capsule, .tablet, .spray]
}
