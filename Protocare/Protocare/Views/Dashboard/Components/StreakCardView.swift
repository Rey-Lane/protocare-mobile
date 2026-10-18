import SwiftUI

struct StreakCardView: View {
    let streak: StreakInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.appCaption)
                    .foregroundStyle(streak.currentStreak > 0 ? Color.appWarning : Color.appTextSecondary)
                Text("STREAK")
                    .font(.appCaptionBold)
                    .foregroundStyle(Color.appTextSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(streak.currentStreak)")
                    .font(.appNumericDisplayLarge)
                Text(streak.currentStreak == 1 ? "day" : "days")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.appText.opacity(0.04), radius: 8, y: 4)
    }
}
