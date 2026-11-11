import SwiftUI

/// Custom in-screen header for tab roots (D6).
///
/// Tab roots own their header on-screen instead of using a native nav-bar
/// title; pushed screens use `navigationTitle` as usual. Renders an optional
/// eyebrow caption above the title, and an optional supporting subtitle below.
///
/// - Note: This view applies **no page padding of its own** — callers position
///   it inside their own padded column (e.g. a ScrollView whose content has
///   `.padding(.horizontal, AppSpacing.pagePadding)`) or pad it at the call
///   site.
struct ScreenHeader: View {
    /// Small greeting-style caption rendered above the title.
    var eyebrow: String? = nil
    /// Large screen title.
    let title: String
    /// Supporting line rendered below the title.
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.bottom, AppSpacing.xs)
            }

            Text(title)
                .font(.appScreenTitle)
                .foregroundStyle(Color.appText)

            if let subtitle {
                Text(subtitle)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.top, AppSpacing.s)
            }
        }
    }
}
