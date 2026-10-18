import SwiftUI

/// Journal check-in card (Step 25e, unified action model).
/// Adaptive mini form keyed off the same `merge_params(default, user)`
/// resolution the daily dashboard uses: amount slider for substance actions,
/// duration slider for timed activities, plain complete button for binary.
struct ActionCheckinCard: View {
    let checkin: JournalCheckinSummary
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onComplete: (QuantityOutput?, Int?) -> Void

    @State private var volumeAmount: Double
    @State private var durationSeconds: Double

    init(checkin: JournalCheckinSummary, isExpanded: Bool, onToggleExpand: @escaping () -> Void, onComplete: @escaping (QuantityOutput?, Int?) -> Void) {
        self.checkin = checkin
        self.isExpanded = isExpanded
        self.onToggleExpand = onToggleExpand
        self.onComplete = onComplete
        _volumeAmount = State(initialValue: checkin.defaultQuantity?.amount ?? 0)
        _durationSeconds = State(initialValue: Double(checkin.defaultDurationSeconds ?? 60))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            if isExpanded && !checkin.isCompleted {
                miniForm
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var headerRow: some View {
        Button {
            if !checkin.isCompleted {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onToggleExpand()
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: checkin.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(checkin.isCompleted ? Color.appPrimary : Color.appTextSecondary)
                    .accessibilityLabel(checkin.isCompleted ? "Completed" : "Not completed")

                Text(checkin.actionName)
                    .font(.subheadline)
                    .foregroundStyle(Color.appText)

                Spacer()

                if checkin.isCompleted {
                    if let summary = checkin.completedSummary {
                        Text(summary)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appSuccess)
                    } else {
                        Text("Done")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appSuccess)
                    }
                } else {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .disabled(checkin.isCompleted)
    }

    private var miniForm: some View {
        VStack(spacing: 14) {
            Divider()
                .padding(.horizontal, 14)

            if checkin.hasVolume {
                volumeSlider
            }

            if checkin.hasDuration {
                durationSlider
            }

            Button {
                let vol: QuantityOutput? = checkin.hasVolume
                    ? QuantityOutput(amount: volumeAmount, unit: checkin.defaultQuantity?.unit ?? .ml)
                    : nil
                let dur: Int? = checkin.hasDuration ? Int(durationSeconds) : nil
                onComplete(vol, dur)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Complete")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appPrimary)
                .foregroundStyle(Color.appOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }

    private var volumeSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Amount")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(volumeDisplay)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appText)
            }

            Slider(value: $volumeAmount, in: 0...checkin.volumeUpperBound, step: 0.5)
                .tint(Color.appPrimary)
        }
        .padding(.horizontal, 14)
    }

    private var durationSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Duration")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(durationDisplay)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appText)
            }

            Slider(value: $durationSeconds, in: 0...checkin.durationUpperBound, step: 5)
                .tint(Color.appPrimary)
        }
        .padding(.horizontal, 14)
    }

    private var volumeDisplay: String {
        let unit = checkin.defaultQuantity?.unit.displayName ?? "ml"
        let value = volumeAmount.roundedString(maxFractionDigits: 1)
        return "\(value) \(unit)"
    }

    private var durationDisplay: String {
        let seconds = Int(durationSeconds)
        if seconds >= 60 {
            let minutes = Double(seconds) / 60.0
            return "\(minutes.roundedString(maxFractionDigits: 1)) min"
        } else {
            return "\(seconds)s"
        }
    }
}
