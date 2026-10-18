import SwiftUI

// MARK: - Typography (D1)
// Semantic text styles keep Dynamic Type compatibility (D3);
// sizes below are the defaults at the standard content size.

extension Font {
    /// Root screen titles — 28 pt bold.
    static let appScreenTitle = Font.title.weight(.bold)
    /// Section headers — 20 pt semibold.
    static let appSectionTitle = Font.title3.weight(.semibold)
    /// Card and row titles — 17 pt semibold.
    static let appCardTitle = Font.headline
    /// Body text — 16 pt regular.
    static let appBody = Font.callout
    /// Captions and meta text — 13 pt regular.
    static let appCaption = Font.footnote
    /// Emphasized captions — 13 pt semibold.
    static let appCaptionBold = Font.footnote.weight(.semibold)
    /// Numeric data display (streak counters, check-in stats, onboarding numbers) — 22 pt rounded heavy (D2).
    static let appNumericDisplay = Font.system(.title2, design: .rounded, weight: .heavy)
    /// Hero numeric stats — 28 pt rounded heavy (D2).
    static let appNumericDisplayLarge = Font.system(.title, design: .rounded, weight: .heavy)
    /// Empty-state image font ONLY — 40 pt; never for text.
    static let appEmptyStateIcon = Font.system(size: 40)
    /// Large empty-state image font ONLY — 48 pt; never for text.
    static let appEmptyStateIconLarge = Font.system(size: 48)
}

// MARK: - Corner Radius (D4)

/// Caseless namespace for the corner-radius scale.
enum AppRadius {
    /// Chips and tags.
    static let chip: CGFloat = 8
    /// Text inputs and search fields.
    static let input: CGFloat = 12
    /// Cards and containers.
    static let card: CGFloat = 16
    /// Full-screen viewers and sheets.
    static let viewer: CGFloat = 24
}

// MARK: - Spacing (D5)

/// Caseless namespace for the 4 pt spacing grid and standard page padding.
enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    /// Standard horizontal page padding.
    static let pagePadding: CGFloat = 16
}
