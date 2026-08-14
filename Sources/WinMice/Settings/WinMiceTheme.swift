import SwiftUI

/// Graphite Mac tokens for the Settings window (light only).
enum WinMiceTheme {
    static let charcoal = Color(red: 26 / 255, green: 31 / 255, blue: 38 / 255) // #1A1F26
    /// Sidebar selection fill. Too light for `.tint` on buttons/pickers; use `controlAccent` there.
    static let accent = Color(red: 126 / 255, green: 184 / 255, blue: 255 / 255) // #7EB8FF
    /// Deeper blue for interactive controls (`.tint`), where `accent` reads too washed out.
    static let controlAccent = Color(red: 90 / 255, green: 140 / 255, blue: 210 / 255) // #5A8CD2
    static let aluminumLight = Color(red: 232 / 255, green: 236 / 255, blue: 241 / 255) // #E8ECF1
    static let aluminumMid = Color(red: 197 / 255, green: 206 / 255, blue: 217 / 255) // #C5CED9
    static let aluminumDeep = Color(red: 154 / 255, green: 168 / 255, blue: 184 / 255) // #9AA8B8
    static let sheetFill = Color.white.opacity(0.55)
    static let sheetBorder = charcoal.opacity(0.12)
    static let mutedText = charcoal.opacity(0.65)

    static let sheetCornerRadius: CGFloat = 12
    static let rowCornerRadius: CGFloat = 8
    static let sheetMargin: CGFloat = 10
    /// Clears the traffic lights (measured ~9–23pt from the content top under fullSizeContentView).
    static let sheetTopMargin: CGFloat = 28
}
