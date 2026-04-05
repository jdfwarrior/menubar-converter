#!/usr/bin/env swift
// Generates AppIcon.icns for MBConverter — a film-strip → MP4 converter icon.
// Usage: swift scripts/create_icon.swift [output-dir]
//   output-dir defaults to the directory this script lives in.
import AppKit
import CoreText

// MARK: - Drawing

func drawIcon(in ctx: CGContext, size s: CGFloat) {
    // ── Background ──────────────────────────────────────────────────────────
    let corner = s * 0.225
    let fullRect = CGRect(x: 0, y: 0, width: s, height: s)
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: fullRect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.clip()

    let cs = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.07, green: 0.08, blue: 0.16, alpha: 1),  // bottom-left: dark navy
        CGColor(red: 0.14, green: 0.09, blue: 0.30, alpha: 1)   // top-right:  deep purple-blue
    ] as CFArray
    let bgLocs: [CGFloat] = [0, 1]
    let bgGrad = CGGradient(colorsSpace: cs, colors: bgColors, locations: bgLocs)!
    ctx.drawLinearGradient(bgGrad, start: .zero, end: CGPoint(x: s, y: s), options: [])
    ctx.restoreGState()

    // ── Film Strip (left) ────────────────────────────────────────────────────
    let sx = s * 0.08, sy = s * 0.20
    let sw = s * 0.34, sh = s * 0.60

    ctx.saveGState()

    // Strip fill + border
    let stripFill = CGColor(red: 0.18, green: 0.20, blue: 0.34, alpha: 1)
    let stripBorder = CGColor(red: 0.82, green: 0.85, blue: 0.95, alpha: 0.88)
    ctx.setFillColor(stripFill)
    ctx.setStrokeColor(stripBorder)
    ctx.setLineWidth(s * 0.018)
    let stripRect = CGRect(x: sx, y: sy, width: sw, height: sh)
    ctx.addRect(stripRect)
    ctx.drawPath(using: .fillStroke)

    // Horizontal dividers → three frames
    ctx.setStrokeColor(CGColor(red: 0.82, green: 0.85, blue: 0.95, alpha: 0.40))
    ctx.setLineWidth(s * 0.010)
    let fh = sh / 3
    for i: CGFloat in [1, 2] {
        ctx.move(to: CGPoint(x: sx, y: sy + fh * i))
        ctx.addLine(to: CGPoint(x: sx + sw, y: sy + fh * i))
    }
    ctx.strokePath()

    // Sprocket holes — 4 pairs
    let hs = s * 0.036
    let hm = s * 0.014
    let vSpacing = sh / 4.5
    ctx.setFillColor(CGColor(red: 0.07, green: 0.08, blue: 0.16, alpha: 1))
    for i in 0..<4 {
        let hy = sy + sh * 0.09 + CGFloat(i) * vSpacing
        ctx.fill(CGRect(x: sx + hm,            y: hy, width: hs, height: hs))
        ctx.fill(CGRect(x: sx + sw - hm - hs,  y: hy, width: hs, height: hs))
    }

    // Play triangle in the middle frame
    let pcx = sx + sw / 2
    let pcy = sy + fh * 1.5   // center of middle frame
    let pr  = fh * 0.26
    let play = CGMutablePath()
    play.move(to: CGPoint(x: pcx - pr * 0.55, y: pcy - pr))
    play.addLine(to: CGPoint(x: pcx + pr,      y: pcy))
    play.addLine(to: CGPoint(x: pcx - pr * 0.55, y: pcy + pr))
    play.closeSubpath()
    ctx.addPath(play)
    ctx.setFillColor(CGColor(red: 1.0, green: 0.68, blue: 0.18, alpha: 0.92))
    ctx.fillPath()

    ctx.restoreGState()

    // ── Conversion Arrow (center) ────────────────────────────────────────────
    let acx  = s * 0.585
    let acy  = s * 0.50
    let atw  = s * 0.15   // total width
    let ash  = s * 0.11   // shaft height
    let ahh  = s * 0.24   // arrowhead height
    let asw  = atw * 0.56 // shaft width

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: s * 0.035,
                  color: CGColor(red: 0.25, green: 0.75, blue: 1.0, alpha: 0.70))

    let arr = CGMutablePath()
    arr.move(to:    CGPoint(x: acx - atw/2,         y: acy + ash/2))
    arr.addLine(to: CGPoint(x: acx - atw/2 + asw,   y: acy + ash/2))
    arr.addLine(to: CGPoint(x: acx - atw/2 + asw,   y: acy + ahh/2))
    arr.addLine(to: CGPoint(x: acx + atw/2,          y: acy))
    arr.addLine(to: CGPoint(x: acx - atw/2 + asw,   y: acy - ahh/2))
    arr.addLine(to: CGPoint(x: acx - atw/2 + asw,   y: acy - ash/2))
    arr.addLine(to: CGPoint(x: acx - atw/2,         y: acy - ash/2))
    arr.closeSubpath()

    ctx.addPath(arr)
    ctx.setFillColor(CGColor(red: 0.22, green: 0.76, blue: 1.0, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // ── MP4 Badge (right) ────────────────────────────────────────────────────
    let bx = s * 0.685
    let by = s * 0.24
    let bw = s * 0.235
    let bh = s * 0.52

    ctx.saveGState()

    // Badge background
    let badgePath = CGPath(roundedRect: CGRect(x: bx, y: by, width: bw, height: bh),
                           cornerWidth: s * 0.04, cornerHeight: s * 0.04, transform: nil)
    ctx.addPath(badgePath)

    // Orange gradient on badge
    let badgeColors = [
        CGColor(red: 1.0, green: 0.62, blue: 0.08, alpha: 1),
        CGColor(red: 0.95, green: 0.42, blue: 0.04, alpha: 1)
    ] as CFArray
    let badgeLocs: [CGFloat] = [0, 1]
    let badgeGrad = CGGradient(colorsSpace: cs, colors: badgeColors, locations: badgeLocs)!
    ctx.clip()
    ctx.drawLinearGradient(badgeGrad,
                           start: CGPoint(x: bx, y: by + bh),
                           end:   CGPoint(x: bx, y: by),
                           options: [])
    ctx.resetClip()

    // "MP4" text
    let fontSize = s * 0.135
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let mp4Attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let attrStr = NSAttributedString(string: "MP4", attributes: mp4Attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let tb = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let tx = bx + (bw - tb.width) / 2 - tb.origin.x
    let ty = by + (bh - tb.height) / 2 - tb.origin.y
    ctx.textPosition = CGPoint(x: tx, y: ty)
    CTLineDraw(line, ctx)

    ctx.restoreGState()
}

// MARK: - Render to PNG data

func renderPNG(size: Int) -> Data? {
    let s = CGFloat(size)
    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    drawIcon(in: ctx, size: s)

    guard let cg = ctx.makeImage() else { return nil }
    let ns = NSImage(cgImage: cg, size: NSSize(width: s, height: s))
    guard let tiff = ns.tiffRepresentation,
          let bmp  = NSBitmapImageRep(data: tiff),
          let png  = bmp.representation(using: .png, properties: [:]) else { return nil }
    return png
}

// MARK: - Main

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
let outDir    = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : scriptDir
let iconsetDir = (outDir as NSString).appendingPathComponent("AppIcon.iconset")

let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

var ok = true
for (sz, name) in sizes {
    let dest = (iconsetDir as NSString).appendingPathComponent(name)
    if let data = renderPNG(size: sz) {
        do {
            try data.write(to: URL(fileURLWithPath: dest))
            print("  ✓  \(name)")
        } catch {
            print("  ✗  \(name): \(error)")
            ok = false
        }
    } else {
        print("  ✗  \(name): render failed")
        ok = false
    }
}

guard ok else {
    fputs("Icon generation failed.\n", stderr)
    exit(1)
}

let icnsPath = (outDir as NSString).appendingPathComponent("AppIcon.icns")
let result = Process()
result.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
result.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
try! result.run()
result.waitUntilExit()

if result.terminationStatus == 0 {
    print("\nIcon written to: \(icnsPath)")
    // Clean up iconset
    try? fm.removeItem(atPath: iconsetDir)
} else {
    fputs("iconutil failed (exit \(result.terminationStatus))\n", stderr)
    exit(1)
}
