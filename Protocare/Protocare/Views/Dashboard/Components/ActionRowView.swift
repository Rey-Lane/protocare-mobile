import SwiftUI

struct ActionRowView: View {
    let action: DailyActionStatus
    let isReadOnly: Bool
    let onToggle: () -> Void
    let onCheckinWithDosage: (QuantityOutput?, Int?) -> Void

    @State private var showDosageSheet = false

    private let accent = Color.appPrimary

    private var hasDosageFields: Bool {
        action.defaultVolume != nil || action.appliedVolume != nil
            || action.defaultDurationSeconds != nil || action.appliedDurationSeconds != nil
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                guard !isReadOnly else { return }
                if action.isCompleted {
                    onToggle()
                } else if hasDosageFields {
                    showDosageSheet = true
                } else {
                    onToggle()
                }
            } label: {
                Image(systemName: action.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(action.isCompleted ? accent : Color(.systemGray4))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.actionName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(action.isCompleted ? .secondary : .primary)
                if let desc = action.description {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let time = action.scheduledTime {
                Text(formatTime(time))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .sheet(isPresented: $showDosageSheet) {
            CheckinDosageSheet(action: action) { volume, duration in
                onCheckinWithDosage(volume, duration)
            }
        }
    }

    private func formatTime(_ hhmm: String) -> String {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return hhmm }
        let period = h >= 12 ? "PM" : "AM"
        let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", hour12, m, period)
    }
}
