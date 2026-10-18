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
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            confirmButton
        }
        .padding(AppSpacing.pagePadding)
        .presentationDetents([.medium])
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(action.actionName)
                .font(.appCardTitle)
            if let desc = action.description {
                Text(desc)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.appBody.weight(.semibold))

            HStack {
                Button { quantity = max(0, quantity - stepIncrement) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.appSectionTitle)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(quantity.roundedString(maxFractionDigits: 2))
                    .font(.appNumericDisplay)
                    .foregroundStyle(accent)

                Text(unitLabel)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)

                Spacer()

                Button { quantity += stepIncrement } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.appSectionTitle)
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }

            if let prefill = action.defaultQuantity {
                Text("Default: \(prefill.amount.roundedString(maxFractionDigits: 2)) \(prefill.unit.displayName)")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous))
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
                .font(.appBody.weight(.semibold))

            Slider(value: $durationSeconds, in: 0...7200, step: 5)
                .tint(accent)

            HStack {
                Text("0s").font(.appCaption).foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(durationLabel).font(.appNumericDisplay)
                Spacer()
                Text("120 min").font(.appCaption).foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.input, style: .continuous))
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
                    .font(.appBody.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
