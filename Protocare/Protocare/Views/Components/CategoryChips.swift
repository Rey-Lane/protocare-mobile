import SwiftUI

struct CategoryChips: View {
    @Binding var selectedCategory: ProtocolBuilderViewModel.ActionsCategory?
    let onSelect: (ProtocolBuilderViewModel.ActionsCategory?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProtocolBuilderViewModel.ActionsCategory.allCases) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedCategory == category && category == .all {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                            onSelect(selectedCategory)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryChips(selectedCategory: .constant(nil)) { _ in }
}
