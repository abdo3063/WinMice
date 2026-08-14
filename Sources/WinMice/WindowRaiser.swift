import AppKit
import ApplicationServices

/// Brings the window under the pointer forward when autoscroll starts.
///
/// Every call in here is synchronous inter-process messaging, and a busy or beach-balling app can
/// take seconds to answer. Event taps run their callback on the main thread while the window server
/// holds up input delivery, so doing this work inline with a mouse event stalls every click and
/// keystroke on the machine — and eventually gets the tap disabled for running long. It runs on its
/// own queue instead, with an explicit messaging timeout as a second line of defence.
enum WindowRaiser {
    private static let queue = DispatchQueue(label: "app.winmice.window-raiser", qos: .userInitiated)
    private static let messagingTimeout: Float = 0.25
    /// Depth to climb looking for something that answers `AXRaise`, since the element under the
    /// pointer is usually a control several levels below its window.
    private static let maxAncestorHops = 10

    /// - Parameter point: Pointer location in Core Graphics screen coordinates (origin top left).
    static func raiseWindow(at point: CGPoint) {
        queue.async {
            guard AXIsProcessTrusted(), let element = element(at: point) else { return }

            var pid = pid_t()
            if AXUIElementGetPid(element, &pid) == .success {
                DispatchQueue.main.async {
                    NSRunningApplication(processIdentifier: pid)?.activate()
                }
            }
            raise(element)
        }
    }

    private static func element(at point: CGPoint) -> AXUIElement? {
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, messagingTimeout)

        var element: AXUIElement?
        guard AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &element) == .success else {
            return nil
        }
        return element
    }

    private static func raise(_ element: AXUIElement) {
        var current = element
        for _ in 0..<maxAncestorHops {
            AXUIElementSetMessagingTimeout(current, messagingTimeout)
            if AXUIElementPerformAction(current, "AXRaise" as CFString) == .success { return }
            guard let next = parent(of: current) else { return }
            current = next
        }
    }

    private static func parent(of element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, "AXParent" as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }
}
