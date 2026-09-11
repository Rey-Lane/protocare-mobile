import SwiftUI

struct ProtocolSettingsView: View {
    @ObservedObject private var vm: ProtocolSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAllMetrics = false
    @State private var isShowingIconPicker = false
    @State private var draggedActionId: String?

    private let accent = Color.appPrimary

    private let protocolIcons = [
        "🧴", "💊", "🏃", "🧘", "🥗", "🧠",
        "💤", "🔬", "🩺", "🧪", "🫀", "💪",
        "🎯", "📅", "✨", "🌿", "🫧", "🧖",
        "💆", "🦷", "👁️", "🫁", "🦴", "❤️‍🩹",
    ]

    init(vm: ProtocolSettingsViewModel) {
        _vm = ObservedObject(wrappedValue: vm)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                appearanceSection
                scheduleSection
                metricsSection
                actionsSection
                deleteSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Protocol Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        let saved = await vm.save()
                        if saved { dismiss() }
                    }
                }
                .disabled(!vm.canSave)
                .fontWeight(.semibold)
                .foregroundStyle(vm.canSave ? accent : .secondary)
            }
        }
        .alert("Update Failed", isPresented: .constant(vm.editError != nil), actions: {
            Button("OK") { vm.editError = nil }
        }, message: {
            Text(vm.editError ?? "")
        })
        .sheet(isPresented: $vm.isShowingEditImagePicker) {
            ImagePicker(selectedImage: $vm.editSelectedImage, isPresented: $vm.isShowingEditImagePicker) { _, data in
                vm.editImageData = data
                vm.editImageChanged = true
                vm.editImageRemoved = false
            }
        }
        .sheet(item: $vm.scheduleAction) { action in
            ScheduleActionSheet(action: action) { schedule, slots in
                vm.updateSchedule(for: action, schedule: schedule, slots: slots)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $vm.isShowingActionPicker) {
            ActionPickerView(
                api: vm.api,
                authStore: vm.authStore,
                onSelect: { actionItem in
                    vm.addAction(actionItem)
                }
            )
        }
        .sheet(isPresented: $isShowingIconPicker) {
            iconPickerSheet
        }
        .sheet(isPresented: $showingAllMetrics) {
            allMetricsSheet
        }
        .confirmationDialog(
            "Delete Protocol?",
            isPresented: $vm.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // Handled by parent via Notification or callback
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. The protocol and all its data will be permanently removed.")
        }
        .task {
            await vm.loadAvailableActions()
        }
        .onChange(of: vm.editCategory) { _, newCategory in
            if let newCategory {
                let categoryDefaults = MetricKey.defaults(for: newCategory)
                let existing = vm.editMetricKeys ?? []
                let userCustom = existing.filter { !categoryDefaults.contains($0) }
                vm.editMetricKeys = categoryDefaults + userCustom
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground

            VStack(alignment: .leading, spacing: 8) {
                if let category = vm.editCategory {
                    Text(category.displayName.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(vm.protocolImageURL == nil ? .secondary : Color.white.opacity(0.7))
                        .tracking(1.5)
                }

                Text(vm.editName.isEmpty ? "Untitled Protocol" : vm.editName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(vm.protocolImageURL == nil ? Color.primary : Color.white)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    statusPill
                    stepsPill
                }
            }
            .padding(18)
        }
    }

    @ViewBuilder
    private var heroBackground: some View {
        if let urlString = vm.protocolImageURL, !urlString.isEmpty {
            ResilientAsyncImage(urlString: urlString) {
                heroFallbackBackground
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.15), Color.black.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            heroFallbackBackground
        }
    }

    private var heroFallbackBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator).opacity(0.08))
            )
    }

    private var statusPill: some View {
        Text(vm.editIsActive ? "ACTIVE" : "PAUSED")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                vm.protocolImageURL == nil
                ? (vm.editIsActive ? accent.opacity(0.18) : Color(.systemGray5))
                : Color.black.opacity(0.35)
            )
            .foregroundStyle(vm.protocolImageURL == nil ? (vm.editIsActive ? accent : .secondary) : Color.white)
            .clipShape(Capsule())
    }

    private var stepsPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet")
                .font(.system(size: 12, weight: .semibold))
            Text("\(vm.editActions.count) steps")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(vm.protocolImageURL == nil ? Color(.systemGray5) : Color.black.opacity(0.35))
        .foregroundStyle(vm.protocolImageURL == nil ? Color.secondary : Color.white)
        .clipShape(Capsule())
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Appearance")

            // Protocol Name
            SettingsRow(icon: "textformat", label: "Name") {
                TextField("e.g. Morning Glow", text: $vm.editName)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.words)
            }

            SettingsDivider()

            // Cover Image
            SettingsRow(icon: "photo", label: "Cover") {
                HStack(spacing: 8) {
                    if vm.editImageRemoved {
                        Text("None")
                            .foregroundStyle(.secondary)
                    } else if vm.editSelectedImage != nil {
                        Text("Updated")
                            .foregroundStyle(accent)
                    } else if vm.protocolImageURL != nil {
                        Text("Set")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Add")
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if vm.editImageRemoved || vm.protocolImageURL == nil {
                    vm.isShowingEditImagePicker = true
                } else {
                    // Show change/remove options
                    vm.isShowingEditImagePicker = true
                }
            }

            SettingsDivider()

            // Icon
            SettingsRow(icon: "face.dashed", label: "Icon") {
                HStack(spacing: 8) {
                    if let icon = vm.editIcon {
                        Text(icon)
                            .font(.system(size: 22))
                    } else {
                        Text("Choose")
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingIconPicker = true
            }

            SettingsDivider()

            // Goal / Category
            SettingsRow(icon: "target", label: "Goal") {
                HStack(spacing: 8) {
                    Text(vm.editCategory?.displayName ?? "Select")
                        .foregroundStyle(vm.editCategory == nil ? .secondary : .primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Show category menu inline — handled by the Menu below
            }
            .contextMenu {
                ForEach(ActionCategory.allCases) { cat in
                    Button {
                        vm.editCategory = vm.editCategory == cat ? nil : cat
                    } label: {
                        Label(cat.displayName, systemImage: vm.editCategory == cat ? "checkmark" : cat.tagIcon)
                    }
                }
            }

            // Remove cover button
            if (vm.protocolImageURL != nil || vm.editSelectedImage != nil) && !vm.editImageRemoved {
                SettingsDivider()
                Button {
                    vm.editSelectedImage = nil
                    vm.editImageData = nil
                    vm.editImageChanged = true
                    vm.editImageRemoved = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                        Text("Remove Cover")
                            .foregroundStyle(.red)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Schedule")

            SettingsRow(icon: "bolt.fill", label: "Active") {
                Toggle("", isOn: $vm.editIsActive)
                    .tint(accent)
                    .labelsHidden()
            }

            SettingsDivider()

            SettingsRow(icon: "calendar", label: "Start Date") {
                DatePicker("", selection: $vm.editStartedAt, displayedComponents: .date)
                    .labelsHidden()
            }

            SettingsDivider()

            SettingsRow(icon: "flag.checkered", label: "End Date") {
                HStack(spacing: 8) {
                    if vm.hasEditEndedAt {
                        DatePicker("", selection: Binding(
                            get: { vm.editEndedAt ?? Date() },
                            set: { vm.editEndedAt = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    } else {
                        Text("Not set")
                            .foregroundStyle(.secondary)
                    }
                    Toggle("", isOn: $vm.hasEditEndedAt)
                        .tint(accent)
                        .labelsHidden()
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Journal Metrics", count: vm.editMetricKeys?.count)

            // Bug #1 fix: show only metrics the user actually selected
            // (selected category defaults first, then any custom picks).
            // The old `categoryDefaults + selectedNonDefault` formula kept
            // unselected defaults permanently visible in the list.
            let displayedMetrics: [MetricKey] = {
                let selected = vm.editMetricKeys ?? []
                let defaults = vm.editCategory.map { MetricKey.defaults(for: $0) } ?? []
                let selectedDefaults = defaults.filter { selected.contains($0) }
                let customPicks = selected.filter { !defaults.contains($0) }
                return selectedDefaults + customPicks
            }()

            if displayedMetrics.isEmpty {
                Text(vm.editCategory == nil
                     ? "Select a goal to see recommended metrics"
                     : "No metrics selected — add the ones you want to track")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(displayedMetrics) { metric in
                    Button {
                        if vm.editMetricKeys?.contains(metric) == true {
                            vm.editMetricKeys?.removeAll { $0 == metric }
                            // Bug #2 fix: keep [] instead of collapsing to nil —
                            // nil drops metric_keys from the PATCH and the journal
                            // falls back to category defaults.
                        } else {
                            if vm.editMetricKeys == nil { vm.editMetricKeys = [] }
                            vm.editMetricKeys?.append(metric)
                        }
                    } label: {
                        HStack {
                            Image(systemName: metric.icon)
                                .foregroundStyle(accent)
                            Text(metric.label)
                            Spacer()
                            if vm.editMetricKeys?.contains(metric) == true {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(accent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if metric != displayedMetrics.last {
                        SettingsDivider()
                    }
                }
            }

            SettingsDivider()

            Button {
                showingAllMetrics = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(accent)
                    Text("Add more metrics")
                        .foregroundStyle(accent)
                        .font(.subheadline)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Protocol Steps", count: vm.editActions.count)

            if vm.editActions.isEmpty {
                Text("No actions yet. Add some below.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(vm.editActions) { action in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.displayName)
                                .font(.system(size: 15, weight: .semibold))
                            // Unified model (Step 23): category + modality badges
                            // replace provenance ("Library"/"Custom") labels.
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
                            if !action.scheduleSummaryText.isEmpty {
                                Text(action.scheduleSummaryText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if !action.tagLabel.isEmpty {
                                Text(action.tagLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            let reminderCount = action.slots.filter { $0.isReminderOn }.count
                            if reminderCount > 0 {
                                Text("🔔 \(reminderCount) reminder\(reminderCount > 1 ? "s" : "")")
                                    .font(.caption2)
                                    .foregroundStyle(accent)
                            }
                        }

                        Spacer()

                        Button {
                            vm.scheduleAction = action
                        } label: {
                            Image(systemName: "clock")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            vm.removeAction(action)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .opacity(draggedActionId == action.id ? 0.35 : 1)
                    .draggable(action.id) {
                        Text(action.displayName)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        draggedActionId = nil
                        guard let droppedId = items.first,
                              let sourceIndex = vm.editActions.firstIndex(where: { $0.id == droppedId })
                        else { return false }
                        let destIndex = vm.editActions.firstIndex(where: { $0.id == action.id }) ?? 0
                        guard sourceIndex != destIndex else { return false }
                        vm.editActions.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destIndex > sourceIndex ? destIndex + 1 : destIndex)
                        return true
                    } isTargeted: { isTargeted in
                        draggedActionId = isTargeted ? action.id : nil
                    }

                    if action != vm.editActions.last {
                        SettingsDivider()
                    }
                }
            }

            SettingsDivider()

            Button {
                vm.isShowingActionPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(accent)
                    Text("Add Action")
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Button {
            vm.showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Protocol")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon Picker Sheet

    private var iconPickerSheet: some View {
        NavigationStack {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(protocolIcons, id: \.self) { icon in
                        Button {
                            vm.editIcon = icon
                            isShowingIconPicker = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(vm.editIcon == icon ? accent.opacity(0.15) : Color(.systemGray6))
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

    // MARK: - All Metrics Sheet

    private var allMetricsSheet: some View {
        NavigationStack {
            List {
                ForEach(MetricKey.allCases) { metric in
                    Button {
                        if vm.editMetricKeys?.contains(metric) == true {
                            vm.editMetricKeys?.removeAll { $0 == metric }
                            // Bug #2 fix: keep [] instead of collapsing to nil.
                        } else {
                            if vm.editMetricKeys == nil { vm.editMetricKeys = [] }
                            vm.editMetricKeys?.append(metric)
                        }
                    } label: {
                        HStack {
                            Image(systemName: metric.icon)
                                .foregroundStyle(accent)
                            VStack(alignment: .leading) {
                                Text(metric.label)
                                Text(metric.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if vm.editMetricKeys?.contains(metric) == true {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(accent)
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

// MARK: - Shared Components

private struct SectionHeader: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            if let count {
                Text("\(count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

private struct SettingsRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .font(.body)

            Spacer()

            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 54)
    }
}
