import SwiftUI

struct ProgressCardView: View {
    let percentage: Int

    private let accent = Color.appPrimary

    private var motivationalText: String {
        if percentage == 100 { return "All done!" }
        if percentage >= 67 { return "Almost there!" }
        if percentage >= 34 { return "Keep it up!" }
        return "Keep going!"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "chart.pie.fill")
                    .font(.appCaption)
                    .foregroundStyle(accent)
                Text("PROGRESS")
                    .font(.appCaptionBold)
                    .foregroundStyle(Color.appTextSecondary)
            }
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage) / 100.0)
                        .rotation(Angle.degrees(-90))
                        .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    Text("\(percentage)")
                        .font(.appNumericDisplay)
                        .foregroundStyle(accent)
                    Text("%")
                        .font(.appCaptionBold)
                        .foregroundStyle(accent)
                        .offset(x: 14, y: -6)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "trending_up")
                        .font(.appCaption)
                        .foregroundStyle(accent)
                    Text(motivationalText)
                        .font(.appCaption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.appText.opacity(0.04), radius: 8, y: 4)
    }
}
