import SwiftUI

/// Title screen: pulsing neon rings behind a gradient wordmark, best score,
/// and a glowing play button.
struct MenuView: View {
    @ObservedObject var state: GameState
    @State private var pulsing = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.07, green: 0.05, blue: 0.16), Palette.background],
                center: .center, startRadius: 4, endRadius: 160
            )
            .ignoresSafeArea()

            // Slowly breathing orbit rings.
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        index == 1 ? Palette.pink.opacity(0.35) : Palette.cyan.opacity(0.25),
                        lineWidth: 1
                    )
                    .frame(width: 70 + CGFloat(index) * 52)
                    .scaleEffect(pulsing ? 1.06 : 0.96)
                    .animation(
                        .easeInOut(duration: 2.2 + Double(index) * 0.4).repeatForever(autoreverses: true),
                        value: pulsing
                    )
            }

            VStack(spacing: 6) {
                Text("PULSAR")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Palette.titleGradient)
                    .shadow(color: Palette.pink.opacity(0.7), radius: 8)

                Text("ORBIT · DODGE · SURVIVE")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Palette.dim)

                if state.bestScore > 0 {
                    Text("BEST \(state.bestScore)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Palette.gold)
                        .padding(.top, 2)
                }

                Button {
                    Haptics.uiTap()
                    state.startRun()
                } label: {
                    Text("PLAY")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 9)
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

                Text("turn the crown to fly")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.dim.opacity(0.8))
                    .padding(.top, 2)
            }
        }
        .onAppear { pulsing = true }
    }
}

#Preview {
    MenuView(state: GameState())
}
