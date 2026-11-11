import SwiftUI

struct JournalListView: View {
    @ObservedObject var vm: JournalListViewModel
    let api: AuthAPI
    let authStore: AuthStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                Group {
                    if vm.isLoading {
                        ProgressView()
                    } else if vm.protocols.isEmpty {
                        ContentUnavailableView(
                            "No Protocols",
                            systemImage: "book.closed.fill",
                            description: Text("Create a protocol to start journaling your outcomes")
                        )
                    } else {
                        List(vm.protocols) { item in
                            NavigationLink(value: item) {
                                ProtocolJournalRow(protocol: item)
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ProtocolItem.self) { item in
                OutcomeJournalView(
                    vm: OutcomeJournalViewModel(protocol: item, api: api, authStore: authStore)
                )
            }
            .task {
                await vm.load()
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    /// Custom in-screen header (D6), mirroring the other tab roots:
    /// header block above the content with its own page padding,
    /// nav bar hidden.
    private var header: some View {
        ScreenHeader(title: "Journal")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.vertical, 12)
    }
}

private struct ProtocolJournalRow: View {
    let `protocol`: ProtocolItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: `protocol`.category?.tagIcon ?? "list.clipboard.fill")
                .font(.appSectionTitle)
                .foregroundStyle(`protocol`.category?.tagColor ?? Color.appPrimary)
                .frame(width: 36, height: 36)
                .background((`protocol`.category?.tagColor ?? Color.appPrimary).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))

            VStack(alignment: .leading, spacing: 4) {
                Text(`protocol`.name)
                    .font(.appCardTitle)
                if let category = `protocol`.category {
                    Text(category.displayName)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            Spacer()

            if `protocol`.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.appCaption)
                        .foregroundStyle(Color.appWarning)
                    Text("\(`protocol`.streak)")
                        .font(.appCaptionBold)
                        .foregroundStyle(Color.appWarning)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
