import SwiftUI

struct MetricSliderView: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.appCardTitle)
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Text("\(value)")
                    .font(.appCaptionBold)
                    .foregroundStyle(Color.appPrimary)
                    .monospacedDigit()
                    .frame(width: 28)
            }

            HStack(spacing: 8) {
                Text("0")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...10, step: 1) {
                    Text(title)
                }
                .tint(Color.appPrimary)

                Text("10")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
