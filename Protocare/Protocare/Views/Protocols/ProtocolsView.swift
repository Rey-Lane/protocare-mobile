import SwiftUI

struct ProtocolsView: View {
    @ObservedObject var vm: ProtocolsViewModel
    let api: AuthAPI
    let authStore: AuthStore
    @State private var showingBuilder = false
    @State private var selectedProtocol: ProtocolItem?
    @State private var openEditOnAppear = false
    @State private var protocolToDelete: ProtocolItem? = nil
    @State private var isSearching = false



    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    header
                    if !vm.availableCategories.isEmpty {
                        categoryChips
                    }
                    if vm.isLoading && vm.protocols.isEmpty {
                        ProgressView("Loading protocols...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if let error = vm.errorMessage {
                        VStack(spacing: 12) {
                            Text(error)
                                .foregroundStyle(Color(.systemRed))
                            Button("Retry") { Task { await vm.load() } }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else if vm.filteredProtocols.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "leaf")
                                .font(.appEmptyStateIconLarge)
                                .foregroundStyle(Color.appPrimary)
                            Text("No protocols yet")
                                .font(.appCardTitle)
                            Text("Start building your first self-care routine...")
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                            Button {
                                showingBuilder = true
                            } label: {
                                Text("Create Protocol")
                                    .font(.appBody.weight(.semibold))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.appPrimary)
                                    .foregroundStyle(Color.appOnAccent)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else {
                        List {
                            ForEach(vm.filteredProtocols) { item in
                                ProtocolCardView(item: item, imageURL: vm.protocolImageURLs[item.id])
                                    .listRowInsets(EdgeInsets(top: 8, leading: AppSpacing.pagePadding, bottom: 8, trailing: AppSpacing.pagePadding))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            protocolToDelete = item
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            openEditOnAppear = true
                                            selectedProtocol = item
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Color.appWarning)
                                    }
                                    .onTapGesture {
                                        selectedProtocol = item
                                    }

                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }

                fab
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .task { await vm.load() }
            .navigationDestination(item: $selectedProtocol) { item in
                ProtocolDetailView(
                    item: item,
                    actionsLookup: vm.actionsLookup,
                    api: api,
                    authStore: authStore,
                    viewModel: vm,
                    initialProtocolImageURL: vm.protocolImageURLs[item.id],
                    autoOpenEdit: openEditOnAppear
                )
            }
            .navigationDestination(isPresented: $showingBuilder) {
                ProtocolBuilderView(
                    api: api,
                    authStore: authStore,
                    onSaved: {
                        showingBuilder = false
                        Task { await vm.load() }
                    }
                )
            }
            .onChange(of: selectedProtocol) { _, _ in
                if selectedProtocol == nil {
                    openEditOnAppear = false
                }
            }

            .alert("Unable to Delete Protocol", isPresented: deleteErrorPresented) {
                Button("OK", role: .cancel) {
                    vm.deletionErrorMessage = nil
                }
            } message: {
                Text(vm.deletionErrorMessage ?? "Something went wrong.")
            }
            .overlay {
                if protocolToDelete != nil {
                    ZStack {
                        Color.appText.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    protocolToDelete = nil
                                }
                            }

                        VStack(spacing: 0) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appError)
                                    .frame(width: 32, height: 32)
                                    .background(Color.appError.opacity(0.12))
                                    .clipShape(Circle())

                                Text("Delete Protocol?")
                                    .font(.appCardTitle)
                                    .foregroundStyle(Color.appText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                            Text("This action cannot be undone. The protocol and all its data will be permanently removed.")
                                .font(.appBody)
                                .foregroundStyle(Color.appTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)

                            Divider()
                                .padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        protocolToDelete = nil
                                    }
                                } label: {
                                    Text("Cancel")
                                        .font(.appBody.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.secondarySystemBackground))
                                        .foregroundStyle(Color.appText)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    if let item = protocolToDelete {
                                        Task { await vm.deleteProtocol(item) }
                                    }
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        protocolToDelete = nil
                                    }
                                } label: {
                                    Text("Delete")
                                        .font(.appBody.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.appError)
                                        .foregroundStyle(Color.appOnAccent)
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .frame(width: 280)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                        .shadow(color: Color.appText.opacity(0.15), radius: 20, y: 8)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if isSearching {
                HStack {
                    TextField("Search protocols...", text: $vm.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.appBody)

                    Button {
                        vm.searchQuery = ""
                        isSearching = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
            } else {
                Text("Protocol Library")
                    .font(.appScreenTitle)
            }

            Spacer()

            if !isSearching {
                Button {
                    isSearching = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(Color.appText)
                }
            }
        }
        .padding(.horizontal, AppSpacing.pagePadding)
        .padding(.vertical, 12)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "All",
                    isSelected: vm.selectedCategory == nil,
                    color: Color.appPrimary
                ) {
                    vm.selectedCategory = nil
                }

                ForEach(vm.availableCategories) { category in
                    CategoryChip(
                        label: category.displayName,
                        isSelected: vm.selectedCategory == category,
                        color: category.tagColor
                    ) {
                        vm.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, AppSpacing.pagePadding)
        }
        .padding(.bottom, 4)
    }

    private var fab: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showingBuilder = true
                } label: {
                    Image(systemName: "plus")
                        .font(.appSectionTitle)
                        .foregroundStyle(Color.appOnAccent)
                        .frame(width: 52, height: 52)
                        .background(Color.appPrimary)
                        .clipShape(Circle())
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private var deleteErrorPresented: Binding<Bool> {
        Binding(
            get: { vm.deletionErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    vm.deletionErrorMessage = nil
                }
            }
        )
    }
}

private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.appBody.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemBackground))
                .foregroundStyle(isSelected ? Color.appOnAccent : Color.appTextSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ProtocolCardView: View {
    let item: ProtocolItem
    let imageURL: String?
    private let primary = Color.appPrimary

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                if let category = item.category {
                    Text(category.displayName.uppercased())
                        .font(.appCaptionBold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(category.tagColor.opacity(0.18))
                        .foregroundStyle(category.tagColor)
                        .clipShape(Capsule())
                }

                Text(item.name)
                    .font(.appCardTitle)
                    .foregroundStyle(Color.appText)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.appCaption)
                        Text(item.stepsLabel)
                            .font(.appCaption)
                    }
                    .foregroundStyle(Color.appTextSecondary)

                    if item.streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.appCaption)
                                .foregroundStyle(Color.appWarning)
                            Text(item.streakLabel)
                                .font(.appCaption)
                                .foregroundStyle(Color.appWarning)
                        }
                    }
                }

                Button {
                } label: {
                    Text(item.isActive == true ? "Active" : "Paused")
                        .font(.appCaptionBold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(item.isActive == true ? Color.appPrimaryLight : Color(.systemGray5))
                        .foregroundStyle(item.isActive == true ? Color.appPrimaryDark : Color.appTextSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let imageURL, !imageURL.isEmpty {
                ZStack(alignment: .topTrailing) {
                    ResilientAsyncImage(urlString: imageURL) {
                        RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous)
                            .fill(Color(.systemGray6))
                            .frame(width: 100, height: 100)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous))
                    .grayscale(item.isActive == true ? 0 : 0.8)

                    if item.streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.appCaptionBold)
                            Text("\(item.streak)d")
                                .font(.appCaptionBold)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(Color.appWarning)
                        .foregroundStyle(Color.appOnAccent)
                        .clipShape(Capsule())
                        .offset(x: 4, y: -6)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
        .shadow(color: Color.appText.opacity(0.04), radius: 10, y: 4)
        .opacity(item.isActive == true ? 1.0 : 0.6)
    }
}

struct ProtocolsView_Previews: PreviewProvider {
    struct PreviewAPI: AuthAPI {
        func register(email: String, password: String, name: String) async throws -> AccessToken { .init(userId: UUID().uuidString, accessToken: "t", refreshToken: "r", tokenType: "Bearer") }
        func login(email: String, password: String) async throws -> AccessToken { .init(userId: UUID().uuidString, accessToken: "t", refreshToken: "r", tokenType: "Bearer") }
        func refresh(request: RefreshTokenRequest) async throws -> TokenPair { .init(userId: UUID().uuidString, accessToken: "t", refreshToken: "r") }
        func logout(refreshToken: String) async throws {}
        func fetchProtocols(token: String, category: ActionCategory? = nil) async throws -> [ProtocolItem] {
            [
                ProtocolItem(
                    id: UUID().uuidString,
                    userId: UUID().uuidString,
                    name: "Morning Glow",
                    actions: [],
                    isActive: true,
                    startedAt: "2026-01-01",
                    endedAt: nil,
                    category: .skincare,
                    streak: 5
                ),
                ProtocolItem(
                    id: UUID().uuidString,
                    userId: UUID().uuidString,
                    name: "Circadian Ritual",
                    actions: [],
                    isActive: true,
                    startedAt: "2025-12-20",
                    endedAt: nil,
                    category: .supplement,
                    streak: 0
                )
            ]
        }
        func fetchActions(token: String, category: ActionCategory? = nil, modality: ActionModality? = nil, query: String? = nil, libraryOnly: Bool? = nil) async throws -> [Action] { [] }
        func createAction(token: String, payload: ActionCreate) async throws -> Action {
            Action(id: UUID().uuidString, name: payload.name, description: payload.description, category: payload.category, modality: payload.modality)
        }
        func updateAction(token: String, actionId: String, payload: ActionUpdate) async throws -> Action {
            Action(id: actionId, name: payload.name ?? "", category: payload.category ?? .custom)
        }
        func createProtocol(token: String, payload: ProtocolCreateRequest) async throws -> ProtocolItem {
            ProtocolItem(
                id: UUID().uuidString,
                userId: payload.userId,
                name: payload.name,
                actions: payload.actions.map { action in
                    ProtocolAction(
                        id: UUID().uuidString,
                        actionId: action.actionId,
                        rrule: action.rrule,
                        position: action.position,
                        checkins: nil
                    )
                },
                isActive: payload.isActive,
                startedAt: payload.startedAt,
                endedAt: payload.endedAt,
                category: payload.category,
                streak: 0
            )
        }
        func deleteProtocol(token: String, protocolId: String) async throws { }
        func createProtocolWithImage(token: String, payload: ProtocolCreateRequest, imageData: Data?) async throws -> ProtocolItem {
            ProtocolItem(
                id: UUID().uuidString,
                userId: payload.userId,
                name: payload.name,
                actions: payload.actions.map { action in
                    ProtocolAction(
                        id: UUID().uuidString,
                        actionId: action.actionId,
                        rrule: action.rrule,
                        position: action.position,
                        checkins: nil
                    )
                },
                isActive: payload.isActive,
                startedAt: payload.startedAt,
                endedAt: payload.endedAt,
                category: payload.category,
                streak: 0
            )
        }
        func updateProtocol(token: String, protocolId: String, payload: ProtocolUpdate) async throws -> ProtocolItem {
            ProtocolItem(id: protocolId, userId: UUID().uuidString, name: payload.name ?? "Updated", actions: [], isActive: payload.isActive, startedAt: payload.startedAt, endedAt: payload.endedAt, category: payload.category, streak: 0)
        }
        func createCheckin(token: String, payload: ProtocolCheckinCreate) async throws -> CheckIn {
            return CheckIn(protocolActionId: payload.protocolActionId, ts: payload.ts, quantity: payload.quantity, unit: payload.unit, durationSeconds: payload.durationSeconds, completed: payload.completed, id: UUID().uuidString, userId: nil)
        }
        func deleteCheckin(token: String, protocolId: String, checkinId: String) async throws {}
        func uploadProtocolImage(token: String, protocolId: String, imageData: Data) async throws -> ImageAttachmentCreate {
            ImageAttachmentCreate(id: UUID().uuidString, filename: "image.jpg", contentType: "image/jpeg", fileSize: imageData.count, width: 100, height: 100, url: "https://example.com/image.jpg")
        }
        func fetchProtocolImage(token: String, protocolId: String) async throws -> ImageAttachment {
            ImageAttachment(id: UUID().uuidString, ownerId: UUID().uuidString, attachableType: "protocol", attachableId: protocolId, filename: "image.jpg", contentType: "image/jpeg", fileSize: 1024, width: 100, height: 100, url: "https://example.com/image.jpg", createdAt: "2024-01-01T12:00:00Z")
        }
        func deleteImage(token: String, imageId: String) async throws { }

        func fetchDailyStatus(token: String, date: Date?) async throws -> DailyStatusResponse {
            DailyStatusResponse(date: "", streak: StreakInfo(currentStreak: 0, longestStreak: 0), dailyProgressPercentage: 0, totalActions: 0, completedActions: 0, protocols: [])
        }
        func fetchProtocolDailyStatus(token: String, protocolId: String, date: Date?) async throws -> ProtocolDailyStatus {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            let dateString = fmt.string(from: date ?? Date())

            return ProtocolDailyStatus(
                protocolId: protocolId,
                date: dateString,
                totalActions: 3,
                completedActions: 1,
                completionPercentage: 33,
                actions: [
                    ActionCheckinStatus(
                        protocolActionId: UUID().uuidString,
                        actionId: UUID().uuidString,
                        actionName: "Morning Cleanser",
                        position: 0,
                        scheduledTime: "08:00",
                        isCompleted: true,
                        completedAt: "2024-01-01T10:00:00Z",
                        checkinId: UUID().uuidString,
                        quantity: 2, unit: .ml, completed: true
                    ),
                    ActionCheckinStatus(
                        protocolActionId: UUID().uuidString,
                        actionId: UUID().uuidString,
                        actionName: "Toner",
                        position: 1,
                        scheduledTime: "08:05",
                        isCompleted: false,
                        completedAt: nil,
                        checkinId: nil,
                        quantity: nil,
                        unit: nil,
                        durationSeconds: nil,
                        completed: true
                    ),
                    ActionCheckinStatus(
                        protocolActionId: UUID().uuidString,
                        actionId: UUID().uuidString,
                        actionName: "Moisturizer",
                        position: 2,
                        scheduledTime: "08:10",
                        isCompleted: false,
                        completedAt: nil,
                        checkinId: nil,
                        quantity: nil,
                        unit: nil,
                        durationSeconds: nil,
                        completed: true
                    )
                ]
            )
        }
        func fetchProtocolWithCheckins(token: String, protocolId: String) async throws -> ProtocolWithCheckins {
            ProtocolWithCheckins(id: protocolId, userId: UUID().uuidString, name: "Preview", actions: [], isActive: true, startedAt: nil, endedAt: nil)
        }
        func fetchProtocolCheckins(token: String, protocolId: String, dateFrom: Date?, dateTo: Date?) async throws -> [CheckIn] { [] }
        func fetchJournalEntries(token: String, protocolId: String, dateFrom: String?, dateTo: String?) async throws -> [JournalEntry] { [] }
        func fetchJournalEntry(token: String, protocolId: String, date: String) async throws -> JournalEntryDetail {
            JournalEntryDetail(id: UUID().uuidString, protocolId: protocolId, date: date, dayNumber: 1, metrics: [:], availableMetrics: [], checkins: [], createdAt: "2024-01-01T12:00:00Z", updatedAt: "2024-01-01T12:00:00Z")
        }
        func saveJournalEntry(token: String, protocolId: String, date: String, metrics: [String: Int], notes: String?) async throws -> JournalEntry {
            JournalEntry(id: UUID().uuidString, protocolId: protocolId, date: date, dayNumber: 1, metrics: metrics, notes: notes)
        }
        func uploadJournalPhoto(token: String, protocolId: String, date: String, imageData: Data) async throws -> JournalEntry {
            JournalEntry(id: UUID().uuidString, protocolId: protocolId, date: date, dayNumber: 1, metrics: [:], photoUrl: "https://example.com/photo.jpg")
        }
        func fetchNotificationSchedules(token: String, protocolActionId: String?) async throws -> [NotificationScheduleResponse] { [] }
        func fetchNotificationSchedule(token: String, scheduleId: String) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: scheduleId, protocolActionId: UUID().uuidString, userId: UUID().uuidString, preferredTime: "08:00", timezone: "UTC", isEnabled: true, createdAt: "2024-01-01T12:00:00Z")
        }
        func createNotificationSchedule(token: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: UUID().uuidString, protocolActionId: payload.protocolActionId, userId: UUID().uuidString, preferredTime: payload.preferredTime, timezone: payload.timezone, isEnabled: payload.isEnabled ?? true, createdAt: "2024-01-01T12:00:00Z")
        }
        func updateNotificationSchedule(token: String, scheduleId: String, payload: NotificationScheduleUpdate) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: scheduleId, protocolActionId: UUID().uuidString, userId: UUID().uuidString, preferredTime: "08:00", timezone: "UTC", isEnabled: true, createdAt: "2024-01-01T12:00:00Z")
        }
        func deleteNotificationSchedule(token: String, scheduleId: String) async throws { }
        func upsertNotificationSchedule(token: String, actionId: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
            NotificationScheduleResponse(id: UUID().uuidString, protocolActionId: actionId, userId: UUID().uuidString, preferredTime: payload.preferredTime, timezone: payload.timezone, isEnabled: payload.isEnabled ?? true, createdAt: "2024-01-01T12:00:00Z")
        }

        func fetchCurrentUser(token: String) async throws -> UserMeResponse {
            UserMeResponse(id: UUID().uuidString, email: "preview@protocare.app", name: "Preview", avatarURL: nil, isActive: true, role: "user", timezone: nil, protocolsCount: 3, streak: StreakInfo(currentStreak: 7, longestStreak: 14), totalCheckins: 42)
        }
        func updateProfile(token: String, payload: ProfileUpdateRequest) async throws -> UserMeResponse {
            UserMeResponse(id: UUID().uuidString, email: "preview@protocare.app", name: "Preview", avatarURL: nil, isActive: true, role: "user", timezone: nil, protocolsCount: 3, streak: StreakInfo(currentStreak: 7, longestStreak: 14), totalCheckins: 42)
        }
        func uploadProfileImage(token: String, imageData: Data) async throws -> UserMeResponse {
            UserMeResponse(id: UUID().uuidString, email: "preview@protocare.app", name: "Preview", avatarURL: nil, isActive: true, role: "user", timezone: nil, protocolsCount: 3, streak: StreakInfo(currentStreak: 7, longestStreak: 14), totalCheckins: 42)
        }
        func deleteAccount(token: String) async throws {}
        func reorderProtocolActions(token: String, protocolId: String, actionIds: [String]) async throws {}
        func fetchProtocolNotificationSchedules(token: String, protocolId: String) async throws -> [String: NotificationScheduleResponse] { [:] }
        func addActionToProtocol(token: String, protocolId: String, payload: ProtocolActionCreate) async throws -> ProtocolItem {
            ProtocolItem(id: protocolId, userId: UUID().uuidString, name: "Preview", actions: [], isActive: true, startedAt: nil, endedAt: nil)
        }
        func removeActionFromProtocol(token: String, protocolId: String, protocolActionId: String) async throws {}
        func fetchMetricsTrend(token: String, protocolId: String, days: Int?) async throws -> MetricTrendResponse {
            MetricTrendResponse(protocolId: protocolId, days: 14, series: [])
        }
        func fetchOnboarding(token: String) async throws -> OnboardingState { OnboardingState() }
        func patchOnboarding(token: String, payload: OnboardingUpdateRequest) async throws -> OnboardingState { OnboardingState() }
        func resetOnboarding(token: String) async throws -> OnboardingState { OnboardingState() }
    }

    static var previews: some View {
        let api = PreviewAPI()
        let authStore: AuthStore = {
            let store = AuthStore()
            store.setAuth(tokens: AuthTokens(userId: UUID().uuidString, accessToken: "preview", refreshToken: "preview", tokenType: "Bearer"))
            return store
        }()

        return ProtocolsView(
            vm: ProtocolsViewModel(api: api, authStore: authStore),
            api: api,
            authStore: authStore
        )
    }
}
