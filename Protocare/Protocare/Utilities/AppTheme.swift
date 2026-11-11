import SwiftUI

extension Color {
    static let appPrimary = Color(red: 0.847, green: 0.643, blue: 0.565)
    static let appPrimaryDark = Color(red: 0.580, green: 0.380, blue: 0.302)
    static let appPrimaryLight = Color(red: 0.969, green: 0.945, blue: 0.945)
    static let appBackground = Color(red: 0.984, green: 0.984, blue: 0.976)
    static let appSurface = Color.white
    static let appText = Color(red: 0.102, green: 0.102, blue: 0.102)
    static let appTextSecondary = Color(red: 0.545, green: 0.494, blue: 0.455)
    static let appBorder = Color(red: 0.910, green: 0.878, blue: 0.855)
    static let appError = Color(red: 0.980, green: 0.337, blue: 0.333)
    static let appSuccess = Color(red: 0.420, green: 0.620, blue: 0.478)
    static let appWarning = Color(red: 0.961, green: 0.678, blue: 0.329)
    static let appOverlay = Color.appPrimary.opacity(0.2)

    /// Text/icons on appPrimary and other accent surfaces ONLY — never for regular text on light backgrounds.
    static let appOnAccent = Color.white

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let hex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        return hex
    }
}
