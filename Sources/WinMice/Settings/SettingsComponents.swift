import AppKit
import SwiftUI

/// Shared layout constants for the settings window.
enum SettingsMetrics {
    static let sidebarWidth: CGFloat = 176
    /// Tiny inset inside the sheet; traffic-light clearance is handled by `sheetTopMargin`.
    static let titlebarInset: CGFloat = 4
    static let contentPadding: CGFloat = 14
}

/// The grouped form every pane is built from. Its own scroll backdrop is hidden so the pane header
/// and the settings below it sit on one continuous window background.
struct SettingsForm<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

/// Rounded, tinted glyph tile in the style of System Settings sidebar icons.
struct PaneIcon: View {
    let symbol: String
    let tint: Color
    var side: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
            .fill(tint.gradient)
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: side * 0.55, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

/// The app icon, with a placeholder for unbundled debug runs that have no icon.
struct AppIconView: View {
    var body: some View {
        if let icon = NSApp.applicationIconImage {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "computermouse.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

/// Compact granted / not-granted pill.
struct StatusBadge: View {
    let isOn: Bool
    let onText: String
    let offText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            Text(isOn ? onText : offText)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(isOn ? Color.green : Color.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((isOn ? Color.green : Color.orange).opacity(0.14), in: Capsule())
        .overlay {
            Capsule().strokeBorder((isOn ? Color.green : Color.orange).opacity(0.35))
        }
    }
}

/// Full-width attention strip, sized and inset to read as part of the window chrome rather than as
/// a card floating on top of the pane below it.
struct NoticeBanner: View {
    let symbol: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button(actionTitle, action: action)
                .controlSize(.small)
        }
        .padding(.horizontal, SettingsMetrics.contentPadding)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.14))
        .overlay(alignment: .bottom) { Divider().overlay(WinMiceTheme.sheetBorder) }
    }
}

/// Live preview of the autoscroll marker at its real pixel size over a mock document.
struct ScrollIndicatorPreview: View {
    let darkMode: Bool
    let size: Int

    private static let lineWidths: [CGFloat] = [160, 128, 176, 104]

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(Self.lineWidths.enumerated()), id: \.offset) { _, width in
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: width, height: 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            IndicatorRepresentable(darkMode: darkMode)
                .frame(width: CGFloat(size), height: CGFloat(size))
        }
        .frame(height: 72)
        .background(previewBackground, in: RoundedRectangle(cornerRadius: WinMiceTheme.rowCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WinMiceTheme.rowCornerRadius, style: .continuous)
                .strokeBorder(WinMiceTheme.sheetBorder)
        }
        .accessibilityLabel("Preview of the \(size) point \(darkMode ? "dark" : "light") indicator")
    }

    /// `textBackgroundColor` stays white under the window's forced aqua appearance, so the dark
    /// variant needs its own dark paper rather than relying on the system color.
    private var previewBackground: Color {
        darkMode ? Color.black.opacity(0.85) : Color(nsColor: .textBackgroundColor)
    }
}

private struct IndicatorRepresentable: NSViewRepresentable {
    let darkMode: Bool

    func makeNSView(context: Context) -> ScrollIndicatorView {
        let view = ScrollIndicatorView()
        view.isDarkMode = darkMode
        return view
    }

    func updateNSView(_ view: ScrollIndicatorView, context: Context) {
        view.isDarkMode = darkMode
        view.needsDisplay = true
    }
}
