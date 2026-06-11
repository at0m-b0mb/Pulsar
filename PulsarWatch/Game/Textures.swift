import SpriteKit
import CoreGraphics

/// Procedurally generated textures — soft glow dots, neon rings and jagged
/// asteroids — drawn once with CoreGraphics so the game ships with zero
/// bitmap assets and stays pixel-crisp on every watch size.
enum Textures {

    /// Soft white radial glow. Tinted at the sprite/emitter level.
    static let dot: SKTexture = radialDot(px: 128)
    static let spark: SKTexture = radialDot(px: 32)

    /// Thin neon ring used for the orbit path.
    static let orbitRing: SKTexture = ring(px: 512, lineFraction: 0.012)

    /// Chunky ring used for the player's shield bubble.
    static let shieldRing: SKTexture = ring(px: 128, lineFraction: 0.07)

    /// A few pre-baked asteroid variants.
    static let rocks: [SKTexture] = [
        rock(px: 96, seed: 11), rock(px: 96, seed: 47), rock(px: 96, seed: 83)
    ]

    // MARK: - Drawing helpers

    private static func makeContext(_ px: Int) -> CGContext {
        CGContext(
            data: nil,
            width: px, height: px,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
    }

    private static func white(_ alpha: CGFloat) -> CGColor {
        CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                components: [1, 1, 1, alpha])!
    }

    private static func gray(_ value: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                components: [value, value, value, alpha])!
    }

    private static func radialDot(px: Int) -> SKTexture {
        let ctx = makeContext(px)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let gradient = CGGradient(
            colorsSpace: space,
            colors: [white(1.0), white(0.55), white(0.0)] as CFArray,
            locations: [0.0, 0.32, 1.0]
        )!
        let center = CGPoint(x: CGFloat(px) / 2, y: CGFloat(px) / 2)
        ctx.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: CGFloat(px) / 2,
            options: []
        )
        return SKTexture(cgImage: ctx.makeImage()!)
    }

    private static func ring(px: Int, lineFraction: CGFloat) -> SKTexture {
        let ctx = makeContext(px)
        let size = CGFloat(px)
        let center = CGPoint(x: size / 2, y: size / 2)
        let lineWidth = size * lineFraction
        let radius = size / 2 - lineWidth * 3.5
        // Stroke widest-to-thinnest to fake an outer glow around the ring.
        for (widthScale, alpha) in [(3.4, 0.16), (2.0, 0.34), (1.0, 1.0)] as [(CGFloat, CGFloat)] {
            ctx.setStrokeColor(white(alpha))
            ctx.setLineWidth(lineWidth * widthScale)
            ctx.addArc(center: center, radius: radius,
                       startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.strokePath()
        }
        return SKTexture(cgImage: ctx.makeImage()!)
    }

    private static func rock(px: Int, seed: UInt64) -> SKTexture {
        var rng = SplitMix(seed: seed)
        let ctx = makeContext(px)
        let size = CGFloat(px)
        let center = CGPoint(x: size / 2, y: size / 2)
        let maxRadius = size * 0.46

        // Jagged silhouette.
        let vertexCount = 9 + Int(rng.next() * 3)
        var points: [CGPoint] = []
        for index in 0..<vertexCount {
            let angle = CGFloat(index) / CGFloat(vertexCount) * .pi * 2
            let radius = maxRadius * (0.68 + 0.32 * rng.next())
            points.append(CGPoint(x: center.x + cos(angle) * radius,
                                  y: center.y + sin(angle) * radius))
        }
        ctx.beginPath()
        ctx.move(to: points[0])
        for point in points.dropFirst() { ctx.addLine(to: point) }
        ctx.closePath()
        ctx.setFillColor(CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                 components: [0.15, 0.17, 0.24, 1])!)
        ctx.fillPath()

        // Lit rim so rocks read against the dark sky.
        ctx.beginPath()
        ctx.move(to: points[0])
        for point in points.dropFirst() { ctx.addLine(to: point) }
        ctx.closePath()
        ctx.setStrokeColor(CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                   components: [0.58, 0.65, 0.82, 0.9])!)
        ctx.setLineWidth(size * 0.035)
        ctx.strokePath()

        // A few craters.
        for _ in 0..<3 {
            let angle = rng.next() * .pi * 2
            let distance = maxRadius * 0.45 * rng.next()
            let craterRadius = size * (0.05 + 0.05 * rng.next())
            ctx.setFillColor(gray(0.05, 0.65))
            ctx.fillEllipse(in: CGRect(
                x: center.x + cos(angle) * distance - craterRadius,
                y: center.y + sin(angle) * distance - craterRadius,
                width: craterRadius * 2, height: craterRadius * 2
            ))
        }
        return SKTexture(cgImage: ctx.makeImage()!)
    }
}

/// Tiny deterministic RNG so asteroid variants look the same every launch.
private struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }

    /// Returns a value in 0..<1.
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 100_000) / 100_000
    }
}
