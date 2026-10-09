import SwiftUI

struct ProtocolBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ProtocolBuilderViewModel
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var scheduleAction: ActionItem?
    @State private var isShowingActionPicker = false
    @State private var showingAllMetrics = false
    private let onSaved: (() -> Void)?

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
                    Menu {
                        ForEach(ActionCategory.allCases) { cat in
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
                    // Bug #1 fix: show only metrics the user actually selected
                    // (selected category defaults first, then any custom picks).
                    // The old `categoryDefaults + selectedNonDefault` formula kept
                    // unselected defaults permanently visible in the list.
                    let displayedMetrics: [MetricKey] = {
                        let selected = vm.draft.metricKeys ?? []
                        let defaults = vm.draft.category.map { MetricKey.defaults(for: $0) } ?? []
                        let selectedDefaults = defaults.filter { selected.contains($0) }
                        let customPicks = selected.filter { !defaults.contains($0) }
                        return selectedDefaults + customPicks
                    }()

                    if displayedMetrics.isEmpty {
                        Text(vm.draft.category == nil
                             ? "Select a goal to see recommended metrics"
                             : "No metrics selected — add the ones you want to track")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(displayedMetrics) { metric in
                            Button {
                                if vm.draft.metricKeys?.contains(metric) == true {
                                    vm.draft.metricKeys?.removeAll { $0 == metric }
                                    // Bug #2 fix: keep [] instead of collapsing to nil —
                                    // nil drops metric_keys from the JSON and the backend
                                    // re-auto-populates category defaults.
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
                    if vm.draft.actions.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "square.stack.3d.up.slash")
                                .font(.system(size: 26))
                                .foregroundStyle(.secondary)
                            Text("No actions yet")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("Add actions from the unified library to build your protocol.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                    Button {
                        isShowingActionPicker = true
                    } label: {
                        Label("Add Action", systemImage: "plus.circle.fill")
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
                        vm.addAction(actionItem)
                    }
                )
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
                                    // Bug #2 fix: keep [] instead of collapsing to nil.
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
}
