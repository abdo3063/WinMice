import AppKit
import CoreGraphics
import SwipeGesturePoster
import XCTest

final class SwipeGesturePosterTests: XCTestCase {
    func testMakeEventsReturnsBeganAndEndedForBack() {
        let events = SwipeGesturePoster.makeEvents(for: .back)
        XCTAssertEqual(events.count, 2)

        let began = events[0]
        let ended = events[1]

        XCTAssertEqual(began.type.rawValue, SwipeGestureFields.eventTypeRaw)
        XCTAssertEqual(ended.type.rawValue, SwipeGestureFields.eventTypeRaw)

        XCTAssertEqual(
            began.getIntegerValueField(SwipeGestureFields.subtype),
            SwipeGestureFields.subtypeSwipe
        )
        XCTAssertEqual(
            began.getIntegerValueField(SwipeGestureFields.phase),
            SwipeGestureFields.phaseBegan
        )
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.phase),
            SwipeGestureFields.phaseEnded
        )
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.directionPrimary),
            SwipeGestureFields.directionLeft
        )
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.directionSecondary),
            SwipeGestureFields.directionLeft
        )
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.directionTertiary),
            SwipeGestureFields.directionLeft
        )
    }

    func testMakeEventsReturnsRightDirectionForForward() {
        let events = SwipeGesturePoster.makeEvents(for: .forward)
        XCTAssertEqual(events.count, 2)
        let ended = events[1]
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.directionPrimary),
            SwipeGestureFields.directionRight
        )
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.directionSecondary),
            SwipeGestureFields.directionRight
        )
        XCTAssertEqual(
            ended.getIntegerValueField(SwipeGestureFields.directionTertiary),
            SwipeGestureFields.directionRight
        )
    }

    func testMakeEventsDoesNotSpoofProcessIdentity() {
        // Dump-era values from the capture machine must never ship as a set.
        // UID 501 alone is a normal first-account id, so only reject the
        // dump PID and the exact dump triple.
        let dumpPID: Int64 = 4595
        let dumpUID: Int64 = 501
        let dumpGID: Int64 = 20
        let pidField = CGEventField(rawValue: 41)!
        let uidField = CGEventField(rawValue: 43)!
        let gidField = CGEventField(rawValue: 44)!

        for direction in [SwipeNavigationDirection.back, .forward] {
            let events = SwipeGesturePoster.makeEvents(for: direction)
            XCTAssertEqual(events.count, 2)
            for event in events {
                let pid = event.getIntegerValueField(pidField)
                let uid = event.getIntegerValueField(uidField)
                let gid = event.getIntegerValueField(gidField)
                XCTAssertNotEqual(pid, dumpPID)
                XCTAssertFalse(pid == dumpPID && uid == dumpUID && gid == dumpGID)
            }
        }
    }

    func testMakeEventsConvertToNSEventSwipe() throws {
        let back = SwipeGesturePoster.makeEvents(for: .back)
        XCTAssertEqual(back.count, 2)
        let backBegan = try XCTUnwrap(NSEvent(cgEvent: back[0]))
        let backEnded = try XCTUnwrap(NSEvent(cgEvent: back[1]))
        XCTAssertEqual(backBegan.type, .swipe)
        XCTAssertEqual(backEnded.type, .swipe)
        XCTAssertEqual(backBegan.phase, .began)
        XCTAssertEqual(backEnded.phase, .ended)
        XCTAssertGreaterThan(backEnded.deltaX, 0)

        let forward = SwipeGesturePoster.makeEvents(for: .forward)
        XCTAssertEqual(forward.count, 2)
        let forwardEnded = try XCTUnwrap(NSEvent(cgEvent: forward[1]))
        XCTAssertEqual(forwardEnded.type, .swipe)
        XCTAssertEqual(forwardEnded.phase, .ended)
        XCTAssertLessThan(forwardEnded.deltaX, 0)
    }

    func testPerformDoesNotTrap() {
        SwipeGesturePoster.perform(.back)
        SwipeGesturePoster.perform(.forward)
    }
}
