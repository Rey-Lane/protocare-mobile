import SwiftUI

/// Unified action picker (Step 21 of the unified action model migration).
///
/// Replaces the old Library/Custom tab split with a single list fed by
/// `GET /actions` (library + user-created actions in one unified collection):
///  - category chips (primary filter): All + 10 `ActionCategory` cases
///  - modality chips (secondary filter): All + 5 `ActionModality` cases
///  - client-side search over the loaded actions
///  - "Create custom action" row at the bottom (existing ActionCreatorView flow)
struct ActionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ActionCategory?
    @State private var selectedModality: ActionModality?
    @State private var isShowingCreator = false
    @State private var actions: [ActionItem] = []
    @State private var isLoading = false
    @State private var loadFailed = false

    private let api: AuthAPI
    private let authStore: AuthStore
    private let onSelect: (ActionItem) -> Void

    init(api: AuthAPI, authStore: AuthStore, onSelect: @escaping (ActionItem) -> Void) {
        self.api = api
        self.authStore = authStore
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                filterChipsSection

                actionsSection

                Section {
                    Button {
                        isShowingCreator = true
                    } label: {
                        Label("Create custom action", systemImage: "plus.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Search actions...")
            .navigationTitle("Choose Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingCreator) {
                ActionCreatorView(
                    api: api,
                    authStore: authStore,
                    onCreated: { action in
                        // Custom actions come back with no schedule/UI state —
                        // the caller adds it to a protocol with the default
                        // parameters attached.
                        let item = ActionItem(
                            id: action.id,
                            name: action.name,
                            substanceId: nil,
                            substance: nil,
                            volume: nil,
                            durationSeconds: nil,
                            category: action.category,
                            modality: action.modality,
                            defaultParameters: action.defaultParameters,
                            isLibrary: false
                        )
                        onSelect(item)
                        dismiss()
                    }
                )
            }
            .task {
                if actions.isEmpty {
                    await loadActions()
                }
            }
            .refreshable {
                await loadActions()
            }
        }
    }

    // MARK: - Filter Chips

    /// Primary axis (ActionCategory) + secondary axis (ActionModality),
    /// each preceded by an "All" chip, both scrolling horizontally.
    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All",
                        icon: nil,
                        color: .appPrimary,
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                    }

                    ForEach(ActionCategory.allCases) { category in
                        FilterChip(
                            label: category.displayName,
                            icon: category.tagIcon,
                            color: category.tagColor,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = category }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All",
                        icon: nil,
                        color: .appPrimary,
                        isSelected: selectedModality == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedModality = nil }
                    }

                    ForEach(ActionModality.allCases, id: \.self) { modality in
                        FilterChip(
                            label: modality.displayName,
                            icon: nil,
                            color: .appPrimary,
                            isSelected: selectedModality == modality
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedModality = modality }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            if isLoading && actions.isEmpty {
                ProgressView("Loading actions...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else if filteredActions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: loadFailed ? "wifi.exclamationmark" : "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(loadFailed ? "Couldn't load actions." : "No matching actions")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if loadFailed {
                        Button("Retry") {
                            Task { await loadActions() }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(filteredActions) { action in
                    UnifiedActionRow(action: action) {
                        onSelect(action)
                        dismiss()
                    }
                }
            }
        } header: {
            HStack {
                Text("Actions")
                Spacer()
                Text("\(filteredActions.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Filtering

    private var filteredActions: [ActionItem] {
        actions.filter { action in
            let matchesCategory = selectedCategory == nil || action.category == selectedCategory
            let matchesModality = selectedModality == nil || action.modality == selectedModality
            let matchesSearch = searchText.isEmpty
                || action.name.localizedCaseInsensitiveContains(searchText)
                || action.displayName.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesModality && matchesSearch
        }
    }

    // MARK: - Data Loading

    private func loadActions() async {
        guard let token = authStore.accessToken else {
            loadFailed = true
            return
        }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }

        do {
            // Unified actions (library + user-created) in one request.
            // No substances lookup: Action carries name/category/modality itself.
            let fetched = try await api.fetchActions(token: token, category: nil, modality: nil, query: nil)
            actions = fetched.toActionItems()
        } catch {
            // Keep whatever was loaded before; flag failure only when the
            // list would otherwise be empty.
            if actions.isEmpty {
                loadFailed = true
            }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? color : Color(.systemGray5))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unified Action Row

/// Row for the unified picker: name + category tag (tagColor + tagIcon)
/// + modality badge when the action has one.
private struct UnifiedActionRow: View {
    let action: ActionItem
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(action.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: action.category.tagIcon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(action.category.displayName)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .foregroundStyle(action.category.tagColor)
                        .background(action.category.tagColor.opacity(0.14))
                        .clipShape(Capsule())

                        if let modality = action.modality {
                            Text(modality.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .foregroundStyle(.secondary)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Text("+ Add")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.appPrimary.opacity(0.12))
                    .foregroundStyle(Color.appPrimary)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
