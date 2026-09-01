import Combine
import Foundation

@MainActor
final class OutcomeJournalViewModel: ObservableObject {
    @Published var entry: JournalEntryDetail?
    @Published var metrics: [String: Int] = [:]
    @Published var notes: String = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var selectedImage: Data?
    @Published var saveSucceeded = false
    @Published var expandedActionId: String?
    @Published var metricTrend: MetricTrendResponse?
    @Published var selectedMetricKey: String?

    let `protocol`: ProtocolItem

    private let api: AuthAPI
    private let authStore: AuthStore

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(protocol: ProtocolItem, api: AuthAPI, authStore: AuthStore) {
        self.protocol = `protocol`
        self.api = api
        self.authStore = authStore
        for keyStr in `protocol`.metricKeys ?? [] {
            metrics[keyStr] = 5
        }
    }

    var today: String {
        Self.dateFormatter.string(from: Date())
    }

    var dayNumber: Int {
        entry?.dayNumber ?? 0
    }

    var availableMetrics: [MetricDefinition] {
        entry?.availableMetrics ?? MetricKey.defaults(for: `protocol`.category ?? .custom).map { key in
            MetricDefinition(key: key)
        }
    }

    var currentTrendSeries: MetricTrendSeries? {
        let key = selectedMetricKey ?? availableMetrics.first?.key.rawValue
        return metricTrend?.series.first { $0.key == key }
    }

    func load() async {
        guard let token = authStore.accessToken else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            entry = try await api.fetchJournalEntry(token: token, protocolId: `protocol`.id, date: today)
            if let entry, !entry.metrics.isEmpty {
                metrics = entry.metrics
            }
            if let entryNotes = entry?.notes {
                notes = entryNotes
            }
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }

        // Load trend data in parallel (don't block the main load)
        if selectedMetricKey == nil, let first = availableMetrics.first {
            selectedMetricKey = first.key.rawValue
        }
        await loadTrend()
    }

    func loadTrend() async {
        guard let token = authStore.accessToken else { return }
        do {
            metricTrend = try await api.fetchMetricsTrend(token: token, protocolId: `protocol`.id, days: 14)
        } catch is CancellationError {
        } catch {
            // Silently fail — trend is non-critical
        }
    }

    func save() async {
        guard let token = authStore.accessToken else { return }
        saveSucceeded = false
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await api.saveJournalEntry(
                token: token,
                protocolId: `protocol`.id,
                date: today,
                metrics: metrics,
                notes: notes.isEmpty ? nil : notes
            )
            saveSucceeded = true
            errorMessage = nil
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeCheckin(
        protocolActionId: String,
        quantity: Double?,
        unit: SubstanceUnit?,
        durationSeconds: Int?
    ) async {
        guard let token = authStore.accessToken else { return }
        guard var checkins = entry?.checkins else { return }
        guard let index = checkins.firstIndex(where: { $0.protocolActionId == protocolActionId }) else { return }

        let checkin = checkins[index]
        if checkin.isCompleted { return }

        let now = ISO8601DateFormatter().string(from: Date())
        let payload = ProtocolCheckinCreate(
            protocolId: `protocol`.id,
            protocolActionId: protocolActionId,
            ts: now,
            quantity: quantity,
            unit: unit,
            durationSeconds: durationSeconds
        )

        do {
            _ = try await api.createCheckin(token: token, payload: payload)
            await load()
            expandedActionId = nil
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleExpand(actionId: String) {
        expandedActionId = expandedActionId == actionId ? nil : actionId
    }

    func uploadPhoto() async {
        guard let token = authStore.accessToken, let imageData = selectedImage else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await api.uploadJournalPhoto(
                token: token,
                protocolId: `protocol`.id,
                date: today,
                imageData: imageData
            )
            selectedImage = nil
            await load()
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setMetric(key: String, value: Int) {
        metrics[key] = value
    }
}
