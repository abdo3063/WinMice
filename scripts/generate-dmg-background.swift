import AppKit

guard let outputPath = CommandLine.arguments.dropFirst().first else {
    fputs("Usage: swift generate-dmg-background.swift <output.png>\n", stderr)
    exit(1)
}

// 2× bitmap for a 600×440 Finder window (Retina). Extra height vs the old
// 600×400 art leaves room for Finder’s title bar so the window does not
// grow a useless scrollbar when background and window share the same size.
let pointWidth = 600
let pointHeight = 440
let width = pointWidth * 2
let height = pointHeight * 2

// Light, neutral field — dark-on-dark captions were unreadable in Finder.
let bgTop = NSColor(srgbRed: 0xF2 / 255.0, green: 0xF2 / 255.0, blue: 0xF7 / 255.0, alpha: 1.0)
let bgBottom = NSColor(srgbRed: 0xE5 / 255.0, green: 0xE5 / 255.0, blue: 0xEA / 255.0, alpha: 1.0)
let arrowColor = NSColor(srgbRed: 0x6E / 255.0, green: 0x6E / 255.0, blue: 0x73 / 255.0, alpha: 1.0)

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
else {
    fatalError("Could not create bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("Missing graphics context")
}

let colors = [bgTop.cgColor, bgBottom.cgColor] as CFArray
guard let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: colors,
    locations: [0, 1]
) else {
    fatalError("Could not create gradient")
}
ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: CGFloat(height)),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// Finder icon centers at (150, 190) and (450, 190) in the 600×440 window.
let leftIconCenterX: CGFloat = 150 * 2
let rightIconCenterX: CGFloat = 450 * 2
let iconCenterY = CGFloat(height) - 190 * 2

let shaftStartX = leftIconCenterX + 120
let shaftEndX = rightIconCenterX - 120
let shaftY = iconCenterY

// Quiet drag cue only — no caption text (Finder already shows icon names).
arrowColor.setStroke()
arrowColor.setFill()

let shaft = NSBezierPath()
shaft.lineWidth = 5
shaft.lineCapStyle = .round
shaft.move(to: NSPoint(x: shaftStartX, y: shaftY))
shaft.line(to: NSPoint(x: shaftEndX - 16, y: shaftY))
shaft.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: shaftEndX - 24, y: shaftY + 16))
head.line(to: NSPoint(x: shaftEndX + 2, y: shaftY))
head.line(to: NSPoint(x: shaftEndX - 24, y: shaftY - 16))
head.close()
head.fill()

NSGraphicsContext.restoreGraphicsState()

// Tag as 144 DPI so Finder maps pixels → points (matches --window-size).
bitmap.size = NSSize(width: CGFloat(pointWidth), height: CGFloat(pointHeight))

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
