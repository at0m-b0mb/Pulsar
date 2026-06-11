import SwiftUI

/// Single source of truth shared between the SwiftUI shell (menu, HUD,
/// game-over) and the SpriteKit scene. The scene mutates it from the render
/// loop, which runs on the main thread.
final class GameState: ObservableObject {

    enum Phase {
        case menu, playing, gameOver
    }

    @Published var phase: Phase = .menu
    @Published var score = 0
    @Published var combo = 1
    @Published var shield = false
    @Published var bestScore: Int
    @Published var newBest = false

    /// Bumped every run so the game view (and its scene) is rebuilt fresh.
    @Published private(set) var run = 0

    private static let bestKey = "pulsar.bestScore"

    init() {
        bestScore = UserDefaults.standard.integer(forKey: Self.bestKey)
        // Debug hook so simulator automation can screenshot gameplay directly.
        if ProcessInfo.processInfo.arguments.contains("PULSAR_AUTOSTART") {
            phase = .playing
        }
    }

    func startRun() {
        score = 0
        combo = 1
        shield = false
        newBest = false
        run += 1
        phase = .playing
    }

    func finishRun() {
        if score > bestScore {
            bestScore = score
            newBest = true
            UserDefaults.standard.set(bestScore, forKey: Self.bestKey)
        }
        phase = .gameOver
    }
}
