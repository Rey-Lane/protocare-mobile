import SwiftUI

/// Quick check-in sheet on the Daily dashboard (Step 25c).
/// Adaptive form based on `merge_params(default_parameters, user_parameters)`:
/// substance → quantity stepper, timed activity → duration slider, binary → done button.
struct CheckinDosageSheet: View {
    let action: DailyActionStatus
    let onConfirm: (Double?, SubstanceUnit?, Int?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Double
    @State private var durationSeconds: Double

    private let accent = Color.appPrimary

    init(action: DailyActionStatus, onConfirm: @escaping (Double?, SubstanceUnit?, Int?) -> Void) {
        self.action = action
        self.onConfirm = onConfirm
        _quantity = State(initialValue: action.defaultQuantity?.amount ?? 0)
        _durationSeconds = State(initialValue: Double(action.defaultDurationSeconds ?? 60))
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            switch action.checkInFormKind {
            case .substance:
                quantitySection
            case .timedActivity:
                durationSection
            case .binary:
                Text("Mark this action as done for today.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
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
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.subheadline.weight(.semibold))

            HStack {
                Button { quantity = max(0, quantity - stepIncrement) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(quantity.roundedString(maxFractionDigits: 2))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)

                Text(unitLabel)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                Spacer()

                Button { quantity += stepIncrement } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }

            if let prefill = action.defaultQuantity {
                Text("Default: \(prefill.amount.roundedString(maxFractionDigits: 2)) \(prefill.unit.displayName)")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var unitLabel: String {
        action.defaultQuantity?.unit.displayName ?? ""
    }

    /// Whole units for sprays/capsules/tablets, halves for ml.
    private var stepIncrement: Double {
        action.defaultQuantity?.unit == .ml ? 0.5 : 1
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))

            Slider(value: $durationSeconds, in: 0...7200, step: 5)
                .tint(accent)

            HStack {
                Text("0s").font(.caption).foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(durationLabel).font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                Text("120 min").font(.caption).foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var confirmButton: some View {
        Button {
            let quantityValue: Double?
            let unitValue: SubstanceUnit?
            let durationValue: Int?
            switch action.checkInFormKind {
            case .substance:
                quantityValue = quantity
                unitValue = action.defaultQuantity?.unit
                durationValue = nil
            case .timedActivity:
                quantityValue = nil
                unitValue = nil
                durationValue = Int(durationSeconds) > 0 ? Int(durationSeconds) : nil
            case .binary:
                quantityValue = nil
                unitValue = nil
                durationValue = nil
            }
            onConfirm(quantityValue, unitValue, durationValue)
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
            .foregroundStyle(Color.appOnAccent)
            .clipShape(Capsule())
        }
    }

    private var durationLabel: String {
        let secs = Int(durationSeconds)
        if secs >= 60 {
            return String(format: "%.1f min", Double(secs) / 60.0)
        }
        return "\(secs)s"
    }
}
