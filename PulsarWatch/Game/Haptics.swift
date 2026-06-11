import WatchKit

/// Thin wrapper so gameplay code reads as intent, not device API.
enum Haptics {
    static func orbCollected() { WKInterfaceDevice.current().play(.click) }
    static func shieldGained() { WKInterfaceDevice.current().play(.directionUp) }
    static func shieldLost() { WKInterfaceDevice.current().play(.retry) }
    static func death() { WKInterfaceDevice.current().play(.failure) }
    static func uiTap() { WKInterfaceDevice.current().play(.start) }
}
