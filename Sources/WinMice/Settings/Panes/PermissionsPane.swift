import AppKit
import SwiftUI

struct PermissionsPane: View {
    @ObservedObject var permissions: PermissionsMonitor

    var body: some View {
        SettingsForm {
            Section {
                LabeledContent {
                    StatusBadge(
                        isOn: permissions.allGranted,
                        onText: "Ready",
                        offText: "Missing"
                    )
                } label: {
                    Text("Status")
                    Text(summary)
                }
            }

            Section("Accessibility") {
                let isGranted = permissions.granted

                LabeledContent {
                    StatusBadge(isOn: isGranted, onText: "Granted", offText: "Not granted")
                } label: {
                    Text("Accessibility")
                    Text(PermissionsMonitor.Permission.accessibility.explanation)
                }

                if isGranted {
                    LabeledContent {
                        Button("Open System Settings") {
                            permissions.openSystemSettings()
                        }
                    } label: {
                        Text("Change")
                        Text("Find WinMice in the list if you need to turn it off.")
                    }
                } else {
                    LabeledContent {
                        Button("Request Access") {
                            permissions.requestMissing()
                        }
                        .buttonStyle(.borderedProminent)
                    } label: {
                        Text("Grant")
                        Text("Shows the Accessibility prompt, or open Settings to flip the switch.")
                    }

                    LabeledContent {
                        Button("Open System Settings") {
                            permissions.openSystemSettings()
                        }
                    } label: {
                        Text("Or open Settings")
                        Text("Use this if no dialog appears.")
                    }
                }
            }

            if !permissions.allGranted, AppInfo.isRunningFromAppBundle {
                Section {
                    LabeledContent {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                        }
                    } label: {
                        Text("This copy")
                        Text(AppInfo.bundlePath)
                            .font(.caption.monospaced())
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                } footer: {
                    Text("Remove old WinMice rows under Accessibility, then Request Access for this copy. Quit and reopen after granting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !permissions.allGranted {
                Section {
                    Label(
                        "A new grant only takes effect after you quit and reopen WinMice.",
                        systemImage: "info.circle"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var summary: String {
        permissions.allGranted
            ? "WinMice has the Accessibility access it needs."
            : "Grant Accessibility below so WinMice can read the mouse."
    }
}
