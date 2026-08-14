import CoreGraphics

public enum SwipeNavigationDirection: Sendable {
    case back
    case forward
}

public enum SwipeGestureFields {
    public static let eventTypeRaw: UInt32 = 29

    public static let subtype = CGEventField(rawValue: 110)!
    public static let phase = CGEventField(rawValue: 132)!
    public static let directionPrimary = CGEventField(rawValue: 115)!
    public static let directionSecondary = CGEventField(rawValue: 117)!
    public static let directionTertiary = CGEventField(rawValue: 164)!

    public static let subtypeSwipe: Int64 = 16
    public static let phaseBegan: Int64 = 1
    public static let phaseEnded: Int64 = 4
    public static let directionLeft: Int64 = 4
    public static let directionRight: Int64 = 8
}

public enum SwipeGesturePoster {
    public static func makeEvents(for direction: SwipeNavigationDirection) -> [CGEvent] {
        let swipeDirection = direction == .back
            ? SwipeGestureFields.directionLeft
            : SwipeGestureFields.directionRight

        guard
            let began = makeGestureEvent(phase: SwipeGestureFields.phaseBegan, direction: nil),
            let ended = makeGestureEvent(phase: SwipeGestureFields.phaseEnded, direction: swipeDirection)
        else {
            return []
        }
        return [began, ended]
    }

    public static func perform(_ direction: SwipeNavigationDirection) {
        for event in makeEvents(for: direction) {
            event.post(tap: .cghidEventTap)
        }
    }

    private static func makeGestureEvent(phase: Int64, direction: Int64?) -> CGEvent? {
        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let event = CGEvent(source: source),
            let eventType = CGEventType(rawValue: SwipeGestureFields.eventTypeRaw)
        else {
            return nil
        }
        event.type = eventType

        // Semantic gesture fields only. Dump-era structural ints (including
        // process PID/UID/GID) are omitted — a minimal type/subtype/phase/direction
        // event still converts to NSEventTypeSwipe.
        event.setIntegerValueField(SwipeGestureFields.subtype, value: SwipeGestureFields.subtypeSwipe)
        event.setIntegerValueField(SwipeGestureFields.phase, value: phase)

        if let direction {
            event.setIntegerValueField(SwipeGestureFields.directionPrimary, value: direction)
            event.setIntegerValueField(SwipeGestureFields.directionSecondary, value: direction)
            event.setIntegerValueField(SwipeGestureFields.directionTertiary, value: direction)
        }
        return event
    }
}
