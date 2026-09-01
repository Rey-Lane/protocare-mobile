import Foundation
import Combine

@MainActor
final class ProtocolsViewModel: ObservableObject {
    @Published private(set) var protocols: [ProtocolItem] = []
    @Published private(set) var actionsLookup: [String: ActionItem] = [:]
    @Published private(set) var protocolImageURLs: [String: String] = [:]
    @Published private(set) var deletingProtocolIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var deletionErrorMessage: String? = nil
    @Published var protocolPendingDeletion: ProtocolItem? = nil
    @Published var searchQuery: String = ""
    @Published var selectedCategory: ProtocolCategory?

    private let api: AuthAPI
    private let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    var filteredProtocols: [ProtocolItem] {
        var result = protocols
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        return result
    }

    var availableCategories: [ProtocolCategory] {
        let categories = Set(protocols.compactMap { $0.category })
        return ProtocolCategory.allCases.filter { categories.contains($0) }
    }

    func load() async {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            protocols = []
            protocolImageURLs = [:]
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedProtocols = api.fetchProtocols(token: token, category: nil)
            async let fetchedActions = api.fetchActions(token: token, query: nil)
            async let fetchedSubstances = api.fetchSubstances(token: token, query: nil)

            let (protocolsResponse, actionsResponse, substances) = try await (fetchedProtocols, fetchedActions, fetchedSubstances)
            protocols = protocolsResponse
            protocolImageURLs = await fetchProtocolImageURLs(for: protocolsResponse, token: authStore.accessToken ?? token)
            // Unified action model: GET /actions already returns library AND
            // user-created actions, so one lookup covers every protocol action.
            let enriched = actionsResponse.toActionItems(using: substances)
            actionsLookup = Dictionary(uniqueKeysWithValues: enriched.map { ($0.id, $0) }) as [String: ActionItem]
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load protocols."
        }
    }

    func requestDeletion(of item: ProtocolItem) {
        protocolPendingDeletion = item
    }

    func cancelDeletion() {
        protocolPendingDeletion = nil
    }

    func confirmDeletion() async {
        guard let item = protocolPendingDeletion else { return }
        protocolPendingDeletion = nil
        await deleteProtocol(item)
    }

    func deleteProtocol(_ item: ProtocolItem) async {
        guard let token = authStore.accessToken else {
            deletionErrorMessage = "User not authenticated."
            return
        }
        guard deletingProtocolIDs.contains(item.id) == false else { return }

        deletingProtocolIDs.insert(item.id)
        defer { deletingProtocolIDs.remove(item.id) }

        do {
            try await api.deleteProtocol(token: token, protocolId: item.id)
            protocols.removeAll { $0.id == item.id }
            protocolImageURLs[item.id] = nil
        } catch let apiError as APIError {
            deletionErrorMessage = userFriendlyDeletionMessage(for: apiError)
        } catch {
            deletionErrorMessage = "Failed to delete protocol. Please try again."
        }
    }

    private func userFriendlyDeletionMessage(for error: APIError) -> String {
        switch error {
        case .server(status: 409, _):
            return "This protocol has scheduled notifications and cannot be deleted right now."
        case .server(status: 404, _):
            return "This protocol no longer exists. It may have already been deleted."
        case .server(status: 401, _), .server(status: 403, _):
            return "You don't have permission to delete this protocol."
        case .server(let status, _) where (500...599).contains(status):
            return "A server error occurred. Please try again later."
        case .server(_, let message):
            return message ?? "An unexpected error occurred."
        case .transport:
            return "Unable to reach the server. Check your internet connection and try again."
        default:
            return "Failed to delete protocol. Please try again."
        }
    }

    private func fetchProtocolImageURLs(for items: [ProtocolItem], token: String) async -> [String: String] {
        let maxConcurrent = 6
        let semaphore = AsyncSemaphore(count: maxConcurrent)
        return await withTaskGroup(of: (String, String?).self) { group in
            for item in items {
                group.addTask {
                    await semaphore.wait()
                    defer { semaphore.signal() }
                    do {
                        let image = try await self.api.fetchProtocolImage(token: token, protocolId: item.id)
                        let url = image.url?.trimmingCharacters(in: .whitespacesAndNewlines)
                        return (item.id, url.flatMap { $0.isEmpty ? nil : $0 })
                    } catch APIError.server(let status, _) where status == 404 {
                        return (item.id, nil)
                    } catch {
                        return (item.id, nil)
                    }
                }
            }
            var results: [String: String] = [:]
            for await (id, url) in group {
                if let url { results[id] = url }
            }
            return results
        }
    }
}

/// A simple async-compatible counting semaphore for throttling concurrent work.
private final class AsyncSemaphore: @unchecked Sendable {
    private let lock = NSLock()
    private var permits: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(count: Int) {
        self.permits = count
    }

    func wait() async {
        lock.lock()
        if permits > 0 {
            permits -= 1
            lock.unlock()
            return
        }
        waiters.reserveCapacity(1)
        lock.unlock()
        await withCheckedContinuation { (cc: CheckedContinuation<Void, Never>) in
            lock.lock()
            // Double-check after re-acquiring lock (another signal may have arrived)
            if permits > 0 {
                permits -= 1
                lock.unlock()
                cc.resume()
                return
            }
            waiters.append(cc)
            lock.unlock()
        }
    }

    func signal() {
        lock.lock()
        if waiters.isEmpty {
            permits += 1
            lock.unlock()
        } else {
            let waiter = waiters.removeFirst()
            lock.unlock()
            waiter.resume()
        }
    }
}
