import SwiftUI

/// Unified filter chips (Step 25b of the unified action model migration).
///
/// Two axes, matching the ActionPickerView filter design from Step 21:
///  - primary: "All" + 10 `ActionCategory` cases (with tagColor + tagIcon)
///  - secondary: "All" + 5 `ActionModality` cases
///
/// Replaces the old modality-only chips ("All/Topical/Oral/Device/Hygiene").
struct CategoryChips: View {
    @Binding var selectedCategory: ActionCategory?
    @Binding var selectedModality: ActionModality?
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = nil
                            }
                            onSelect()
                        }
                    )
                    ForEach(ActionCategory.allCases) { category in
                        CategoryChip(
                            title: category.displayName,
                            icon: category.tagIcon,
                            color: category.tagColor,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                                onSelect()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        title: "All",
                        isSelected: selectedModality == nil,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedModality = nil
                            }
                            onSelect()
                        }
                    )
                    ForEach(ActionModality.allCases, id: \.self) { modality in
                        CategoryChip(
                            title: modality.displayName,
                            isSelected: selectedModality == modality,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedModality = modality
                                }
                                onSelect()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = .appPrimary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.appCaptionBold)
                }
                Text(title)
                    .font(isSelected ? .appCaptionBold : .appCaption)
            }
            .foregroundStyle(isSelected ? Color.appOnAccent : Color.appTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray5))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryChips(
        selectedCategory: .constant(nil),
        selectedModality: .constant(nil),
        onSelect: {}
    )
}
