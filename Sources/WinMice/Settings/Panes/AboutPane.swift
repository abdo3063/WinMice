import AppKit
import SwiftUI

struct AboutPane: View {
    var body: some View {
        SettingsForm {
            Section {
                hero
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            Section {
                support
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            AppIconView()
                .frame(width: 48, height: 48)

            VStack(spacing: 2) {
                Text(AppInfo.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(AppInfo.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !AppInfo.versionDescription.isEmpty {
                    Text("Version \(AppInfo.versionDescription)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(AppInfo.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)
        }
    }

    private var support: some View {
        VStack(spacing: 6) {
            Button {
                NSWorkspace.shared.open(AppInfo.supportURL)
            } label: {
                Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            Text("WinMice is free. A coffee keeps it maintained.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
