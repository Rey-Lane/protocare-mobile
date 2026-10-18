import SwiftUI

struct ScheduleActionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var frequency: ScheduleFrequency
    @State private var selectedDays: [ScheduleDay]
    @State private var slots: [ScheduleSlot]
    @State private var expandedSlotId: UUID?
    @State private var isFrequencyExpanded = false

    private let actionName: String
    private let onSave: (ActionSchedule, [ScheduleSlot]) -> Void

    private let primary = Color.appPrimary
    private static let maxSlots = 5

    init(
        action: ActionItem,
        onSave: @escaping (ActionSchedule, [ScheduleSlot]) -> Void
    ) {
        let schedule = action.schedule ?? ActionSchedule()
        _frequency = State(initialValue: schedule.frequency)
        _selectedDays = State(initialValue: schedule.days.isEmpty ? ScheduleDay.allCases : schedule.days)

        // Initialize slots from action, or create a default one from the schedule's time
        // Snap minutes to nearest 5-min increment for drum picker
        let existingSlots = action.slots
        if existingSlots.isEmpty {
            let snappedMinute = (schedule.minute / 5) * 5
            _slots = State(initialValue: [
                ScheduleSlot(hour: schedule.hour, minute: snappedMinute, isReminderOn: true, reminderOffsetMinutes: 0)
            ])
        } else {
            _slots = State(initialValue: existingSlots.map { slot in
                var s = slot
                s.minute = (slot.minute / 5) * 5
                return s
            })
        }

        self.actionName = action.displayName
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            sheetHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    repeatSection
                    if frequency == .weekly {
                        daysSection
                    }
                    slotsSection
                    summaryCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            saveButton
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
    }

    // MARK: - Drag Handle & Header

    private var dragHandle: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 48, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 16)
    }

    private var sheetHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Schedule Action")
                    .font(.appSectionTitle)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.appCaptionBold)
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(primary)
                Text(actionName)
                    .font(.appCardTitle)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Repeat Section

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Repeat")
            frequencyDropdown
        }
    }

    private var frequencyDropdown: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFrequencyExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(frequency.displayName)
                        .font(.appBody.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.appCaptionBold)
                        .foregroundStyle(Color.appTextSecondary)
                        .rotationEffect(.degrees(isFrequencyExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)

            if isFrequencyExpanded {
                VStack(spacing: 0) {
                    ForEach(ScheduleFrequency.allCases) { freq in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                frequency = freq
                                isFrequencyExpanded = false
                            }
                        } label: {
                            HStack {
                                Text(freq.displayName)
                                    .font(.appBody.weight(freq == frequency ? .bold : .regular))
                                    .foregroundStyle(freq == frequency ? primary : Color.appText)
                                Spacer()
                                if freq == frequency {
                                    Image(systemName: "checkmark")
                                        .font(.appCaptionBold)
                                        .foregroundStyle(primary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if freq != ScheduleFrequency.allCases.last {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Days Section

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("On Days")
            HStack(spacing: 6) {
                ForEach(ScheduleDay.allCases) { day in
                    dayButton(day)
                }
            }
        }
    }

    private func dayButton(_ day: ScheduleDay) -> some View {
        let selected = selectedDays.contains(day)
        return Button {
            toggleDay(day)
        } label: {
            Text(day.singleLetter)
                .font(.appBody.weight(selected ? .bold : .medium))
                .foregroundStyle(selected ? Color.appOnAccent : Color.appTextSecondary)
                .frame(width: 40, height: 40)
                .background {
                    if selected {
                        Circle().fill(primary)
                    } else {
                        Circle()
                            .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Slots Section

    private var slotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Times (\(slots.count))")

            ForEach(slots) { slot in
                slotCard(slot)
            }

            if slots.count < Self.maxSlots {
                addSlotButton
            }
        }
    }

    private func slotCard(_ slot: ScheduleSlot) -> some View {
        let isExpanded = expandedSlotId == slot.id

        return VStack(spacing: 0) {
            // Collapsed / header row
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSlotId = isExpanded ? nil : slot.id
                }
            } label: {
                HStack(spacing: 10) {
                    // Time display
                    Text(slot.timeLabel)
                        .font(.appNumericDisplay)
                        .foregroundStyle(Color.appText)

                    // Reminder status pill
                    if slot.isReminderOn {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.appCaptionBold)
                            Text(slot.offsetLabel)
                                .font(.appCaptionBold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(primary.opacity(0.12))
                        .foregroundStyle(primary)
                        .clipShape(Capsule())
                    } else {
                        Text("No reminder")
                            .font(.appCaption.weight(.medium))
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    // Expand chevron
                    Image(systemName: "chevron.down")
                        .font(.appCaptionBold)
                        .foregroundStyle(Color.appTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))

                    // Delete button (only if >1 slot)
                    if slots.count > 1 {
                        Button {
                            removeSlot(slot)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.appBody)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 14) {
                    // Time drum picker (single UIPickerView with 2 components)
                    TimeDrumPicker(
                        hour: Binding(
                            get: { slot.hour },
                            set: { updateSlot(slot, hour: $0) }
                        ),
                        minute: Binding(
                            get: { slot.minute },
                            set: { updateSlot(slot, minute: $0) }
                        )
                    )
                    .frame(height: 200)

                    Divider()

                    // Reminder toggle
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.appBody)
                            .foregroundStyle(slot.isReminderOn ? primary : Color.appTextSecondary)
                        Text("Remind me")
                            .font(.appBody.weight(.medium))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { slot.isReminderOn },
                            set: { updateSlot(slot, isReminderOn: $0) }
                        ))
                        .tint(primary)
                        .labelsHidden()
                    }

                    // Offset picker (only if reminder is on)
                    if slot.isReminderOn {
                        offsetPicker(slot: slot)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private func offsetPicker(slot: ScheduleSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REMIND ME AT")
                .font(.appCaptionBold)
                .foregroundStyle(Color.appTextSecondary)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(ScheduleSlot.allowedOffsets, id: \.self) { offset in
                    let isSelected = slot.reminderOffsetMinutes == offset
                    Button {
                        updateSlot(slot, reminderOffsetMinutes: offset)
                    } label: {
                        Text(offsetLabel(for: offset))
                            .font(.appCaption.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.appOnAccent : Color.appTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                if isSelected {
                                    Capsule().fill(primary)
                                } else {
                                    Capsule()
                                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func offsetLabel(for minutes: Int) -> String {
        switch minutes {
        case 0: return "At time"
        case 5: return "5 min"
        case 15: return "15 min"
        case 30: return "30 min"
        default: return "\(minutes) min"
        }
    }

    private var addSlotButton: some View {
        Button {
            addSlot()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.appBody)
                Text("Add another time")
                    .font(.appBody.weight(.semibold))
            }
            .foregroundStyle(primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.appBody.weight(.semibold))
                .foregroundStyle(primary)
            Text(summaryAttributedString)
                .font(.appBody.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(primary.opacity(0.15), lineWidth: 1)
        )
    }

    private var summaryAttributedString: AttributedString {
        let schedule = buildSchedule()
        let daysText = schedule.summaryLabel
        let timeTexts = slots.map { $0.timeLabel }
        let timeText = timeTexts.joined(separator: ", ")
        var result = AttributedString("Repeats \(daysText) at \(timeText).")
        if let daysRange = result.range(of: daysText) {
            result[daysRange].font = .appBody.weight(.bold)
            result[daysRange].foregroundColor = .primary
        }
        if let timeRange = result.range(of: timeText) {
            result[timeRange].font = .appBody.weight(.bold)
            result[timeRange].foregroundColor = .primary
        }
        return result
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            let schedule = buildSchedule()
            onSave(schedule, slots)
            dismiss()
        } label: {
            Text("Save Schedule")
                .font(.appBody.weight(.heavy))
                .foregroundStyle(Color.appOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(primary)
                .clipShape(Capsule())
                .shadow(color: primary.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.appCaptionBold)
            .foregroundStyle(Color.appTextSecondary)
            .tracking(1.5)
            .padding(.leading, 4)
    }

    private func toggleDay(_ day: ScheduleDay) {
        if selectedDays.contains(day) {
            if selectedDays.count > 1 {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedDays.removeAll { $0 == day }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDays.append(day)
                selectedDays.sort { $0.calendarIndex < $1.calendarIndex }
            }
        }
    }

    private func buildSchedule() -> ActionSchedule {
        // Use the first slot's time for the rrule's BYHOUR/BYMINUTE
        let firstSlot = slots.first
        return ActionSchedule(
            frequency: frequency,
            days: selectedDays,
            hour: firstSlot?.hour ?? 8,
            minute: firstSlot?.minute ?? 0
        )
    }

    private func addSlot() {
        guard slots.count < Self.maxSlots else { return }
        let newSlot = ScheduleSlot(hour: 12, minute: 0, isReminderOn: true, reminderOffsetMinutes: 0)
        withAnimation(.easeInOut(duration: 0.2)) {
            slots.append(newSlot)
            expandedSlotId = newSlot.id
        }
    }

    private func removeSlot(_ slot: ScheduleSlot) {
        withAnimation(.easeInOut(duration: 0.2)) {
            slots.removeAll { $0.id == slot.id }
            if expandedSlotId == slot.id {
                expandedSlotId = nil
            }
        }
    }

    private func updateSlot(_ slot: ScheduleSlot, hour: Int? = nil, minute: Int? = nil, isReminderOn: Bool? = nil, reminderOffsetMinutes: Int? = nil) {
        guard let index = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        if let hour { slots[index].hour = hour }
        if let minute { slots[index].minute = minute }
        if let isReminderOn { slots[index].isReminderOn = isReminderOn }
        if let reminderOffsetMinutes { slots[index].reminderOffsetMinutes = reminderOffsetMinutes }
    }
}

private extension ScheduleDay {
    var singleLetter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}
