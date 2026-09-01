import SwiftUI

struct UserActionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditor = false
    @State private var isShowingDeleteConfirmation = false
    @StateObject private var store: UserActionsStore
    let action: UserAction
    private let onEdited: (() -> Void)?
    private let onDeleted: (() -> Void)?

    init(api: AuthAPI, authStore: AuthStore, action: UserAction, onEdited: (() -> Void)? = nil, onDeleted: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: UserActionsStore(api: api, authStore: authStore))
        self.action = action
        self.onEdited = onEdited
        self.onDeleted = onDeleted
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: action.displayColor).opacity(0.15))
                        Image(systemName: action.displayIcon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: action.displayColor))
                    }
                    .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(action.name)
                            .font(.title3.weight(.bold))
                        HStack(spacing: 6) {
                            Label(action.category.displayName, systemImage: action.category.tagIcon)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let description = action.description, !description.isEmpty {
                Section {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                } header: {
                    Text("Description")
                }
            }

            if let fields = action.parameters?.fields, !fields.isEmpty {
                Section {
                    ForEach(fields) { field in
                        HStack {
                            Text(field.label)
                                .font(.body)
                            Spacer()
                            Text(field.type.rawValue.capitalized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            if field.isRequired {
                                Text("*")
                                    .foregroundStyle(.red)
                                    .font(.footnote.weight(.bold))
                            }
                            if let unit = field.unit {
                                Text("(\(unit))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Parameters")
                }
            }

            Section {
                LabeledContent("Protocols", value: "\(action.protocolCount)")
                LabeledContent("Created", value: action.createdAt, format: .dateTime.month().day().year())
                LabeledContent("Updated", value: action.updatedAt, format: .dateTime.month().day().year())
            } header: {
                Text("Info")
            }

            Section {
                Button {
                    isShowingEditor = true
                } label: {
                    Label("Edit Action", systemImage: "pencil")
                }

                Button {
                    Task {
                        let duplicated = await store.duplicateAction(id: action.id)
                        if duplicated != nil {
                            dismiss()
                        }
                    }
                } label: {
                    Label("Duplicate Action", systemImage: "doc.on.doc")
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("Delete Action", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Action Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingEditor) {
            ActionCreatorView(
                api: store.api,
                authStore: store.authStore,
                editingAction: action,
                onCreated: { _ in
                    onEdited?()
                    dismiss()
                }
            )
        }
        .alert("Delete Action", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let deleted = await store.deleteUserAction(id: action.id)
                    if deleted {
                        onDeleted?()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(action.name)\"? This action cannot be undone.")
        }
    }
}
