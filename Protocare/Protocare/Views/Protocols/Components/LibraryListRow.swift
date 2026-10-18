import SwiftUI

struct LibraryListRow: View {
    let action: ActionItem
    let onAdd: () -> Void
    private let accent = Color.appPrimary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12))
                Image(systemName: action.categoryIcon)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.displayName)
                    .font(.appCardTitle)
                    .foregroundStyle(Color.appText)

                if !action.descriptionLabel.isEmpty {
                    Text(action.descriptionLabel)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            Spacer()

            Button(action: onAdd) {
                Text("+ Add")
                    .font(.appCaptionBold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accent.opacity(0.12))
                    .foregroundStyle(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.1))
        )
        .shadow(color: Color.appText.opacity(0.04), radius: 8, y: 3)
    }
}
