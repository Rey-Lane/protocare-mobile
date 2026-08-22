import SwiftUI

struct ProtocolBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ProtocolBuilderViewModel
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var scheduleAction: ActionItem?
    @State private var isShowingActionPicker = false
    @State private var isShowingIconPicker = false
    @State private var showingAllMetrics = false
    private let onSaved: (() -> Void)?

    private let protocolIcons = [
        "🧴", "💊", "🏃", "🧘", "🥗", "🧠",
        "💤", "🔬", "🩺", "🧪", "🫀", "💪",
        "🎯", "📅", "✨", "🌿", "🫧", "🧖",
        "💆", "🦷", "👁️", "🫁", "🦴", "❤️‍🩹"
    ]

    init(api: AuthAPI, authStore: AuthStore, onSaved: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: ProtocolBuilderViewModel(api: api, authStore: authStore))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    coverImageSection
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section {
                    header
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)

                Section {
                    TextField("e.g. Longevity Stack v1", text: $vm.draft.name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Protocol Name")
                }

                Section {
                    Button {
                        isShowingIconPicker = true
                    } label: {
                        HStack {
                            if let icon = vm.draft.icon {
                                Text(icon)
                                    .font(.system(size: 28))
                            } else {
                                Image(systemName: "circle.dashed")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)
                            }
                            Text(vm.draft.icon == nil ? "Choose Icon" : "Change Icon")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Icon")
                }

                Section {
                    Menu {
                        ForEach(ProtocolCategory.allCases) { cat in
                            Button {
                                vm.draft.category = vm.draft.category == cat ? nil : cat
                            } label: {
                                Label(cat.displayName, systemImage: vm.draft.category == cat ? "checkmark" : cat.tagIcon)
                            }
                        }
                    } label: {
                        HStack {
                            Text(vm.draft.category?.displayName ?? "Select a goal")
                                .foregroundStyle(vm.draft.category == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Goal")
                }

                Section {
                    // Show category defaults + any user-selected metrics not in defaults (no duplicates)
                    let categoryDefaults: [MetricKey] = {
                        if let cat = vm.draft.category { return MetricKey.defaults(for: cat) }
                        return []
                    }()
                    let selectedNonDefault: [MetricKey] = {
                        guard let selected = vm.draft.metricKeys else { return [] }
                        return selected.filter { !categoryDefaults.contains($0) }
                    }()
                    let displayedMetrics = categoryDefaults + selectedNonDefault

                    if displayedMetrics.isEmpty {
                        Text("Select a goal to see recommended metrics")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(displayedMetrics) { metric in
                            Button {
                                if vm.draft.metricKeys?.contains(metric) == true {
                                    vm.draft.metricKeys?.removeAll { $0 == metric }
                                    if vm.draft.metricKeys?.isEmpty == true { vm.draft.metricKeys = nil }
                                } else {
                                    if vm.draft.metricKeys == nil { vm.draft.metricKeys = [] }
                                    vm.draft.metricKeys?.append(metric)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: metric.icon)
                                        .foregroundStyle(Color.appPrimary)
                                    Text(metric.label)
                                    Spacer()
                                    if vm.draft.metricKeys?.contains(metric) == true {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        showingAllMetrics = true
                    } label: {
                        Label("Add more metrics", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundStyle(Color.appPrimary)
                    }
                } header: {
                    Text("Journal Metrics")
                }

                Section {
                    if vm.isLoading && vm.draft.actions.isEmpty {
                        ProgressView("Loading actions...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(vm.draft.actions) { action in
                            ActionRow(
                                action: action,
                                onSettings: {
                                    scheduleAction = action
                                },
                                onRemove: {
                                    vm.removeAction(action)
                                }
                            )
                        }
                    }
                } header: {
                    HStack {
                        Text("Atomic Actions")
                        Spacer()
                        Text("\(vm.draft.actions.count) STEPS")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Picker("", selection: $vm.selectedTab) {
                        Text("Library").tag(ProtocolBuilderViewModel.Tab.library)
                        Text("Custom").tag(ProtocolBuilderViewModel.Tab.custom)
                    }
                    .pickerStyle(.segmented)

                    if vm.selectedTab == .library {
                        CategoryChips(
                            selectedCategory: $vm.selectedCategory,
                            onSelect: { _ in }
                        )
                        .padding(.vertical, 6)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 14))
                            TextField("Search actions...", text: $vm.searchQuery)
                                .font(.system(size: 15))
                            if !vm.searchQuery.isEmpty {
                                Button {
                                    vm.searchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 4, trailing: 16))

                        libraryTabContent
                    } else {
                        customTabContent
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Protocol Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            let wasSaved = await vm.save()
                            guard wasSaved else { return }
                            onSaved?()
                            dismiss()
                        }
                    }
                    .disabled(!vm.canSave)
                    .foregroundStyle(vm.canSave ? Color.appPrimary : .secondary)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                if vm.imageUploadFailed {
                    Button("Retry Image") {
                        vm.errorMessage = nil
                        Task {
                            let saved = await vm.retryImageUpload()
                            if saved { onSaved?(); dismiss() }
                        }
                    }
                }
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, isPresented: $isShowingImagePicker) { _, data in
                    vm.selectImage(data)
                }
            }
            .task {
                await vm.loadActions()
            }
            .sheet(item: $scheduleAction) { action in
                ScheduleActionSheet(action: action) { schedule, slots in
                    vm.updateSchedule(for: action, schedule: schedule, slots: slots)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $isShowingActionPicker) {
                ActionPickerView(
                    api: vm.api,
                    authStore: vm.authStore,
                    onSelect: { actionItem in
                        vm.addPredefinedAction(actionItem)
                    }
                )
            }
            .sheet(isPresented: $isShowingIconPicker) {
                iconPickerSheet
            }
            .onChange(of: vm.draft.category) { _, newCategory in
                if let newCategory {
                    let categoryDefaults = MetricKey.defaults(for: newCategory)
                    let existing = vm.draft.metricKeys ?? []
                    // Preserve user-selected metrics that aren't in the new defaults
                    let userCustom = existing.filter { !categoryDefaults.contains($0) }
                    vm.draft.metricKeys = categoryDefaults + userCustom
                }
            }
            .sheet(isPresented: $showingAllMetrics) {
                NavigationStack {
                    List {
                        ForEach(MetricKey.allCases) { metric in
                            Button {
                                if vm.draft.metricKeys?.contains(metric) == true {
                                    vm.draft.metricKeys?.removeAll { $0 == metric }
                                    if vm.draft.metricKeys?.isEmpty == true { vm.draft.metricKeys = nil }
                                } else {
                                    if vm.draft.metricKeys == nil { vm.draft.metricKeys = [] }
                                    vm.draft.metricKeys?.append(metric)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: metric.icon)
                                        .foregroundStyle(Color.appPrimary)
                                    VStack(alignment: .leading) {
                                        Text(metric.label)
                                        Text(metric.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if vm.draft.metricKeys?.contains(metric) == true {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .navigationTitle("All Metrics")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingAllMetrics = false }
                        }
                    }
                }
            }
        }
    }

    private var coverImageSection: some View {
        Group {
            if let selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .frame(maxHeight: 240)
                        .clipped()

                    Button {
                        self.selectedImage = nil
                        vm.removeSelectedImage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                    }
                    .padding(12)
                }

                Button("Change Cover") {
                    isShowingImagePicker = true
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .padding(.top, 8)
            } else {
                Button {
                    isShowingImagePicker = true
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "add_a_photo")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Add Protocol Cover")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .background(Color(.systemGray6).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var iconPickerSheet: some View {
        NavigationStack {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(protocolIcons, id: \.self) { icon in
                        Button {
                            vm.draft.icon = icon
                            isShowingIconPicker = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(vm.draft.icon == icon ? Color.appPrimary.opacity(0.15) : Color(.systemGray6))
                                    .frame(width: 48, height: 48)
                                Text(icon)
                                    .font(.system(size: 26))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isShowingIconPicker = false }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Define Protocol")
                .font(.system(size: 30, weight: .bold))
            Text("Set the foundation for your new routine")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var libraryTabContent: some View {
        if vm.isLoading && vm.availableActions.isEmpty {
            ProgressView("Loading actions...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
        } else if vm.filteredActions.isEmpty {
            VStack(spacing: 8) {
                Text(vm.searchQuery.isEmpty && vm.selectedCategory == nil ? "No actions found." : "No matching actions.")
                    .foregroundStyle(.secondary)
                if vm.searchQuery.isEmpty && vm.selectedCategory == nil {
                    Button("Reload") {
                        Task { await vm.loadActions() }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            ForEach(vm.filteredActions) { action in
                LibraryListRow(
                    action: action,
                    onAdd: { vm.addPredefinedAction(action) }
                )
            }
        }
    }

    @ViewBuilder
    private var customTabContent: some View {
        if vm.customActionItems.isEmpty && vm.userActions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Create custom actions")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Build your own tracking actions with custom parameters, then add them to your protocols.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    Button {
                        isShowingActionPicker = true
                    } label: {
                        Label("Browse & Create Actions", systemImage: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appPrimary)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(vm.customActionItems) { action in
                    CustomActionRow(
                        action: action,
                        userAction: vm.userActions.first(where: { $0.id.uuidString == action.id }),
                        onAdd: { vm.addPredefinedAction(action) }
                    )
                }

                Button {
                    isShowingActionPicker = true
                } label: {
                    Label("New Custom Action", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
    }
}
