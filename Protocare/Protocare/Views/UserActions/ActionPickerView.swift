import SwiftUI

struct ActionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store: UserActionsStore
    @State private var searchText = ""
    @State private var selectedTab: PickerTab = .library
    @State private var selectedLibraryCategory: ActionsCategory? = nil
    @State private var isShowingCreator = false

    // Library data (loaded here, not in UserActionsStore)
    @State private var libraryActions: [ActionItem] = []
    @State private var isLoadingLibrary = false

    private let api: AuthAPI
    private let onSelect: (ActionItem) -> Void

    enum PickerTab: String, CaseIterable, Identifiable {
        case library = "Library"
        case custom = "Custom"
        var id: String { rawValue }
    }

    enum ActionsCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case topical = "Topical"
        case oral = "Oral"
        case device = "Device"
        case hygiene = "Hygiene"
        var id: String { rawValue }
    }

    init(api: AuthAPI, authStore: AuthStore, onSelect: @escaping (ActionItem) -> Void) {
        _store = StateObject(wrappedValue: UserActionsStore(api: api, authStore: authStore))
        self.api = api
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                // Tab picker
                Section {
                    Picker("", selection: $selectedTab) {
                        ForEach(PickerTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if selectedTab == .library {
                    libraryContent
                } else {
                    customContent
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCreator = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $isShowingCreator) {
                ActionCreatorView(
                    api: store.api,
                    authStore: store.authStore,
                    onCreated: { action in
                        let item = ActionItem(
                            id: action.id.uuidString,
                            name: action.name,
                            userActionId: action.id,
                            userActionCategory: action.category
                        )
                        onSelect(item)
                        dismiss()
                    }
                )
            }
            .task {
                await loadAllData()
            }
        }
    }

    // MARK: - Library Tab

    @ViewBuilder
    private var libraryContent: some View {
        Section {
            // Category chips for library (substance type filter)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ActionsCategory.allCases) { cat in
                        ActionCategoryPill(
                            label: cat.rawValue,
                            isSelected: selectedLibraryCategory == cat || (cat == .all && selectedLibraryCategory == nil),
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedLibraryCategory = cat == .all ? nil : cat
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }

        Section {
            if isLoadingLibrary && libraryActions.isEmpty {
                ProgressView("Loading actions...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if filteredLibraryActions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No matching actions")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(filteredLibraryActions) { action in
                    LibraryListRow(action: action) {
                        onSelect(action)
                        dismiss()
                    }
                }
            }
        } header: {
            HStack {
                Text("Predefined Actions")
                Spacer()
                Text("\(filteredLibraryActions.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Custom Tab

    @ViewBuilder
    private var customContent: some View {
        if !store.templates.isEmpty {
            Section {
                ForEach(filteredTemplates) { action in
                    CustomActionRow(
                        action: ActionItem(
                            id: action.id.uuidString,
                            name: action.name,
                            userActionId: action.id,
                            userActionCategory: action.category
                        ),
                        userAction: action,
                        onAdd: {
                            let item = ActionItem(
                                id: action.id.uuidString,
                                name: action.name,
                                userActionId: action.id,
                                userActionCategory: action.category
                            )
                            onSelect(item)
                            dismiss()
                        }
                    )
                }
            } header: {
                Text("Templates")
            }
        }

        Section {
            if store.isLoading && store.userActions.isEmpty {
                ProgressView("Loading actions...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if filteredCustomActions.isEmpty && filteredTemplates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No custom actions yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Create your first custom action to track anything you want.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(filteredCustomActions) { action in
                    CustomActionRow(
                        action: ActionItem(
                            id: action.id.uuidString,
                            name: action.name,
                            userActionId: action.id,
                            userActionCategory: action.category
                        ),
                        userAction: action,
                        onAdd: {
                            let item = ActionItem(
                                id: action.id.uuidString,
                                name: action.name,
                                userActionId: action.id,
                                userActionCategory: action.category
                            )
                            onSelect(item)
                            dismiss()
                        }
                    )
                }
            }
        } header: {
            HStack {
                Text("My Actions")
                Spacer()
                Text("\(filteredCustomActions.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Filtering

    private var filteredLibraryActions: [ActionItem] {
        libraryActions.filter { action in
            let matchesCategory: Bool = {
                guard let category = selectedLibraryCategory, category != .all else { return true }
                return action.substance?.type.rawValue == category.rawValue
            }()
            let matchesSearch = searchText.isEmpty || action.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var filteredCustomActions: [UserAction] {
        store.activeActions.filter { action in
            let matchesSearch = searchText.isEmpty || action.name.localizedCaseInsensitiveContains(searchText)
            return matchesSearch
        }
    }

    private var filteredTemplates: [UserAction] {
        store.templates.filter { action in
            let matchesSearch = searchText.isEmpty || action.name.localizedCaseInsensitiveContains(searchText)
            return matchesSearch
        }
    }

    // MARK: - Data Loading

    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadLibraryActions() }
            group.addTask { await store.loadUserActions() }
        }
    }

    private func loadLibraryActions() async {
        guard let token = store.authStore.accessToken else { return }
        isLoadingLibrary = true
        defer { isLoadingLibrary = false }

        do {
            async let fetchedActions = api.fetchActions(token: token, query: nil)
            async let fetchedSubstances = api.fetchSubstances(token: token, query: nil)
            let (actions, substances) = try await (fetchedActions, fetchedSubstances)
            libraryActions = actions.toActionItems(using: substances)
        } catch {
            // Non-critical — library tab will show empty state
        }
    }
}

// MARK: - Category Pill

private struct ActionCategoryPill: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.appPrimary : Color.appPrimaryLight)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
