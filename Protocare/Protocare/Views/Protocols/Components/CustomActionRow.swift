import SwiftUI

struct CustomActionRow: View {
    let action: ActionItem
    let userAction: UserAction?
    let onAdd: () -> Void
    private let accent = Color.appPrimary

    private var iconColor: Color {
        Color(hex: userAction?.displayColor ?? "#34C759")
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15))
                Image(systemName: userAction?.displayIcon ?? action.categoryIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                if let desc = userAction?.description, !desc.isEmpty {
                    Text(desc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if !action.descriptionLabel.isEmpty {
                    Text(action.descriptionLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onAdd) {
                Text("+ Add")
                    .font(.system(size: 13, weight: .semibold))
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
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
    }
}
