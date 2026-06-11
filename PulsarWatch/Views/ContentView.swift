import SwiftUI

struct ContentView: View {
    @StateObject private var state = GameState()

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            switch state.phase {
            case .menu:
                MenuView(state: state)
                    .transition(.opacity)
            case .playing:
                GameView(state: state)
                    .id(state.run)   // fresh scene every run
                    .transition(.opacity)
            case .gameOver:
                GameOverView(state: state)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state.phase)
    }
}

#Preview {
    ContentView()
}
