import SwiftUI

struct LibraryCardView: View {
    let action: ActionItem
    let onAdd: () -> Void

    private var initial: String {
        action.displayName.prefix(1).uppercased()
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Color(.systemGray6))
                Text(initial).font(.appBody.weight(.bold))
            }
            .frame(width: 52, height: 52)

            Text(action.displayName)
                .font(.appCardTitle)
                .multilineTextAlignment(.center)

            Text(action.tagLabel)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            if !action.detailLabel.isEmpty {
                Text(action.detailLabel)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Button(action: onAdd) {
                Text("+ Add")
                    .font(.appCaptionBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

#Preview {
    LibraryCardView(
        action: ActionItem(name: "Magnesium Glycinate", scheduleLabel: "Daily", timeLabel: "22:00", modeLabel: "Oral")
    ) {}
    .padding()
    .frame(maxWidth: 240)
    .background(Color(.systemGroupedBackground))
}
