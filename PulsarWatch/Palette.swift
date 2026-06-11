import SwiftUI
import CoreGraphics

/// One neon palette for the whole game: deep space blues, hot pink player,
/// electric cyan pickups, warm gold star.
enum Palette {
    // SwiftUI
    static let background = Color(red: 0.02, green: 0.024, blue: 0.06)
    static let pink = Color(red: 1.0, green: 0.18, blue: 0.47)
    static let cyan = Color(red: 0.10, green: 0.89, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.40)
    static let dim = Color(white: 0.62)

    static let titleGradient = LinearGradient(
        colors: [pink, cyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    // SpriteKit / CoreGraphics
    static let bgUI = PColor(red: 0.02, green: 0.024, blue: 0.06, alpha: 1)
    static let pinkUI = PColor(red: 1.0, green: 0.18, blue: 0.47, alpha: 1)
    static let cyanUI = PColor(red: 0.10, green: 0.89, blue: 1.0, alpha: 1)
    static let goldUI = PColor(red: 1.0, green: 0.82, blue: 0.40, alpha: 1)
    static let starlightUI = PColor(red: 0.75, green: 0.82, blue: 1.0, alpha: 1)
}

#if os(watchOS)
import UIKit
typealias PColor = UIColor
#endif
