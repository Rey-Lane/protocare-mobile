import SwiftUI

// NOTE(Step 22): previously bound to ProtocolBuilderViewModel.ActionsCategory,
// which was removed with the builder's dual action list. The builder no longer
// embeds category chips (ActionPickerView owns filtering now). Kept compiling
// via SubstanceType until Step 25b replaces it with the new ActionCategory +
// ActionModality chip design.
struct CategoryChips: View {
    @Binding var selectedCategory: SubstanceType?
    let onSelect: (SubstanceType?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = nil
                        }
                        onSelect(selectedCategory)
                    }
                )
                ForEach(SubstanceType.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
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
