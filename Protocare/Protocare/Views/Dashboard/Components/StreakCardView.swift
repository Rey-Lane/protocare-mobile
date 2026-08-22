import SwiftUI

struct StreakCardView: View {
    let streak: StreakInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(streak.currentStreak > 0 ? Color.appWarning : .secondary)
                Text("STREAK")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(streak.currentStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(streak.currentStreak == 1 ? "day" : "days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
    }
}
