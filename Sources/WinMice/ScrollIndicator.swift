import AppKit

/// Borderless panel that draws the autoscroll anchor indicator above every other window.
@MainActor
final class ScrollIndicatorWindow {
    private let window: NSPanel
    private let content = ScrollIndicatorView(frame: NSRect(x: 0, y: 0, width: 32, height: 32))
    private var anchor: CGPoint?

    init() {
        window = NSPanel(
            contentRect: content.bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        window.contentView = content
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    }

    func show(at point: CGPoint) {
        anchor = point
        move(to: point)
        window.orderFrontRegardless()
    }

    func hide() {
        anchor = nil
        window.orderOut(nil)
    }

    func configure(darkMode: Bool, size: CGFloat) {
        content.isDarkMode = darkMode
        content.frame = NSRect(x: 0, y: 0, width: size, height: size)
        window.setContentSize(content.frame.size)
        content.needsDisplay = true
        if let anchor {
            move(to: anchor)
        }
    }

    private func move(to point: CGPoint) {
        let offset = content.frame.width / 2
        window.setFrameOrigin(NSPoint(x: point.x - offset, y: point.y - offset))
    }
}

/// The classic four-arrow autoscroll marker, drawn to fill its bounds. Shared by the overlay panel
/// and the live preview in settings.
final class ScrollIndicatorView: NSView {
    var isDarkMode = false

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let side = min(bounds.width, bounds.height)
        let inset = max(1, side * 0.0625)
        let circle = bounds.insetBy(dx: inset, dy: inset)
        let mid = side / 2

        NSColor.black.withAlphaComponent(0.18).setFill()
        NSBezierPath(ovalIn: circle.offsetBy(dx: 0, dy: max(1, side * 0.03125))).fill()

        let fill = isDarkMode
            ? NSColor.black.withAlphaComponent(0.88)
            : NSColor(calibratedWhite: 0.94, alpha: 0.96)
        let stroke = isDarkMode
            ? NSColor.white.withAlphaComponent(0.72)
            : NSColor(calibratedWhite: 0.42, alpha: 0.9)
        let symbol = isDarkMode
            ? NSColor.white.withAlphaComponent(0.78)
            : NSColor(calibratedWhite: 0.24, alpha: 0.9)

        fill.setFill()
        NSBezierPath(ovalIn: circle).fill()

        stroke.setStroke()
        let ring = NSBezierPath(ovalIn: circle)
        ring.lineWidth = max(1, side * 0.03125)
        ring.stroke()

        symbol.setFill()
        let dot = side * 0.125
        NSBezierPath(ovalIn: NSRect(x: mid - dot / 2, y: mid - dot / 2, width: dot, height: dot)).fill()

        drawArrow(from: NSPoint(x: mid, y: side * 0.375), to: NSPoint(x: mid, y: side * 0.15625), color: symbol, side: side)
        drawArrow(from: NSPoint(x: mid, y: side * 0.625), to: NSPoint(x: mid, y: side * 0.84375), color: symbol, side: side)
        drawArrow(from: NSPoint(x: side * 0.375, y: mid), to: NSPoint(x: side * 0.15625, y: mid), color: symbol, side: side)
        drawArrow(from: NSPoint(x: side * 0.625, y: mid), to: NSPoint(x: side * 0.84375, y: mid), color: symbol, side: side)
    }

    private func drawArrow(from start: NSPoint, to end: NSPoint, color: NSColor, side: CGFloat) {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        path.lineWidth = max(1.5, side * 0.0625)
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = side * 0.11
        let spread: CGFloat = .pi / 6

        let head = NSBezierPath()
        head.move(to: end)
        head.line(to: NSPoint(
            x: end.x - cos(angle - spread) * headLength,
            y: end.y - sin(angle - spread) * headLength
        ))
        head.move(to: end)
        head.line(to: NSPoint(
            x: end.x - cos(angle + spread) * headLength,
            y: end.y - sin(angle + spread) * headLength
        ))
        head.lineWidth = max(1.5, side * 0.0625)
        head.lineCapStyle = .round
        head.stroke()
    }
}
