// Renders the iOrganize app icon (warm dark rounded square + golden folder
// with a sparkle sweep) at every size the .icns format needs.
// Run via: swift Packaging/make-icon.swift <output-dir>
import AppKit

let sizes: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16", 16, 1), ("icon_16x16@2x", 16, 2),
    ("icon_32x32", 32, 1), ("icon_32x32@2x", 32, 2),
    ("icon_128x128", 128, 1), ("icon_128x128@2x", 128, 2),
    ("icon_256x256", 256, 1), ("icon_256x256@2x", 256, 2),
    ("icon_512x512", 512, 1), ("icon_512x512@2x", 512, 2),
]

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func drawIcon(pixels: Int) -> NSImage {
    let size = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let inset = size * 0.09
    let squircle = NSBezierPath(
        roundedRect: NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2),
        xRadius: size * 0.2,
        yRadius: size * 0.2
    )

    // Warm dark background gradient (suite look)
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.18, green: 0.14, blue: 0.09, alpha: 1),
        ending: NSColor(calibratedRed: 0.07, green: 0.06, blue: 0.05, alpha: 1)
    )
    gradient?.draw(in: squircle, angle: -60)

    // Golden glow
    if let glow = NSGradient(
        starting: NSColor(calibratedRed: 0.91, green: 0.71, blue: 0.30, alpha: 0.28),
        ending: NSColor.clear
    ) {
        squircle.addClip()
        glow.draw(fromCenter: NSPoint(x: size * 0.30, y: size * 0.74), radius: 0,
                  toCenter: NSPoint(x: size * 0.30, y: size * 0.74), radius: size * 0.55,
                  options: [])
    }

    let gold = NSColor(calibratedRed: 0.91, green: 0.71, blue: 0.30, alpha: 1)
    let goldSoft = NSColor(calibratedRed: 0.96, green: 0.83, blue: 0.53, alpha: 1)

    // Folder body
    let fw = size * 0.52
    let fh = size * 0.34
    let fx = (size - fw) / 2
    let fy = size * 0.26
    let tabW = fw * 0.42
    let tabH = fh * 0.28

    let folder = NSBezierPath(
        roundedRect: NSRect(x: fx, y: fy, width: fw, height: fh),
        xRadius: size * 0.045, yRadius: size * 0.045
    )
    let tab = NSBezierPath(
        roundedRect: NSRect(x: fx, y: fy + fh - tabH * 0.4, width: tabW, height: tabH),
        xRadius: size * 0.03, yRadius: size * 0.03
    )
    gold.setFill()
    tab.fill()
    folder.fill()

    // Dark seam across the folder (organized "slot" look)
    let seam = NSBezierPath(
        roundedRect: NSRect(x: fx + fw * 0.14, y: fy + fh * 0.42, width: fw * 0.72, height: fh * 0.14),
        xRadius: fh * 0.07, yRadius: fh * 0.07
    )
    NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.06, alpha: 1).setFill()
    seam.fill()

    // Sparkle (4-point star) top-right — the "clean" moment
    func sparkle(center: NSPoint, radius: CGFloat, color: NSColor) {
        let path = NSBezierPath()
        let waist = radius * 0.22
        path.move(to: NSPoint(x: center.x, y: center.y + radius))
        path.curve(to: NSPoint(x: center.x + radius, y: center.y),
                   controlPoint1: NSPoint(x: center.x + waist, y: center.y + waist),
                   controlPoint2: NSPoint(x: center.x + waist, y: center.y + waist))
        path.curve(to: NSPoint(x: center.x, y: center.y - radius),
                   controlPoint1: NSPoint(x: center.x + waist, y: center.y - waist),
                   controlPoint2: NSPoint(x: center.x + waist, y: center.y - waist))
        path.curve(to: NSPoint(x: center.x - radius, y: center.y),
                   controlPoint1: NSPoint(x: center.x - waist, y: center.y - waist),
                   controlPoint2: NSPoint(x: center.x - waist, y: center.y - waist))
        path.curve(to: NSPoint(x: center.x, y: center.y + radius),
                   controlPoint1: NSPoint(x: center.x - waist, y: center.y + waist),
                   controlPoint2: NSPoint(x: center.x - waist, y: center.y + waist))
        path.close()
        color.setFill()
        path.fill()
    }
    sparkle(center: NSPoint(x: size * 0.72, y: size * 0.72), radius: size * 0.11, color: goldSoft)
    sparkle(center: NSPoint(x: size * 0.62, y: size * 0.80), radius: size * 0.045, color: goldSoft)

    image.unlockFocus()
    return image
}

for entry in sizes {
    let pixels = entry.points * entry.scale
    let image = drawIcon(pixels: pixels)
    guard let tiff = image.tiffRepresentation,
          let representation = NSBitmapImageRep(data: tiff) else { continue }
    representation.size = NSSize(width: entry.points, height: entry.points)
    guard let png = representation.representation(using: .png, properties: [:]) else { continue }
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent("\(entry.name).png")
    try? png.write(to: url)
}
print("Icon set written to \(outputDir)")
