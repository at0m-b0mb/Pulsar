// Draws the 1024×1024 Pulsar app icon with CoreGraphics and writes it into
// the asset catalog. Run from the Pulsar folder:
//
//   swift Tools/make_icon.swift
//
import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers

let px = 1024
let size = CGFloat(px)
let center = CGPoint(x: size / 2, y: size / 2)
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [r, g, b, a])!
}

let ctx = CGContext(
    data: nil, width: px, height: px,
    bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Deep-space radial background.
let bg = CGGradient(
    colorsSpace: srgb,
    colors: [color(0.09, 0.07, 0.22), color(0.015, 0.018, 0.05)] as CFArray,
    locations: [0, 1]
)!
ctx.drawRadialGradient(bg, startCenter: center, startRadius: 0,
                       endCenter: center, endRadius: size * 0.75, options: [.drawsAfterEndLocation])

// Scatter of dim stars.
var seed: UInt64 = 99
func rand() -> CGFloat {
    seed = seed &* 6364136223846793005 &+ 1442695040888963407
    return CGFloat((seed >> 33) % 100_000) / 100_000
}
for _ in 0..<70 {
    let r = 1.2 + rand() * 2.6
    ctx.setFillColor(color(0.75, 0.82, 1.0, 0.12 + rand() * 0.5))
    ctx.fillEllipse(in: CGRect(x: rand() * size, y: rand() * size, width: r, height: r))
}

func glowDot(at p: CGPoint, radius: CGFloat, core: CGColor, halo: CGColor) {
    let g = CGGradient(colorsSpace: srgb,
                       colors: [core, halo, color(0, 0, 0, 0)] as CFArray,
                       locations: [0, 0.3, 1])!
    ctx.drawRadialGradient(g, startCenter: p, startRadius: 0,
                           endCenter: p, endRadius: radius, options: [])
}

// Central star.
glowDot(at: center, radius: size * 0.30,
        core: color(1, 0.95, 0.8), halo: color(1, 0.7, 0.25, 0.55))

// Cyan orbit ring with layered glow.
let ringRadius = size * 0.335
for (width, alpha) in [(CGFloat(34), 0.16), (CGFloat(18), 0.4), (CGFloat(8), 1.0)] {
    ctx.setStrokeColor(color(0.10, 0.89, 1.0, alpha))
    ctx.setLineWidth(width)
    ctx.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
}

// Comet trail along the ring (fading arc segments behind the comet).
let cometAngle: CGFloat = .pi * 0.78
ctx.setLineCap(.round)
for step in 0..<26 {
    let t = CGFloat(step) / 26
    let a0 = cometAngle - 0.07 - t * 1.15
    ctx.setStrokeColor(color(1.0, 0.18, 0.47, 0.65 * (1 - t)))
    ctx.setLineWidth(26 * (1 - t * 0.8))
    ctx.addArc(center: center, radius: ringRadius, startAngle: a0 - 0.05, endAngle: a0, clockwise: false)
    ctx.strokePath()
}

// The comet itself.
let cometPos = CGPoint(x: center.x + cos(cometAngle) * ringRadius,
                       y: center.y + sin(cometAngle) * ringRadius)
glowDot(at: cometPos, radius: size * 0.13,
        core: color(1, 1, 1), halo: color(1.0, 0.18, 0.47, 0.75))

// Write the PNG into the asset catalog.
let image = ctx.makeImage()!
let outURL = URL(fileURLWithPath: "PulsarWatch/Assets.xcassets/AppIcon.appiconset/icon.png")
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outURL.path)")
