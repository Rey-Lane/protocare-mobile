import SwiftUI

struct ActionRow: View {
    let action: ActionItem
    let onSettings: () -> Void
    let onRemove: () -> Void

    private var reminderCount: Int {
        action.slots.filter { $0.isReminderOn }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(action.displayName)
                        .font(.system(size: 16, weight: .semibold))

                    if reminderCount > 0 {
                        Text("🔔 \(reminderCount)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.12))
                            .foregroundStyle(Color.appPrimary)
                            .clipShape(Capsule())
                    }
                }

                if !action.scheduleSummaryText.isEmpty {
                    Text(action.scheduleSummaryText)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                } else {
                    HStack(spacing: 8) {
                        // Unified model (Step 25b): category + modality badges
                        // replace the library/custom split.
                        CapsuleTag(text: action.tagLabel, style: scheduleStyle)
                        if !action.detailLabel.isEmpty {
                            Text(action.detailLabel)
                                .font(.footnote)
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        CapsuleTag(text: action.category.displayName, style: .accent)
                        if let modality = action.modality {
                            CapsuleTag(text: modality.displayName, style: .primary)
                        }
                    }
                }
            }

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(Color.appTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.2))
        )
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var scheduleStyle: CapsuleTag.TagStyle {
        (action.tagLabel).contains(",") ? .accent : .primary
    }
}

struct CapsuleTag: View {
    enum TagStyle { case primary, accent }

    let text: String
    var style: TagStyle = .primary

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color(.systemGray6)
        case .accent: return Color.appWarning.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .secondary
        case .accent: return Color.appWarning
        }
    }
}

#Preview {
    VStack(spacing: 14) {
        ActionRow(
            action: ActionItem(
                name: "Vitamin C Serum",
                schedule: ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 8, minute: 0),
                slots: [ScheduleSlot(hour: 8, minute: 0, isReminderOn: true, reminderOffsetMinutes: 0)]
            ),
            onSettings: {},
            onRemove: {}
        )
        ActionRow(
            action: ActionItem(
                name: "Tretinoin",
                schedule: ActionSchedule(frequency: .weekly, days: [.monday, .wednesday, .friday], hour: 21, minute: 30)
            ),
            onSettings: {},
            onRemove: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
