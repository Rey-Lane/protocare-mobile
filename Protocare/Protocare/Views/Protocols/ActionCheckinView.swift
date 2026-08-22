import SwiftUI

struct ActionCheckinView: View {
    let protocolId: String
    let protocolAction: ProtocolAction
    let action: ActionItem?
    @StateObject var vm: ActionCheckinViewModel
    var onSubmit: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var executionDate: Date = Date()
    @State private var appliedVolume: Double?
    @State private var appliedDuration: Double = 60


    private let accent = Color.appPrimary

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                timeSection

                HStack(spacing: 12) {
                    metricTile(title: "Amount", value: volumeDisplay, caption: unitDisplay)
                    metricTile(title: "Duration", value: durationDisplay.value, caption: durationDisplay.unit)
                }

                durationSlider
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
        .onAppear {
            if let vol = action?.volume?.amount {
                appliedVolume = vol
            }
            if let seconds = parseSeconds(from: protocolAction.rrule) {
                appliedDuration = Double(seconds)
            } else if let dur = action?.durationSeconds {
                appliedDuration = Double(dur)
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundStyle(.secondary)

            Spacer()

            Text(action?.displayName ?? "Check-in")
                .font(.system(size: 18, weight: .semibold))

            Spacer()

            Spacer(minLength: 44)
        }
    }

    private var timeSection: some View {
        HStack {
            Label("Execution Time", systemImage: "clock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            DatePicker("", selection: $executionDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private func metricTile(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private var durationSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adjust Duration")
                .font(.subheadline.weight(.semibold))
            Slider(value: $appliedDuration, in: 0...3600, step: 5)
                .tint(accent)
            HStack {
                Text("0s").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("60 min").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.08))
        )
    }

    private var completeButton: some View {
        Button {
            let payload = ProtocolCheckinCreate(
                protocolId: protocolId,
                protocolActionId: protocolAction.id,
                ts: ISO8601DateFormatter().string(from: executionDate),
                appliedVolume: appliedVolume.map { Quantity(amount: $0, unit: action?.volume?.unit ?? .ml) },
                appliedDurationSeconds: Int(appliedDuration)
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
                    .font(.system(size: 17, weight: .bold))
                Text("Complete Step")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(accent)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: accent.opacity(0.25), radius: 8, y: 3)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private var volumeDisplay: String {
        if let vol = appliedVolume {
            return vol.roundedString(maxFractionDigits: 2)
        }
        if let amount = action?.volume?.amount {
            return amount.roundedString(maxFractionDigits: 2)
        }
        return "—"
    }

    private var unitDisplay: String {
        if let unit = action?.volume?.unit {
            return unit.displayName
        }
        return ""
    }

    private var durationDisplay: (value: String, unit: String) {
        let seconds = Int(appliedDuration)
        if seconds >= 60 {
            let minutes = Double(seconds) / 60.0
            return (minutes.roundedString(maxFractionDigits: 1), "min")
        } else {
            return ("\(seconds)", "sec")
        }
    }

    private func parseSeconds(from rrule: String) -> Int? {
        // Basic parser for "duration_seconds=NNN" style inside rrule if present
        if let range = rrule.range(of: #"duration[_ ]?seconds=([0-9]+)"#, options: .regularExpression) {
            let valuePart = String(rrule[range]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(valuePart)
        }
        return nil
    }
}



//struct ActionCheckinView_Previews: PreviewProvider {
//    static var previews: some View {
//        ActionCheckinView(
//            protocolAction: ProtocolAction(id: UUID(), actionId: UUID(), rrule: "Daily at 08:04", position: 0, name: "Gentle Cleanser", description: nil, isCompleted: false),
//            action: ActionItem(name: "Gentle Cleanser", scheduleLabel: "Daily", timeLabel: "08:04", modeLabel: nil, volume: Quantity(amount: 2, unit: .ml), durationSeconds: 60)
//        )
//    }
//}
