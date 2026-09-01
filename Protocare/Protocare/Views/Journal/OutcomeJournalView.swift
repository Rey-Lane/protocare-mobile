import SwiftUI
import PhotosUI
import Charts

struct OutcomeJournalView: View {
    @ObservedObject var vm: OutcomeJournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @AppStorage("journal_trend_expanded") private var isTrendExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VisualProgressSection(vm: vm, showImagePicker: $showImagePicker, selectedPhotoItem: $selectedPhotoItem)

                TodayActionsSection(vm: vm)

                if !vm.availableMetrics.isEmpty {
                    DailyMetricsSection(vm: vm)
                }

                MetricTrendSection(vm: vm, isExpanded: $isTrendExpanded)

                NotesSection(notes: $vm.notes)

                LogHistorySection(dayNumber: vm.dayNumber)
            }
            .padding()
        }
        .navigationTitle(vm.protocol.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if vm.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            await vm.save()
                            if vm.saveSucceeded {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .task {
            await vm.load()
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}

private struct ViewerUrl: Identifiable {
    let url: String
    var id: String { url }
}

private struct VisualProgressSection: View {
    @ObservedObject var vm: OutcomeJournalViewModel
    @Binding var showImagePicker: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedViewerUrl: ViewerUrl?
    @State private var showComparisonSlider = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Progress")
                .font(.headline)

            if vm.entry?.photoUrl != nil || vm.selectedImage != nil {
                photoRow
            }

            Button {
                showImagePicker = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(vm.entry?.photoUrl == nil ? "Add progress photo" : "Update photo")
                }
                .font(.subheadline)
                .foregroundStyle(Color.appPrimary)
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let newItem, let data = try? await newItem.loadTransferable(type: Data.self) {
                    vm.selectedImage = data
                    await vm.uploadPhoto()
                }
                selectedPhotoItem = nil
            }
        }
        .fullScreenCover(item: $selectedViewerUrl) { wrapper in
            AsyncImageViewer(
                imageUrl: wrapper.url,
                onCompare: openComparison,
                isPresented: Binding(
                    get: { selectedViewerUrl != nil },
                    set: { if !$0 { selectedViewerUrl = nil } }
                )
            )
        }
        .fullScreenCover(isPresented: $showComparisonSlider) {
            if let baselineUrl = vm.entry?.baselinePhotoUrl, let photoUrl = vm.entry?.photoUrl {
                ComparisonSliderView(
                    beforeImageUrl: baselineUrl,
                    afterImageUrl: photoUrl,
                    beforeLabel: "Day 1",
                    afterLabel: "Day \(vm.dayNumber)",
                    isPresented: $showComparisonSlider
                )
            }
        }
    }

    private var photoRow: some View {
        HStack(spacing: 12) {
            if let baselineUrl = vm.entry?.baselinePhotoUrl {
                ResilientAsyncImage(urlString: baselineUrl, contentMode: .fill) {
                    Rectangle().fill(Color(.systemGray5))
                }
                .frame(width: 140, height: 140)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    Text("Day 1")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 4))
                        .padding(4)
                }
                .onTapGesture { selectedViewerUrl = ViewerUrl(url: baselineUrl) }
            }

            if let photoUrl = vm.entry?.photoUrl {
                ResilientAsyncImage(urlString: photoUrl, contentMode: .fill) {
                    Rectangle().fill(Color(.systemGray5))
                }
                .frame(width: 140, height: 140)
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityLabel("Day \(vm.dayNumber) progress photo")
                .overlay(alignment: .bottom) {
                    Text("Day \(vm.dayNumber)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 4))
                        .padding(4)
                }
                .onTapGesture { selectedViewerUrl = ViewerUrl(url: photoUrl) }
            }
        }
    }

    private func openComparison() {
        selectedViewerUrl = nil
        showComparisonSlider = true
    }
}

private struct DailyMetricsSection: View {
    @ObservedObject var vm: OutcomeJournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Metrics")
                .font(.headline)

            ForEach(vm.availableMetrics) { metric in
                MetricSliderView(
                    icon: metric.icon,
                    title: metric.label,
                    subtitle: metric.description,
                    value: Binding(
                        get: { vm.metrics[metric.key.rawValue] ?? 5 },
                        set: { vm.setMetric(key: metric.key.rawValue, value: $0) }
                    )
                )
            }
        }
    }
}

// MARK: - Metric Trend Section

private struct MetricTrendSection: View {
    @ObservedObject var vm: OutcomeJournalViewModel
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if let series = vm.currentTrendSeries {
                trendChartContent(series: series)
            } else {
                Text("No trend data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.appPrimary)
                Text("Metric Trend")
                    .font(.headline)
            }
        }
    }

    @ViewBuilder
    private func trendChartContent(series: MetricTrendSeries) -> some View {
        VStack(spacing: 12) {
            // Metric picker
            Menu {
                ForEach(vm.metricTrend?.series ?? []) { s in
                    Button {
                        vm.selectedMetricKey = s.key
                    } label: {
                        HStack {
                            Image(systemName: s.icon)
                            Text(s.label)
                            if s.key == vm.selectedMetricKey {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: series.icon)
                    Text(series.label)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color.appPrimary)
            }

            // Chart
            if series.points.count >= 2 {
                chartView(series: series)
            } else {
                Text("Need at least 2 data points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            // Change indicator
            if let change = series.changeVsPrev {
                changeIndicator(change: change)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func chartView(series: MetricTrendSeries) -> some View {
        let chartData = series.points.compactMap { point -> ChartDataPoint? in
            guard let d = isoFormatter.date(from: point.date) else { return nil }
            return ChartDataPoint(date: d, value: point.value)
        }

        Chart {
            ForEach(chartData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.appPrimary)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.appPrimary.opacity(0.1))
            }

            if let last = chartData.last {
                PointMark(
                    x: .value("Date", last.date),
                    y: .value("Score", last.value)
                )
                .foregroundStyle(Color.appPrimary)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: 0...10)
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 2)) {
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: chartData.count > 10 ? 3 : 2)) { value in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
            }
        }
        .frame(height: 160)
    }

    @ViewBuilder
    private func changeIndicator(change: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.weight(.bold))
            Text(String(format: "%+.1f vs 7d ago", change))
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(change >= 0 ? .green : .red)
    }
}

private struct TodayActionsSection: View {
    @ObservedObject var vm: OutcomeJournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Actions")
                .font(.headline)

            if let checkins = vm.entry?.checkins, !checkins.isEmpty {
                ForEach(checkins) { checkin in
                    ActionCheckinCard(
                        checkin: checkin,
                        isExpanded: vm.expandedActionId == checkin.id,
                        onToggleExpand: { vm.toggleExpand(actionId: checkin.id) },
                        onComplete: { volume, duration in
                            Task {
                                await vm.completeCheckin(
                                    protocolActionId: checkin.protocolActionId,
                                    quantity: volume?.amount,
                                    unit: volume?.unit,
                                    durationSeconds: duration
                                )
                            }
                        }
                    )
                }
            } else {
                Text("No actions scheduled for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct NotesSection: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)

            TextField("Add notes...", text: $notes, axis: .vertical)
                .lineLimit(3...)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct LogHistorySection: View {
    let dayNumber: Int

    var body: some View {
        HStack {
            Text("Log History")
                .font(.headline)
            Spacer()
            Text("Day \(dayNumber)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appPrimary)
        }
    }
}

// MARK: - Chart Data Helpers

private struct ChartDataPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

private let isoFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()
