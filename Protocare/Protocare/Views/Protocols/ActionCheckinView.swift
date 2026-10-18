import SwiftUI

/// Adaptive check-in screen (unified action model, Step 24).
///
/// The form is chosen from `effective = merge_params(action.default_parameters,
/// protocol_action.user_parameters)`:
/// - substance form (quantity stepper + unit) — `volume_amount`/`serving` present
/// - timed activity form (duration picker) — `duration_seconds` present
/// - binary toggle ("Did you do it?") — empty parameters
struct ActionCheckinView: View {
    let protocolId: String
    let protocolAction: ProtocolAction
    let action: ActionItem?
    @StateObject var vm: ActionCheckinViewModel
    var onSubmit: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var executionDate: Date = Date()
    @State private var quantity: Double = 0
    @State private var durationSeconds: Double = 60
    @State private var didDoIt: Bool = true

    /// Effective parameters driving the form kind and pre-fill.
    private var effectiveParameters: [String: AnyCodable] {
        CheckInFormResolver.effectiveParameters(
            actionDefault: action?.defaultParameters,
            userOverride: protocolAction.userParameters
        )
    }

    private var formKind: CheckInFormKind {
        CheckInFormResolver.formKind(for: effectiveParameters)
    }

    private let accent = Color.appPrimary

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                timeSection

                switch formKind {
                case .substance:
                    quantitySection
                case .timedActivity:
                    durationSection
                case .binary:
                    binarySection
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay(alignment: .bottom) {
            completeButton
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear(perform: prefill)
    }

    /// Pre-fill from `merge_params(default_parameters, user_parameters)`.
    private func prefill() {
        let params = effectiveParameters
        if let quantity = CheckInFormResolver.defaultQuantity(in: params) {
            self.quantity = quantity.amount
        }
        if let duration = CheckInFormResolver.defaultDurationSeconds(in: params) {
            durationSeconds = Double(duration)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            Text(action?.displayName ?? "Check-in")
                .font(.appSectionTitle)

            Spacer()

            Spacer(minLength: 44)
        }
    }

    // MARK: - Execution time (all forms)

    private var timeSection: some View {
        HStack {
            Label("Execution Time", systemImage: "clock.fill")
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            DatePicker("", selection: $executionDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    // MARK: - Substance form (quantity + unit)

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Amount")
                .font(.appBody.weight(.semibold))

            HStack {
                Button {
                    quantity = max(0, quantity - stepIncrement)
                } label: {
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

                Button {
                    quantity += stepIncrement
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.appSectionTitle)
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }

            if let hint = quantityHint {
                Text(hint)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private var unitLabel: String {
        CheckInFormResolver.defaultQuantity(in: effectiveParameters)?.unit.displayName ?? ""
    }

    /// Stepping granularity: whole units for sprays/capsules/tablets, halves for ml/mg/g.
    private var stepIncrement: Double {
        CheckInFormResolver.defaultQuantity(in: effectiveParameters)?.unit == .ml ? 0.5 : 1
    }

    private var quantityHint: String? {
        guard let prefill = CheckInFormResolver.defaultQuantity(in: effectiveParameters) else { return nil }
        return "Default: \(prefill.amount.roundedString(maxFractionDigits: 2)) \(prefill.unit.displayName)"
    }

    // MARK: - Timed activity form

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adjust Duration")
                .font(.appBody.weight(.semibold))
            Slider(value: $durationSeconds, in: 0...7200, step: 5)
                .tint(accent)
            HStack {
                Text("0s").font(.appCaption).foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(durationDisplay)
                    .font(.appNumericDisplay)
                Spacer()
                Text("120 min").font(.appCaption).foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private var durationDisplay: String {
        let seconds = Int(durationSeconds)
        if seconds >= 60 {
            let minutes = Double(seconds) / 60.0
            return "\(minutes.roundedString(maxFractionDigits: 1)) min"
        }
        return "\(seconds)s"
    }

    // MARK: - Binary form ("Did you do it?")

    private var binarySection: some View {
        VStack(spacing: 14) {
            Toggle(isOn: $didDoIt) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Did you do it?")
                        .font(.appBody.weight(.semibold))
                    Text("Just mark this action as done for today.")
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .tint(accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    // MARK: - Submit

    private var completeButton: some View {
        Button {
            let params = effectiveParameters
            let quantityValue: Double?
            let unitValue: SubstanceUnit?
            let durationValue: Int?
            switch formKind {
            case .substance:
                quantityValue = quantity
                unitValue = CheckInFormResolver.defaultQuantity(in: params)?.unit
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

            let payload = ProtocolCheckinCreate(
                protocolId: protocolId,
                protocolActionId: protocolAction.id,
                ts: ISO8601DateFormatter().string(from: executionDate),
                quantity: quantityValue,
                unit: unitValue,
                durationSeconds: durationValue,
                completed: formKind == .binary ? didDoIt : true
            )
            Task {
                let success = await vm.submit(payload: payload)
                if success {
                    onSubmit?()
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.appBody.weight(.bold))
                Text(completeButtonTitle)
                    .font(.appBody.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(accent)
            .foregroundStyle(Color.appOnAccent)
            .clipShape(Capsule())
            .shadow(color: accent.opacity(0.25), radius: 8, y: 3)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private var completeButtonTitle: String {
        switch formKind {
        case .substance, .timedActivity: return "Complete Step"
        case .binary: return didDoIt ? "Mark as Done" : "Skip"
        }
    }
}
