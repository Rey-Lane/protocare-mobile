import SwiftUI
import Combine

struct ActionCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActionCreatorViewModel
    @State private var newFieldKey = ""
    @State private var newFieldLabel = ""
    @State private var newFieldType: ActionFieldType = .text
    @State private var showingNewFieldSheet = false
    private let onCreated: (UserAction) -> Void

    init(api: AuthAPI, authStore: AuthStore, editingAction: UserAction? = nil, onCreated: @escaping (UserAction) -> Void) {
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
                        ForEach(ActionCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }

                    ColorPicker("Color", selection: $viewModel.accentColor)

                    Picker("Icon", selection: $viewModel.iconKey) {
                        ForEach(ActionIcon.allCases, id: \.self) { icon in
                            Label(icon.displayName, systemImage: icon.systemName).tag(icon.rawValue as String?)
                        }
                    }
                } header: {
                    Text("Appearance")
                }

                Section {
                    if viewModel.fields.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("No parameter fields yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Add fields to let users customize this action when adding it to a protocol.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        ForEach(viewModel.fields) { field in
                            FieldRow(field: field, onRemove: {
                                withAnimation { viewModel.removeField(field) }
                            })
                        }
                    }

                    Button {
                        showingNewFieldSheet = true
                    } label: {
                        Label("Add Field", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Parameters")
                        Spacer()
                        if !viewModel.fields.isEmpty {
                            Text("\(viewModel.fields.count)/20")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.canSave ? Color.appPrimary : .secondary)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showingNewFieldSheet) {
                AddFieldSheet(
                    key: $newFieldKey,
                    label: $newFieldLabel,
                    type: $newFieldType,
                    onAdd: {
                        let field = ActionField(
                            key: newFieldKey,
                            label: newFieldLabel,
                            type: newFieldType
                        )
                        viewModel.addField(field)
                        newFieldKey = ""
                        newFieldLabel = ""
                        newFieldType = .text
                        showingNewFieldSheet = false
                    }
                )
            }
        }
    }
}

private struct FieldRow: View {
    let field: ActionField
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(field.label)
                    .font(.system(size: 15, weight: .medium))
                HStack(spacing: 6) {
                    Text(field.type.rawValue.capitalized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if field.isRequired {
                        Text("Required")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appWarning)
                    }
                    if let unit = field.unit {
                        Text("· \(unit)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

private struct AddFieldSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var key: String
    @Binding var label: String
    @Binding var type: ActionFieldType
    let onAdd: () -> Void

    private var canAdd: Bool {
        !key.trimmingCharacters(in: .whitespaces).isEmpty
        && !label.trimmingCharacters(in: .whitespaces).isEmpty
        && key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Field key (e.g. dosage_amount)", text: $key)
                        .textInputAutocapitalization(.none)
                        .font(.system(.body, design: .monospaced))
                    TextField("Display label (e.g. Dosage Amount)", text: $label)
                        .textInputAutocapitalization(.words)
                    Picker("Type", selection: $type) {
                        ForEach(ActionFieldType.allCases, id: \.self) { fieldType in
                            Text(fieldType.rawValue.capitalized).tag(fieldType)
                        }
                    }
                } header: {
                    Text("New Parameter Field")
                } footer: {
                    Text("Key must be alphanumeric with underscores only.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(!canAdd)
                    .fontWeight(.semibold)
                }
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
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var category: ActionCategory = .custom
    @Published var iconKey: String? = "sparkles"
    @Published var accentColor: Color = .green
    @Published var fields: [ActionField] = []
    @Published var errorMessage: String? = nil
    @Published var isSaving: Bool = false

    let isEditing: Bool
    private let editingActionId: UUID?
    private let api: AuthAPI
    let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore, editingAction: UserAction? = nil) {
        self.api = api
        self.authStore = authStore
        self.editingActionId = editingAction?.id
        self.isEditing = editingAction != nil

        if let action = editingAction {
            self.name = action.name
            self.description = action.description ?? ""
            self.category = action.category
            self.iconKey = action.iconKey
            self.fields = action.parameters?.fields ?? []
            if let hex = action.color {
                self.accentColor = Color(hex: hex)
            }
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && name.count >= 2
        && name.count <= 100
        && !isSaving
    }

    func addField(_ field: ActionField) {
        guard fields.count < 20 else { return }
        fields.append(field)
    }

    func removeField(_ field: ActionField) {
        fields.removeAll { $0.key == field.key }
    }

    func save() async -> UserAction? {
        guard canSave else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return nil
        }

        let parameters = fields.isEmpty ? nil : ActionParameters(fields: fields)
        let colorHex = accentColor.toHex()

        if let editingId = editingActionId {
            let payload = UserActionUpdate(
                name: name,
                description: description.isEmpty ? nil : description,
                category: category,
                parameters: parameters,
                iconKey: iconKey,
                color: colorHex
            )
            do {
                return try await api.updateUserAction(token: token, actionId: editingId, payload: payload)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to update action."
                return nil
            }
        } else {
            let payload = UserActionCreate(
                name: name,
                description: description.isEmpty ? nil : description,
                category: category,
                parameters: parameters,
                iconKey: iconKey,
                color: colorHex
            )
            do {
                return try await api.createUserAction(token: token, payload: payload)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to create action."
                return nil
            }
        }
    }
}
