import SwiftUI

/// The sections of the settings window, in sidebar order.
enum SettingsPane: String, CaseIterable, Identifiable {
    case scrolling
    case buttons
    case general
    case permissions
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scrolling: "Scrolling"
        case .buttons: "Back & Forward"
        case .general: "General"
        case .permissions: "Permissions"
        case .about: "About"
        }
    }

    var subtitle: String {
        switch self {
        case .scrolling: "Middle-click autoscroll behavior and the on-screen indicator."
        case .buttons: "Turn the side buttons on your mouse into navigation."
        case .general: "Startup and menu bar options."
        case .permissions: "Accessibility access WinMice needs to read mouse buttons."
        case .about: "Version, credits, and support."
        }
    }

    var symbol: String {
        switch self {
        case .scrolling: "arrow.up.and.down"
        case .buttons: "arrow.left.arrow.right"
        case .general: "gearshape.fill"
        case .permissions: "lock.shield.fill"
        case .about: "info"
        }
    }

    var tint: Color {
        switch self {
        // Keep icon fills distinct from the selected-row `WinMiceTheme.accent` fill, and dark enough
        // for white SF Symbols (~3:1+ against white).
        case .scrolling: Color(red: 70 / 255, green: 120 / 255, blue: 190 / 255) // #4678BE
        case .buttons: WinMiceTheme.controlAccent // #5A8CD2
        case .general: Color(red: 90 / 255, green: 98 / 255, blue: 108 / 255) // #5A626C
        case .permissions: Color(red: 45 / 255, green: 140 / 255, blue: 130 / 255) // #2D8C82
        case .about: Color(red: 55 / 255, green: 75 / 255, blue: 95 / 255) // #374B5F
        }
    }
}
