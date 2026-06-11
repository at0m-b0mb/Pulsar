import SwiftUI

struct GameOverView: View {
    @ObservedObject var state: GameState
    @State private var revealed = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.12, green: 0.03, blue: 0.08), Palette.background],
                center: .center, startRadius: 4, endRadius: 160
            )
            .ignoresSafeArea()

            VStack(spacing: 4) {
                Text("GAME OVER")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Palette.pink)
                    .shadow(color: Palette.pink.opacity(0.7), radius: 6)

                Text("\(state.score)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .shadow(color: Palette.cyan.opacity(0.6), radius: 8)
                    .scaleEffect(revealed ? 1 : 0.6)
                    .opacity(revealed ? 1 : 0)

                if state.newBest {
                    Text("★ NEW BEST ★")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Palette.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Palette.gold, in: Capsule())
                        .shadow(color: Palette.gold.opacity(0.8), radius: 8)
                        .scaleEffect(revealed ? 1 : 0.5)
                } else {
                    Text("BEST \(state.bestScore)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Palette.gold)
                }

                Button {
                    Haptics.uiTap()
                    state.startRun()
                } label: {
                    Text("PLAY AGAIN")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Palette.pink, Color(red: 0.62, green: 0.12, blue: 0.72)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: Palette.pink.opacity(0.8), radius: 10)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Button {
                    state.phase = .menu
                } label: {
                    Text("menu")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.dim)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.1)) {
                revealed = true
            }
        }
    }
}

#Preview {
    GameOverView(state: GameState())
}
