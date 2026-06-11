import SwiftUI
import SpriteKit

/// Hosts the SpriteKit scene, routes the Digital Crown into it and floats
/// the score HUD on top.
struct GameView: View {
    @ObservedObject var state: GameState
    @Environment(\.scenePhase) private var scenePhase

    /// Crown angle in degrees; wraps continuously at 0/360.
    @State private var crown: Double = 90
    @State private var scene: GameScene

    init(state: GameState) {
        self.state = state
        let scene = GameScene(size: CGSize(width: 205, height: 251))
        scene.scaleMode = .resizeFill
        _scene = State(initialValue: scene)
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .focusable(true)
            .digitalCrownRotation(
                $crown,
                from: 0, through: 360, by: 1,
                sensitivity: .medium,
                isContinuous: true,
                isHapticFeedbackEnabled: false
            )
            .onChange(of: crown) { _, value in
                scene.crownAngle = CGFloat(value) * .pi / 180
            }
            .onChange(of: scenePhase) { _, phase in
                scene.isPaused = phase != .active
            }
            .onAppear {
                scene.gameState = state
            }
            .overlay(alignment: .topLeading) { hud }
    }

    private var hud: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(state.score)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: Palette.pink.opacity(0.8), radius: 5)

            if state.combo > 1 {
                Text("×\(state.combo)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.cyan)
                    .shadow(color: Palette.cyan.opacity(0.8), radius: 4)
            }

            if state.shield {
                Text("SHIELD")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Palette.background)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Palette.cyan, in: Capsule())
            }
        }
        .padding(.leading, 8)
        .padding(.top, 2)
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.15), value: state.combo)
        .animation(.easeOut(duration: 0.15), value: state.shield)
    }
}
