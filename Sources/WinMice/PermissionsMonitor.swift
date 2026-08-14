import AppKit
import ApplicationServices
import Combine

/// Observable view of the Accessibility grant WinMice needs for its modifying event tap.
///
/// macOS has no change notification for the grant, so the app polls `refresh()`. Republishing
/// only on an actual change keeps the settings window from redrawing on every poll.
@MainActor
final class PermissionsMonitor: ObservableObject {
    enum Permission: CaseIterable, Identifiable {
        case accessibility

        var id: Self { self }

        var title: String { "Accessibility" }

        var explanation: String {
            "Lets WinMice read mouse buttons, post scroll events, and raise the window under the pointer."
        }

        var systemSettingsURL: URL {
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
                ?? URL(fileURLWithPath: "/System/Applications/System Settings.app")
        }

        var isGranted: Bool { AXIsProcessTrusted() }
    }

    @Published private(set) var granted: Bool

    private static let systemSettingsAppURL = URL(
        fileURLWithPath: "/System/Applications/System Settings.app"
    )
    private static let systemSettingsBundleID = "com.apple.systempreferences"

    init() {
        granted = AXIsProcessTrusted()
    }

    var allGranted: Bool { granted }

    var missing: [Permission] {
        granted ? [] : [.accessibility]
    }

    func isGranted(_ permission: Permission) -> Bool {
        permission.isGranted
    }

    func refresh() {
        let current = AXIsProcessTrusted()
        guard current != granted else { return }
        granted = current
    }

    /// Opens the Accessibility list. The deep link only lands on the right pane once System
    /// Settings is running, so a cold launch opens the app first and follows up with the URL.
    func openSystemSettings(for permission: Permission = .accessibility) {
        let destination = permission.systemSettingsURL

        guard NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.systemSettingsBundleID)
            .isEmpty
        else {
            _ = NSWorkspace.shared.open(destination)
            Self.activateSystemSettings()
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(
            at: Self.systemSettingsAppURL,
            configuration: configuration
        ) { _, _ in
            DispatchQueue.main.async {
                _ = NSWorkspace.shared.open(destination)
                Self.activateSystemSettings()
            }
        }
    }

    func request(_ permission: Permission = .accessibility) {
        if AXIsProcessTrusted() {
            openSystemSettings(for: permission)
        } else {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        refresh()
    }

    func requestMissing(promptAccessibility: Bool = true) {
        guard promptAccessibility else {
            refresh()
            return
        }
        if !AXIsProcessTrusted() {
            request(.accessibility)
        }
        refresh()
    }

    private static func activateSystemSettings() {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: systemSettingsBundleID)
            .first?
            .activate()
    }
}
