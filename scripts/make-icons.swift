import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "dist/WinMice.iconset"
let outputURL = URL(fileURLWithPath: output)
try? FileManager.default.removeItem(at: outputURL)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let specs: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for spec in specs {
    let image = drawIcon(size: spec.1)
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        fatalError("Could not render \(spec.0)")
    }
    try png.write(to: outputURL.appendingPathComponent(spec.0))
}

private func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let tileInset = size * 0.06
    let tileRect = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: tileInset, dy: tileInset)
    let corner = size * 0.22

    // Soft drop shadow under the tile.
    if size >= 64 {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = size * 0.045
        shadow.shadowOffset = NSSize(width: 0, height: -size * 0.02)
        shadow.set()
    }

    let tile = NSBezierPath(roundedRect: tileRect, xRadius: corner, yRadius: corner)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()

    let tileGradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.94, alpha: 1),
        NSColor(calibratedWhite: 0.82, alpha: 1)
    ])!
    tileGradient.draw(in: tileRect, angle: -90)

    // Glossy top highlight.
    let glossHeight = tileRect.height * 0.55
    let glossRect = NSRect(
        x: tileRect.minX,
        y: tileRect.maxY - glossHeight,
        width: tileRect.width,
        height: glossHeight
    )
    let gloss = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.55),
        NSColor.white.withAlphaComponent(0)
    ])!
    gloss.draw(in: glossRect, angle: -90)

    NSGraphicsContext.restoreGraphicsState()

    // Subtle rim.
    NSColor(calibratedWhite: 0.72, alpha: 0.9).setStroke()
    let rim = NSBezierPath(roundedRect: tileRect.insetBy(dx: 0.5, dy: 0.5), xRadius: corner, yRadius: corner)
    rim.lineWidth = max(1, size * 0.008)
    rim.stroke()

    // Inner white scroll circle.
    let circleInset = size * 0.22
    let circleRect = tileRect.insetBy(dx: circleInset - tileInset, dy: circleInset - tileInset)
    let circle = NSBezierPath(ovalIn: circleRect)

    NSColor.white.setFill()
    circle.fill()

    NSColor(calibratedWhite: 0.78, alpha: 1).setStroke()
    circle.lineWidth = max(1, size * 0.01)
    circle.stroke()

    let symbolColor = NSColor(calibratedWhite: 0.45, alpha: 1)
    symbolColor.setFill()

    let center = NSPoint(x: circleRect.midX, y: circleRect.midY)
    let triangleWidth = circleRect.width * 0.34
    let triangleHeight = circleRect.height * 0.18
    let gap = circleRect.height * 0.08
    let dotRadius = circleRect.width * 0.055

    // Up triangle.
    let upTip = NSPoint(x: center.x, y: center.y + gap + triangleHeight + dotRadius)
    drawTriangle(
        tip: upTip,
        baseY: upTip.y - triangleHeight,
        width: triangleWidth
    )

    // Center dot.
    NSBezierPath(ovalIn: NSRect(
        x: center.x - dotRadius,
        y: center.y - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    )).fill()

    // Down triangle.
    let downTip = NSPoint(x: center.x, y: center.y - gap - triangleHeight - dotRadius)
    drawTriangle(
        tip: downTip,
        baseY: downTip.y + triangleHeight,
        width: triangleWidth
    )

    image.unlockFocus()
    return image
}

private func drawTriangle(tip: NSPoint, baseY: CGFloat, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: tip)
    path.line(to: NSPoint(x: tip.x - width / 2, y: baseY))
    path.line(to: NSPoint(x: tip.x + width / 2, y: baseY))
    path.close()
    path.fill()
}
