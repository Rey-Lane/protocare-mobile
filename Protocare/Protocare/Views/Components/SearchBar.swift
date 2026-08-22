import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    let placeholder: String
    let onTextChanged: () -> Void
    let onClear: () -> Void

    init(
        text: Binding<String>,
        placeholder: String = "Search actions\u{2026}",
        onTextChanged: @escaping () -> Void = {},
        onClear: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onTextChanged = onTextChanged
        self.onClear = onClear
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.appTextSecondary)
                .padding(.leading, 12)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.custom("Inter", size: 15).weight(.regular))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .onChange(of: text) { _, _ in
                    onTextChanged()
                }
                .submitLabel(.search)
                .onSubmit {
                    isFocused = false
                }
                .accessibilityLabel("Search actions")
                .accessibilityHint("Filters the list of predefined actions by name")

            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        text = ""
                    }
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.trailing, 12)
                .transition(.opacity)
            } else {
                Spacer()
                    .frame(width: 12)
            }
        }
        .frame(minHeight: 40, maxHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appPrimaryLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appPrimary.opacity(isFocused ? 1 : 0), lineWidth: 1.5)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        )
        .focused($isFocused)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBar(text: .constant(""))
        SearchBar(text: .constant("Magnesium"))
    }
    .padding()
}
