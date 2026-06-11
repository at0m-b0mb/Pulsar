import SpriteKit
import WatchKit

/// The whole game lives here: a comet orbiting a pulsing star, steered with
/// the Digital Crown. Asteroids cut across the orbit; energy orbs and shield
/// pickups appear on the ring. Everything is moved by hand in `update` —
/// no physics engine, so motion stays deterministic and cheap on the watch.
final class GameScene: SKScene {

    weak var gameState: GameState?

    /// Crown position in radians, written by SwiftUI. The player eases toward
    /// it every frame (shortest path around the circle) for buttery control.
    var crownAngle: CGFloat = .pi / 2

    // MARK: Nodes

    private let world = SKNode()
    private var starCore: SKSpriteNode!
    private var starHalo: SKSpriteNode!
    private var ringNode: SKSpriteNode!
    private var player: SKNode!
    private var playerCore: SKSpriteNode!
    private var playerHalo: SKSpriteNode!
    private var shieldBubble: SKSpriteNode!
    private var trail: SKEmitterNode!
    private var starfieldFar: SKEmitterNode!
    private var starfieldNear: SKEmitterNode!

    // MARK: Gameplay state

    private struct Asteroid {
        let node: SKSpriteNode
        let velocity: CGVector
        let radius: CGFloat
    }

    private struct Orb {
        let node: SKSpriteNode
        let isShield: Bool
        let expiresAt: TimeInterval
    }

    private var asteroids: [Asteroid] = []
    private var orbs: [Orb] = []

    private var playerAngle: CGFloat = .pi / 2
    private var orbitRadius: CGFloat = 80
    private var center: CGPoint = .zero

    private var lastUpdate: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var asteroidClock: TimeInterval = 0
    private var orbClock: TimeInterval = 1.2
    private var scoreClock: TimeInterval = 0
    private var isDying = false
    private var built = false

    private let playerRadius: CGFloat = 8

    // MARK: Difficulty curve

    private var asteroidInterval: TimeInterval { max(0.5, 1.3 - elapsed * 0.012) }
    private var asteroidSpeed: CGFloat { min(95, 42 + CGFloat(elapsed) * 1.0) }
    private var orbInterval: TimeInterval { max(1.6, 2.4 - elapsed * 0.01) }

    // MARK: - Setup

    // watchOS has no SKView, so setup happens in sceneDidLoad rather than
    // didMove(to:). The size set here is provisional — resizeFill triggers
    // didChangeSize with the real view size, which re-runs layout().
    override func sceneDidLoad() {
        backgroundColor = Palette.bgUI
        guard !built else { return }
        built = true
        addChild(world)
        buildStarfield()
        buildStar()
        buildRing()
        buildPlayer()
        layout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        layout()
    }

    private func layout() {
        center = CGPoint(x: size.width / 2, y: size.height / 2)
        orbitRadius = min(size.width, size.height) * 0.37

        starCore.position = center
        starHalo.position = center
        ringNode.position = center
        ringNode.size = CGSize(width: orbitRadius * 2.3, height: orbitRadius * 2.3)

        for field in [starfieldFar, starfieldNear] {
            field?.position = center
            field?.particlePositionRange = CGVector(dx: size.width * 1.1, dy: size.height * 1.1)
        }
    }

    private func buildStarfield() {
        func field(birthRate: CGFloat, scale: CGFloat, alpha: CGFloat, lifetime: CGFloat) -> SKEmitterNode {
            let emitter = SKEmitterNode()
            emitter.particleTexture = Textures.spark
            emitter.particleBirthRate = birthRate
            emitter.particleLifetime = lifetime
            emitter.particleLifetimeRange = lifetime * 0.6
            emitter.particleScale = scale
            emitter.particleScaleRange = scale * 0.7
            emitter.particleAlpha = 0
            emitter.particleAlphaSpeed = alpha / (lifetime * 0.4)
            emitter.particleAlphaSequence = twinkleSequence(peak: alpha)
            emitter.particleColor = Palette.starlightUI
            emitter.particleColorBlendFactor = 1
            emitter.particleSpeed = 1.5
            emitter.particleSpeedRange = 1.5
            emitter.emissionAngleRange = .pi * 2
            emitter.particleBlendMode = .add
            emitter.zPosition = -10
            emitter.advanceSimulationTime(Double(lifetime) * 2)
            return emitter
        }
        starfieldFar = field(birthRate: 9, scale: 0.10, alpha: 0.45, lifetime: 5)
        starfieldNear = field(birthRate: 5, scale: 0.20, alpha: 0.8, lifetime: 4)
        world.addChild(starfieldFar)
        world.addChild(starfieldNear)
    }

    private func twinkleSequence(peak: CGFloat) -> SKKeyframeSequence {
        SKKeyframeSequence(
            keyframeValues: [0.0, peak, peak * 0.4, peak, 0.0],
            times: [0.0, 0.25, 0.5, 0.75, 1.0]
        )
    }

    private func buildStar() {
        starHalo = SKSpriteNode(texture: Textures.dot)
        starHalo.size = CGSize(width: 86, height: 86)
        starHalo.color = Palette.goldUI
        starHalo.colorBlendFactor = 1
        starHalo.alpha = 0.55
        starHalo.blendMode = .add
        starHalo.zPosition = 0
        world.addChild(starHalo)

        starCore = SKSpriteNode(texture: Textures.dot)
        starCore.size = CGSize(width: 30, height: 30)
        starCore.color = Palette.goldUI
        starCore.colorBlendFactor = 0.35
        starCore.blendMode = .add
        starCore.zPosition = 1
        world.addChild(starCore)

        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: 1.18, duration: 1.1),
            .scale(to: 1.0, duration: 1.1)
        ]))
        pulse.timingMode = .easeInEaseOut
        starHalo.run(pulse)
        starCore.run(pulse.copy() as! SKAction)

        let corona = SKEmitterNode()
        corona.particleTexture = Textures.spark
        corona.particleBirthRate = 22
        corona.particleLifetime = 2.2
        corona.particleLifetimeRange = 1.0
        corona.particleSpeed = 9
        corona.particleSpeedRange = 6
        corona.emissionAngleRange = .pi * 2
        corona.particleScale = 0.16
        corona.particleScaleSpeed = -0.06
        corona.particleAlpha = 0.7
        corona.particleAlphaSpeed = -0.32
        corona.particleColor = Palette.goldUI
        corona.particleColorBlendFactor = 1
        corona.particleBlendMode = .add
        corona.zPosition = 0
        starCore.addChild(corona)
    }

    private func buildRing() {
        ringNode = SKSpriteNode(texture: Textures.orbitRing)
        ringNode.color = Palette.cyanUI
        ringNode.colorBlendFactor = 1
        ringNode.alpha = 0.32
        ringNode.blendMode = .add
        ringNode.zPosition = -2
        world.addChild(ringNode)

        let breathe = SKAction.repeatForever(.sequence([
            .fadeAlpha(to: 0.22, duration: 1.6),
            .fadeAlpha(to: 0.32, duration: 1.6)
        ]))
        breathe.timingMode = .easeInEaseOut
        ringNode.run(breathe)
    }

    private func buildPlayer() {
        player = SKNode()
        player.zPosition = 5
        world.addChild(player)

        playerHalo = SKSpriteNode(texture: Textures.dot)
        playerHalo.size = CGSize(width: 44, height: 44)
        playerHalo.color = Palette.pinkUI
        playerHalo.colorBlendFactor = 1
        playerHalo.alpha = 0.85
        playerHalo.blendMode = .add
        player.addChild(playerHalo)

        playerCore = SKSpriteNode(texture: Textures.dot)
        playerCore.size = CGSize(width: 15, height: 15)
        playerCore.blendMode = .add
        player.addChild(playerCore)

        shieldBubble = SKSpriteNode(texture: Textures.shieldRing)
        shieldBubble.size = CGSize(width: 42, height: 42)
        shieldBubble.color = Palette.cyanUI
        shieldBubble.colorBlendFactor = 1
        shieldBubble.blendMode = .add
        shieldBubble.isHidden = true
        player.addChild(shieldBubble)

        trail = SKEmitterNode()
        trail.particleTexture = Textures.spark
        trail.particleBirthRate = 70
        trail.particleLifetime = 0.55
        trail.particleLifetimeRange = 0.2
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -1.5
        trail.particleScale = 0.34
        trail.particleScaleSpeed = -0.5
        trail.particleSpeed = 4
        trail.particleSpeedRange = 4
        trail.emissionAngleRange = .pi * 2
        trail.particleColor = Palette.pinkUI
        trail.particleColorBlendFactor = 1
        trail.particleBlendMode = .add
        trail.targetNode = world
        trail.zPosition = 4
        player.addChild(trail)
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        guard built else { return }
        if lastUpdate == 0 { lastUpdate = currentTime }
        let dt = min(1.0 / 20.0, currentTime - lastUpdate)
        lastUpdate = currentTime

        steerPlayer(dt: dt)

        guard let state = gameState, state.phase == .playing, !isDying else { return }

        elapsed += dt
        tickScore(dt: dt)
        spawnIfDue(dt: dt)
        moveAsteroids(dt: dt)
        expireOrbs()
        checkCollisions(state: state)
    }

    /// Ease the comet toward the crown angle along the shortest arc, so the
    /// 0°/360° wrap of the crown binding never causes a spin-around.
    private func steerPlayer(dt: TimeInterval) {
        var delta = (crownAngle - playerAngle).truncatingRemainder(dividingBy: .pi * 2)
        if delta > .pi { delta -= .pi * 2 }
        if delta < -.pi { delta += .pi * 2 }
        playerAngle += delta * CGFloat(min(1.0, dt * 14))
        player.position = pointOnRing(angle: playerAngle)
    }

    private func pointOnRing(angle: CGFloat, radius: CGFloat? = nil) -> CGPoint {
        let r = radius ?? orbitRadius
        return CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
    }

    private func tickScore(dt: TimeInterval) {
        scoreClock += dt
        while scoreClock >= 1 {
            scoreClock -= 1
            gameState?.score += 1
        }
    }

    private func spawnIfDue(dt: TimeInterval) {
        asteroidClock += dt
        if asteroidClock >= asteroidInterval {
            asteroidClock = 0
            spawnAsteroid()
            // Brief surge every ~18s of survival to spike the tension.
            if Int(elapsed) % 18 == 0 && elapsed > 10 { spawnAsteroid() }
        }
        orbClock += dt
        if orbClock >= orbInterval && orbs.count < 3 {
            orbClock = 0
            spawnOrb()
        }
    }

    // MARK: - Asteroids

    private func spawnAsteroid() {
        let entryAngle = CGFloat.random(in: 0..<(.pi * 2))
        let spawnDistance = max(size.width, size.height) * 0.72
        let start = pointOnRing(angle: entryAngle, radius: spawnDistance)

        // Aim at a point near the star, offset sideways so crossings sweep
        // different parts of the ring rather than always the dead center.
        let perpendicular = CGVector(dx: -sin(entryAngle), dy: cos(entryAngle))
        let offset = CGFloat.random(in: -orbitRadius * 0.55...orbitRadius * 0.55)
        let target = CGPoint(x: center.x + perpendicular.dx * offset,
                             y: center.y + perpendicular.dy * offset)

        let dx = target.x - start.x, dy = target.y - start.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        let speed = asteroidSpeed
        let velocity = CGVector(dx: dx / length * speed, dy: dy / length * speed)

        let diameter = CGFloat.random(in: 15...26)
        let node = SKSpriteNode(texture: Textures.rocks.randomElement()!)
        node.size = CGSize(width: diameter, height: diameter)
        node.position = start
        node.zRotation = .random(in: 0..<(.pi * 2))
        node.zPosition = 3
        node.run(.repeatForever(.rotate(byAngle: .random(in: -2...2), duration: 1)))
        world.addChild(node)

        asteroids.append(Asteroid(node: node, velocity: velocity, radius: diameter * 0.42))
    }

    private func moveAsteroids(dt: TimeInterval) {
        let escapeDistance = max(size.width, size.height) * 0.78
        var survivors: [Asteroid] = []
        survivors.reserveCapacity(asteroids.count)
        for asteroid in asteroids {
            asteroid.node.position.x += asteroid.velocity.dx * CGFloat(dt)
            asteroid.node.position.y += asteroid.velocity.dy * CGFloat(dt)
            let dx = asteroid.node.position.x - center.x
            let dy = asteroid.node.position.y - center.y
            if sqrt(dx * dx + dy * dy) > escapeDistance {
                asteroid.node.removeFromParent()
                gameState?.score += 2   // dodged
            } else {
                survivors.append(asteroid)
            }
        }
        asteroids = survivors
    }

    // MARK: - Orbs

    private func spawnOrb() {
        guard let state = gameState else { return }
        // Shield orb only when the player doesn't already hold one.
        let isShield = !state.shield && CGFloat.random(in: 0...1) < 0.12

        // Keep new orbs at least ~35° away from the player so they require travel.
        var angle = CGFloat.random(in: 0..<(.pi * 2))
        var separation = abs((angle - playerAngle).truncatingRemainder(dividingBy: .pi * 2))
        if separation > .pi { separation = .pi * 2 - separation }
        if separation < 0.6 { angle += .pi }

        let node = SKSpriteNode(texture: isShield ? Textures.shieldRing : Textures.dot)
        node.size = isShield ? CGSize(width: 20, height: 20) : CGSize(width: 16, height: 16)
        node.color = Palette.cyanUI
        node.colorBlendFactor = isShield ? 1 : 0.75
        node.blendMode = .add
        node.position = pointOnRing(angle: angle)
        node.zPosition = 2
        node.alpha = 0
        node.run(.fadeIn(withDuration: 0.3))
        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: 1.25, duration: 0.5),
            .scale(to: 0.9, duration: 0.5)
        ]))
        pulse.timingMode = .easeInEaseOut
        node.run(pulse)
        world.addChild(node)

        orbs.append(Orb(node: node, isShield: isShield, expiresAt: elapsed + 6))
    }

    private func expireOrbs() {
        var remaining: [Orb] = []
        for orb in orbs {
            if elapsed >= orb.expiresAt {
                orb.node.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
                // Letting energy slip away breaks the combo — keeps you moving.
                if !orb.isShield { gameState?.combo = 1 }
            } else {
                remaining.append(orb)
            }
        }
        orbs = remaining
    }

    // MARK: - Collisions

    private func checkCollisions(state: GameState) {
        // Orb pickups.
        var keptOrbs: [Orb] = []
        for orb in orbs {
            if distance(player.position, orb.node.position) < playerRadius + 9 {
                collect(orb: orb, state: state)
            } else {
                keptOrbs.append(orb)
            }
        }
        orbs = keptOrbs

        // Asteroid hits.
        for (index, asteroid) in asteroids.enumerated() {
            guard distance(player.position, asteroid.node.position) < playerRadius + asteroid.radius else { continue }
            if state.shield {
                state.shield = false
                shieldBubble.isHidden = true
                burst(at: asteroid.node.position, color: Palette.cyanUI, count: 26, speed: 60)
                asteroid.node.removeFromParent()
                asteroids.remove(at: index)
                shake(intensity: 3)
                Haptics.shieldLost()
            } else {
                die(state: state)
            }
            return
        }
    }

    private func collect(orb: Orb, state: GameState) {
        if orb.isShield {
            state.shield = true
            shieldBubble.isHidden = false
            shieldBubble.alpha = 0
            shieldBubble.run(.fadeAlpha(to: 0.9, duration: 0.2))
            shieldBubble.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.55, duration: 0.6),
                .fadeAlpha(to: 0.9, duration: 0.6)
            ])))
            Haptics.shieldGained()
        } else {
            state.combo = min(9, state.combo + 1)
            let points = 10 * state.combo
            state.score += points
            popLabel("+\(points)", at: orb.node.position)
            Haptics.orbCollected()
        }
        burst(at: orb.node.position, color: Palette.cyanUI, count: 16, speed: 42)
        orb.node.removeFromParent()
    }

    private func die(state: GameState) {
        isDying = true
        Haptics.death()

        trail.particleBirthRate = 0
        playerCore.isHidden = true
        playerHalo.isHidden = true
        burst(at: player.position, color: Palette.pinkUI, count: 60, speed: 90)
        burst(at: player.position, color: Palette.goldUI, count: 24, speed: 50)
        flash()
        shake(intensity: 7)

        run(.sequence([
            .wait(forDuration: 1.1),
            .run { [weak self] in self?.gameState?.finishRun() }
        ]))
    }

    // MARK: - Juice

    private func burst(at position: CGPoint, color: PColor, count: Int, speed: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = Textures.spark
        emitter.numParticlesToEmit = count
        emitter.particleBirthRate = 600
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.35
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.7
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.42
        emitter.particleScaleSpeed = -0.55
        emitter.particleAlpha = 1
        emitter.particleAlphaSpeed = -1.6
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.position = position
        emitter.zPosition = 8
        world.addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 1.4), .removeFromParent()]))
    }

    private func popLabel(_ text: String, at position: CGPoint) {
        let label = SKLabelNode(text: text)
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 11
        label.fontColor = Palette.cyanUI
        label.position = position
        label.zPosition = 9
        world.addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 16, duration: 0.6), .fadeOut(withDuration: 0.6)]),
            .removeFromParent()
        ]))
    }

    private func shake(intensity: CGFloat) {
        world.removeAction(forKey: "shake")
        var moves: [SKAction] = []
        for step in 0..<6 {
            let falloff = intensity * (1 - CGFloat(step) / 6)
            moves.append(.moveBy(
                x: .random(in: -falloff...falloff),
                y: .random(in: -falloff...falloff),
                duration: 0.035
            ))
        }
        moves.append(.move(to: .zero, duration: 0.035))
        world.run(.sequence(moves), withKey: "shake")
    }

    private func flash() {
        let cover = SKSpriteNode(color: .white, size: CGSize(width: size.width * 2, height: size.height * 2))
        cover.position = center
        cover.alpha = 0
        cover.zPosition = 50
        addChild(cover)
        cover.run(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.05),
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
