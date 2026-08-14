import Foundation

/// Static app metadata used by the menu bar and the settings window.
enum AppInfo {
    static let name = "WinMice"
    static let tagline = "Windows-style mouse for Mac"
    static let summary = """
        Vector scrolling on middle-click and system-wide back/forward side buttons, \
        in a single lightweight process.
        """

    static let supportURL = URL(string: "https://paypal.me/anibalccribeiro")
        ?? URL(fileURLWithPath: "/")

    /// Marketing version from the bundle, e.g. `1.0`. Empty when run unbundled.
    static var versionDescription: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// Path macOS privacy lists should show for this running copy. Empty when unbundled.
    static var bundlePath: String {
        Bundle.main.bundleURL.path
    }

    static var isRunningFromAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
