import SwiftUI

struct TemplatesView: View {
    @StateObject private var vm: TemplatesViewModel
    @Environment(\.dismiss) private var dismiss
    let onProtocolCreated: () -> Void
    private let accent = Color.appPrimary

    init(api: AuthAPI, authStore: AuthStore, onProtocolCreated: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: TemplatesViewModel(api: api, authStore: authStore))
        self.onProtocolCreated = onProtocolCreated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if vm.isLoading && vm.templates.isEmpty {
                        ProgressView("Loading templates...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if let error = vm.errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .foregroundStyle(Color(.systemRed))
                            Button("Retry") { Task { await vm.loadTemplates() } }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else if vm.templates.isEmpty {
                        emptyState
                    } else {
                        categoriesList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .task { await vm.loadTemplates() }
            .alert("Error", isPresented: .constant(vm.creationErrorMessage != nil)) {
                Button("OK") { vm.creationErrorMessage = nil }
            } message: {
                Text(vm.creationErrorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                }
                Spacer()
            }
            Text("Protocol Templates")
                .font(.system(size: 28, weight: .bold))
            Text("Start with a pre-built routine and customize it")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No templates available yet.")
                .font(.headline)
            Text("Templates will appear here when they are added.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 60)
    }

    private var categoriesList: some View {
        VStack(spacing: 28) {
            ForEach(vm.groupedByCategory, id: \.category.id) { category, templates in
                VStack(alignment: .leading, spacing: 14) {
                    categoryHeader(category: category)

                    VStack(spacing: 12) {
                        ForEach(templates) { template in
                            TemplateCardView(
                                template: template,
                                isCreating: vm.isCreating,
                                onUse: {
                                    Task {
                                        let success = await vm.createProtocol(from: template)
                                        if success {
                                            onProtocolCreated()
                                            dismiss()
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private func categoryHeader(category: TemplateCategory) -> some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
            Text(category.displayName)
                .font(.system(size: 20, weight: .bold))
        }
    }
}

private struct TemplateCardView: View {
    let template: ProtocolTemplate
    let isCreating: Bool
    let onUse: () -> Void
    private let accent = Color.appPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroImage

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)

                        if let desc = template.description, !desc.isEmpty {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    stepsPill
                }

                actionDraftsPreview

                HStack {
                    Spacer()
                    Button(action: onUse) {
                        HStack(spacing: 6) {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text("Use Template")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isCreating)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }

    private var heroImage: some View {
        Group {
            if let imageUrl = template.imageUrl, !imageUrl.isEmpty {
                ResilientAsyncImage(urlString: imageUrl, contentMode: .fill) {
                    gradientPlaceholder
                }
                .frame(height: 160)
                .clipped()
            } else {
                gradientPlaceholder
                    .frame(height: 100)
            }
        }
    }

    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: [
                accent.opacity(0.3),
                accent.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: template.category.icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
        )
    }

    private var stepsPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "list.bullet")
                .font(.system(size: 12, weight: .semibold))
            Text(template.stepsLabel)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
    }

    private var actionDraftsPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(template.actionDrafts.sorted(by: { $0.position < $1.position })) { draft in
                HStack(spacing: 8) {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(draft.position + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(accent)
                        )

                    Text(draft.substanceName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    if let dosage = draft.dosageLabel {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let schedule = draft.scheduleLabel {
                        Text(schedule)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
