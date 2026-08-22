import SwiftUI

struct CheckinDosageSheet: View {
    let action: DailyActionStatus
    let onConfirm: (QuantityOutput?, Int?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var volumeAmount: Double
    @State private var durationSeconds: Double

    private let accent = Color.appPrimary

    init(action: DailyActionStatus, onConfirm: @escaping (QuantityOutput?, Int?) -> Void) {
        self.action = action
        self.onConfirm = onConfirm
        _volumeAmount = State(initialValue: action.defaultVolume?.amount ?? action.appliedVolume?.amount ?? 0)
        _durationSeconds = State(initialValue: Double(action.defaultDurationSeconds ?? action.appliedDurationSeconds ?? 60))
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            if action.defaultVolume != nil || action.appliedVolume != nil {
                volumeSection
            }

            if action.defaultDurationSeconds != nil || action.appliedDurationSeconds != nil {
                durationSection
            }

            confirmButton
        }
        .padding(20)
        .presentationDetents([.medium])
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(action.actionName)
                .font(.system(size: 18, weight: .semibold))
            if let desc = action.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline.weight(.semibold))

            HStack {
                Button { volumeAmount = max(0, volumeAmount - 0.5) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(String(format: "%.1f", volumeAmount))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)

                Text(unitLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button { volumeAmount += 0.5 } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))

            Slider(value: $durationSeconds, in: 0...3600, step: 5)
                .tint(accent)

            HStack {
                Text("0s").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(durationLabel).font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Text("60 min").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var confirmButton: some View {
        Button {
            let volume = (action.defaultVolume ?? action.appliedVolume).map {
                QuantityOutput(amount: volumeAmount, unit: $0.unit)
            }
            let duration = (action.defaultDurationSeconds ?? action.appliedDurationSeconds).map { _ in Int(durationSeconds) }
            onConfirm(volume, duration)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Step")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accent)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }

    private var unitLabel: String {
        (action.defaultVolume ?? action.appliedVolume)?.unit.rawValue ?? ""
    }

    private var durationLabel: String {
        let secs = Int(durationSeconds)
        if secs >= 60 {
            return String(format: "%.1f min", Double(secs) / 60.0)
        }
        return "\(secs)s"
    }
}
