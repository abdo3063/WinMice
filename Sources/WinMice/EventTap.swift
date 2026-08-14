@preconcurrency import ApplicationServices
import Foundation

/// Owns the session event tap, including the recovery macOS never asks for and never announces.
///
/// Two properties of event taps drive the design here. They are synchronous: the window server
/// stops delivering input to everyone until the callback returns, so the handler has to be quick.
/// And they are fragile: macOS silently disables a tap on sleep, screen lock, fast user switching,
/// secure input fields, and any callback that overruns its deadline. A disabled tap is not just
/// inert, it degrades input for the whole session, so `verify()` polls the tap and rebuilds it.
@MainActor
final class EventTap {
    typealias Handler = (CGEventType, CGEvent) -> Unmanaged<CGEvent>?

    /// Called when the system disables the tap, so callers can drop any state that assumed a live
    /// event stream (a latched autoscroll waiting for a button release it will now never see).
    var onDisabled: (() -> Void)?

    private(set) var isInstalled = false

    private let eventsOfInterest: [CGEventType]
    private let handler: Handler
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(eventsOfInterest: [CGEventType], handler: @escaping Handler) {
        self.eventsOfInterest = eventsOfInterest
        self.handler = handler
    }

    /// Creates the tap if it is missing. A modifying tap needs Accessibility, so this is a no-op
    /// until the user grants it.
    @discardableResult
    func install() -> Bool {
        guard AXIsProcessTrusted() else {
            tearDown()
            return false
        }
        if isInstalled { return true }
        // Never stack a second tap on top of a half-built one: the old mach port and run loop
        // source would leak and both taps would see every event.
        tearDown()

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let tap = Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue()
            return MainActor.assumeIsolated {
                tap.dispatch(type: type, event: event)
            }
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.mask(for: eventsOfInterest),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        runLoopSource = source
        isInstalled = true
        return true
    }

    /// Installs the tap, re-enables it, or rebuilds it — whichever it currently needs. Cheap enough
    /// to call on a timer: everything it touches is a local check.
    func verify() {
        guard AXIsProcessTrusted() else {
            tearDown()
            return
        }
        guard isInstalled, let tap else {
            install()
            return
        }
        guard !CGEvent.tapIsEnabled(tap: tap) else { return }

        onDisabled?()
        CGEvent.tapEnable(tap: tap, enable: true)
        // A tap the system tore down rather than merely disabled will not come back this way, and
        // leaving it dead means the mouse stays broken until the next launch.
        if !CGEvent.tapIsEnabled(tap: tap) {
            rebuild()
        }
    }

    func rebuild() {
        tearDown()
        install()
    }

    func tearDown() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            self.tap = nil
        }
        isInstalled = false
    }

    private func dispatch(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            onDisabled?()
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return nil
        }
        return handler(type, event)
    }

    /// The two `tapDisabledBy…` types are deliberately absent: their raw values sit at the top of
    /// `UInt32`, so they cannot be expressed as a mask bit, and the system delivers them regardless.
    private static func mask(for types: [CGEventType]) -> CGEventMask {
        types.reduce(CGEventMask(0)) { partial, type in
            partial | (CGEventMask(1) << CGEventMask(type.rawValue))
        }
    }
}
