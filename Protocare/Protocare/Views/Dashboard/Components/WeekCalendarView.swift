import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
    private let numberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    private var weekDates: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        var dates: [Date] = []
        var current = weekInterval.start
        while current < weekInterval.end {
            if let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: current) {
                dates.append(noon)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekDates, id: \.self) { day in
                let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(day)
                let isFuture = calendar.compare(day, to: Date(), toGranularity: .day) == .orderedDescending
                VStack(spacing: 4) {
                    Text(dayFormatter.string(from: day).uppercased())
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isSelected ? .white : isFuture ? Color.secondary.opacity(0.4) : .secondary)
                    Text(numberFormatter.string(from: day))
                        .font(.system(size: 16, weight: isSelected ? .bold : .regular, design: .rounded))
                        .foregroundStyle(isSelected ? .white : isFuture ? Color.primary.opacity(0.4) : .primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isSelected ? Color.appPrimary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isFuture else { return }
                    selectedDate = day
                }
            }
        }
    }
}
