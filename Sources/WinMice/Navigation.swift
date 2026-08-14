import ApplicationServices
import SwipeGesturePoster

enum NavigationMethod: String, Hashable, CaseIterable, Identifiable, PreferenceRepresentable {
    case swipe
    case keyboard

    var id: Self { self }
}

enum NavigationDirection: Hashable, CaseIterable, Identifiable {
    case back
    case forward

    var id: Self { self }

    var opposite: NavigationDirection {
        switch self {
        case .back: .forward
        case .forward: .back
        }
    }

    var title: String {
        switch self {
        case .back: "Back"
        case .forward: "Forward"
        }
    }

    /// Button number this direction uses until the user maps another one. Buttons 0 through 2 are
    /// the left, right, and middle buttons, so the side buttons start at 3.
    var defaultButton: Int {
        switch self {
        case .back: 3
        case .forward: 4
        }
    }

    var swipeDirection: SwipeNavigationDirection {
        switch self {
        case .back: .back
        case .forward: .forward
        }
    }
}

/// Back/forward navigation via clean-room swipe posting or keyboard shortcuts.
@MainActor
final class NavigationController {
    var enabled = true
    var method: NavigationMethod = .swipe
    var triggerOnMouseDown = true
    var buttons: [NavigationDirection: Int64] = NavigationDirection.allCases
        .reduce(into: [:]) { buttons, direction in
            buttons[direction] = Int64(direction.defaultButton)
        }

    private let keyboardSource = CGEventSource(stateID: .hidSystemState)

    func direction(for buttonNumber: Int64) -> NavigationDirection? {
        buttons.first { $0.value == buttonNumber }?.key
    }

    func perform(_ direction: NavigationDirection) {
        switch method {
        case .swipe:
            SwipeGesturePoster.perform(direction.swipeDirection)
        case .keyboard:
            performKeyboard(direction)
        }
    }

    private func performKeyboard(_ direction: NavigationDirection) {
        let keyCode: CGKeyCode = direction == .back ? 0x21 : 0x1E
        // Command and nothing else: whatever the user happens to be holding would otherwise ride
        // along and turn this into a different shortcut.
        let flags: CGEventFlags = .maskCommand

        if let keyDown = CGEvent(keyboardEventSource: keyboardSource, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: keyboardSource, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: CGEventTapLocation.cghidEventTap)
        }
    }
}
